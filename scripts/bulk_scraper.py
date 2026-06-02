import argparse
import asyncio
import re
import time
import os
import hashlib
import requests
import io
from PIL import Image
from dotenv import load_dotenv
from supabase import create_client, Client
from scrapling import Fetcher

# Load environment variables
load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

BUCKET_NAME = "movie-posters"
TARGET_WIDTH = 500
WEBP_QUALITY = 80

def generate_numeric_id(text: str):
    return int(hashlib.sha256(text.encode('utf-8')).hexdigest(), 16) % (10**15)

def process_and_compress_image(image_bytes: bytes) -> bytes:
    try:
        img = Image.open(io.BytesIO(image_bytes))
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")
        if img.width > TARGET_WIDTH:
            w_percent = (TARGET_WIDTH / float(img.width))
            h_size = int((float(img.height) * float(w_percent)))
            img = img.resize((TARGET_WIDTH, h_size), Image.Resampling.LANCZOS)
        output_buffer = io.BytesIO()
        img.save(output_buffer, format="WEBP", quality=WEBP_QUALITY, method=4)
        return output_buffer.getvalue()
    except Exception:
        return image_bytes

def download_and_upload_poster(image_url: str, movie_id: str):
    if not image_url: return None
    try:
        response = requests.get(image_url, timeout=10)
        if response.status_code != 200: return None
        processed_bytes = process_and_compress_image(response.content)
        file_path = f"{movie_id}.webp"
        supabase.storage.from_(BUCKET_NAME).upload(
            path=file_path,
            file=processed_bytes,
            file_options={"content-type": "image/webp", "x-upsert": "true"}
        )
        return supabase.storage.from_(BUCKET_NAME).get_public_url(file_path)
    except Exception:
        return image_url

def extract_youtube_id(url):
    if not url: return None
    regex = r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})'
    match = re.search(regex, url)
    return match.group(1) if match else None

def crawl_movie_details(fetcher, detail_url):
    try:
        res = fetcher.get(detail_url)
        if res.status != 200: return None
        
        # Overview
        overview = res.css('.description-full p::text').get()
        if not overview: overview = res.css('.description-full::text').get()
        if not overview: overview = res.css('.description-short::text').get()
            
        # Original Title
        original_title = ""
        ot_el = res.css('.name2') or res.css('.original-title')
        if ot_el: original_title = ot_el[0].text.strip()
            
        # Metadata Arrays
        countries = [a.text.strip() for a in res.css('.motchill-info-item:contains("Quốc gia:") a')]
        directors = [a.text.strip() for a in res.css('.motchill-info-item:contains("Đạo diễn:") a')]
        
        # Actors
        actors = [a.text.strip() for a in res.css('.motchill-actors-slider .actor-name')]
        if not actors:
             actors = [a.attrib.get('title', '') for a in res.css('.motchill-actors-slider a') if a.attrib.get('title')]
             
        # Trailer
        trailer_key = None
        onclick_attr = res.css('button[onclick*="openTrailerPopup"]::attr(onclick)').get()
        if onclick_attr:
            match = re.search(r"'(https?://[^']+)'", onclick_attr)
            if match:
                trailer_key = extract_youtube_id(match.group(1))
                
        return {
            "overview": overview.strip() if overview else "",
            "original_title": original_title,
            "countries": countries,
            "directors": directors,
            "actors": actors,
            "trailer_key": trailer_key
        }
    except Exception as e:
        print(f"Lỗi crawl chi tiết: {e}")
        return None

def process_page(fetcher, page_url, category):
    response = fetcher.get(page_url)
    if response.status != 200: return []

    movie_elements = response.css('.poster-container')
    if not movie_elements:
        movie_elements = response.css('li.item')
        
    records = []
    for el in movie_elements:
        title = el.css('a::attr(title)').get() or "N/A"
        detail_url = el.css('a::attr(href)').get() or "N/A"
        img_src = el.css('img::attr(src)').get() or el.css('img::attr(data-src)').get() or ""
        
        if img_src.startswith('/'): img_src = f"https://eyephotodoc.com{img_src}"
        if detail_url == "N/A" or "/phim/" not in detail_url: continue

        details = crawl_movie_details(fetcher, detail_url)
        if not details: continue

        movie_id = generate_numeric_id(title)
        new_poster_url = download_and_upload_poster(img_src, str(movie_id))
        
        records.append({
            "id": movie_id,
            "title": title,
            "original_title": details["original_title"],
            "type": category,
            "overview": details["overview"],
            "poster_url": new_poster_url,
            "trailer_key": details["trailer_key"],
            "countries": details["countries"],
            "directors": details["directors"],
            "actors": details["actors"],
            "last_validated_at": "now()"
        })
        time.sleep(0.3)
        
    if records:
        try:
            supabase.table("movies_cache").upsert(records).execute()
        except Exception as e:
            print(f"❌ Lỗi DB: {e}")
            
    return len(records)

def main():
    parser = argparse.ArgumentParser(description="Bulk Scraper Worker")
    parser.add_argument("--category", type=str, required=True, help="Category URL (e.g., phim-le)")
    parser.add_argument("--start", type=int, required=True, help="Start page")
    parser.add_argument("--end", type=int, required=True, help="End page")
    args = parser.parse_args()

    fetcher = Fetcher()
    base_url = f"https://eyephotodoc.com/danh-sach/{args.category}/"
    
    total_movies = 0
    for p in range(args.start, args.end + 1):
        page_url = base_url if p == 1 else f"{base_url}page/{p}/"
        print(f"[Worker {args.category} {args.start}-{args.end}] Cào trang {p}...")
        count = process_page(fetcher, page_url, args.category)
        total_movies += count
        print(f"[Worker {args.category} {args.start}-{args.end}] ✅ Trang {p}: đã lưu {count} phim. (Tổng: {total_movies})")

if __name__ == "__main__":
    main()
