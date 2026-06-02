import json
import os
import hashlib
import requests
import io
from PIL import Image
from dotenv import load_dotenv
from supabase import create_client, Client

# Load environment variables
load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

BUCKET_NAME = "movie-posters"
TARGET_WIDTH = 500  # Nén ảnh về chiều rộng tối đa 500px để làm thumbnail
WEBP_QUALITY = 80   # Giữ chất lượng 80% để nhẹ mà vẫn nét

def generate_numeric_id(text: str):
    return int(hashlib.sha256(text.encode('utf-8')).hexdigest(), 16) % (10**15)

def process_and_compress_image(image_bytes: bytes) -> bytes:
    """Nén ảnh, resize và convert sang WebP để tiết kiệm dung lượng"""
    try:
        # Đọc ảnh từ bytes
        img = Image.open(io.BytesIO(image_bytes))
        
        # Chuyển đổi sang RGB nếu cần (để tránh lỗi khi save webp)
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")
            
        # Resize ảnh nếu quá to, giữ nguyên tỷ lệ
        if img.width > TARGET_WIDTH:
            w_percent = (TARGET_WIDTH / float(img.width))
            h_size = int((float(img.height) * float(w_percent)))
            img = img.resize((TARGET_WIDTH, h_size), Image.Resampling.LANCZOS)
            
        # Lưu vào buffer dưới dạng WebP
        output_buffer = io.BytesIO()
        img.save(output_buffer, format="WEBP", quality=WEBP_QUALITY, method=4)
        
        return output_buffer.getvalue()
    except Exception as e:
        print(f"   ⚠️ Lỗi khi nén ảnh: {e}. Dùng ảnh gốc.")
        return image_bytes

def download_and_upload_poster(image_url: str, movie_id: str):
    """Tải, nén và upload lên Supabase Storage"""
    if not image_url:
        return None
    
    try:
        # 1. Download
        response = requests.get(image_url, timeout=10)
        if response.status_code != 200:
            return None
            
        original_size = len(response.content)
        
        # 2. Nén ảnh
        processed_bytes = process_and_compress_image(response.content)
        new_size = len(processed_bytes)
        
        if original_size > 0:
            saved_percent = 100 - (new_size / original_size * 100)
            print(f"   🖼️ Nén: {original_size/1024:.1f}KB -> {new_size/1024:.1f}KB (Tiết kiệm {saved_percent:.1f}%)")
        
        file_path = f"{movie_id}.webp"
        
        # 3. Upload (Upsert)
        supabase.storage.from_(BUCKET_NAME).upload(
            path=file_path,
            file=processed_bytes,
            file_options={"content-type": "image/webp", "x-upsert": "true"}
        )
        
        # 4. Trả về Public URL
        return supabase.storage.from_(BUCKET_NAME).get_public_url(file_path)
    except Exception as e:
        print(f"   ❌ Lỗi tải/upload poster: {e}")
        return image_url # Fallback

def seed_data():
    input_path = 'scripts/movies_detailed.json'
    if not os.path.exists(input_path):
        print(f"❌ Không tìm thấy {input_path}")
        return

    with open(input_path, 'r', encoding='utf-8') as f:
        movies = json.load(f)

    print(f"🚀 Bắt đầu Seeding {len(movies)} phim (Kèm nén WebP)...")
    
    records = []
    for i, m in enumerate(movies):
        movie_id = generate_numeric_id(m['title'])
        print(f"📦 [{i+1}/{len(movies)}] {m['title']}")
        
        new_poster_url = download_and_upload_poster(m['poster_url'], str(movie_id))
        
        records.append({
            "id": movie_id,
            "title": m['title'],
            "overview": m['overview'],
            "poster_url": new_poster_url,
            "trailer_key": m['trailer_key'],
            "last_validated_at": "now()"
        })

    try:
        supabase.table("movies_cache").upsert(records).execute()
        print(f"✅ HOÀN TẤT! Đã import và nén ảnh cho {len(records)} phim.")
    except Exception as e:
        print(f"❌ Lỗi DB: {e}")

if __name__ == "__main__":
    seed_data()
