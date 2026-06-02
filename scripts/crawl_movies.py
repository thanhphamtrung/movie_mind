import json
import re
import time
from scrapling import Fetcher

def extract_youtube_id(url):
    if not url: return None
    regex = r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})'
    match = re.search(regex, url)
    return match.group(1) if match else None

def crawl_movie_details(fetcher, detail_url):
    try:
        res = fetcher.get(detail_url)
        if res.status != 200: return None
        
        # 1. Lấy mô tả phim (Nội dung)
        overview = res.css('.description-full p::text').get()
        if not overview:
            overview = res.css('.description-full::text').get()
        if not overview:
            overview = res.css('.description-short::text').get()
            
        # 2. Lấy trailer YouTube key
        trailer_key = None
        onclick_attr = res.css('button[onclick*="openTrailerPopup"]::attr(onclick)').get()
        if onclick_attr:
            match = re.search(r"'(https?://[^']+)'", onclick_attr)
            if match:
                trailer_key = extract_youtube_id(match.group(1))
                
        return {
            "overview": overview.strip() if overview else "",
            "trailer_key": trailer_key
        }
    except Exception as e:
        print(f"⚠️ Lỗi khi crawl chi tiết {detail_url}: {e}")
        return None

def crawl_page(fetcher, page_url):
    print(f"📄 Đang crawl trang: {page_url}")
    response = fetcher.get(page_url)
    if response.status != 200:
        print(f"❌ Lỗi: Không thể truy cập {page_url} (Status: {response.status})")
        return []

    # Thử nhiều loại selector khác nhau cho các loại trang khác nhau
    movie_elements = response.css('.poster-container') # Trang chủ
    if not movie_elements:
        movie_elements = response.css('li.item') # Trang danh sách/category
        
    page_movies = []
    print(f"  🎬 Tìm thấy {len(movie_elements)} element phim.")
    
    for el in movie_elements:
        title = el.css('a::attr(title)').get() or "N/A"
        detail_url = el.css('a::attr(href)').get() or "N/A"
        
        # Lấy poster URL (thử nhiều trường hợp img)
        img_src = el.css('img::attr(src)').get() or ""
        if not img_src:
            img_src = el.css('img::attr(data-src)').get() or ""
            
        if img_src.startswith('/'):
            img_src = f"https://eyephotodoc.com{img_src}"
            
        if detail_url == "N/A" or "/phim/" not in detail_url:
            continue

        print(f"    🔎 Đang lấy: {title}...")
        details = crawl_movie_details(fetcher, detail_url)
        
        page_movies.append({
            "title": title,
            "detail_url": detail_url,
            "poster_url": img_src,
            "overview": details["overview"] if details else "",
            "trailer_key": details["trailer_key"] if details else None
        })
        # Thêm delay nhẹ
        time.sleep(0.3)
        
    return page_movies

def main():
    fetcher = Fetcher()
    
    # Chỉ crawl 1 trang mỗi mục để demo nhanh, bạn có thể tăng lên sau
    categories = [
        {"name": "Phim Lẻ", "base_url": "https://eyephotodoc.com/danh-sach/phim-le/", "pages": 1},
        {"name": "Phim Bộ", "base_url": "https://eyephotodoc.com/danh-sach/phim-bo/", "pages": 1},
    ]
    
    all_movies = []
    
    for cat in categories:
        print(f"\n🌟 Bắt đầu crawl mục: {cat['name']}")
        for p in range(1, cat['pages'] + 1):
            page_url = cat['base_url'] if p == 1 else f"{cat['base_url']}page/{p}/"
            movies = crawl_page(fetcher, page_url)
            all_movies.extend(movies)
            print(f"✅ Xong trang {p}. Tổng cộng hiện có {len(all_movies)} phim.")

    # Lưu kết quả
    output_path = 'scripts/movies_detailed.json'
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(all_movies, f, ensure_ascii=False, indent=2)
    
    print(f"\n🎉 HOÀN THÀNH! Đã crawl tổng cộng {len(all_movies)} phim.")
    print(f"💾 Kết quả lưu tại: {output_path}")

if __name__ == "__main__":
    main()
