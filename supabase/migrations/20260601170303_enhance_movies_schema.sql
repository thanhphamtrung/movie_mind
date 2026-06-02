-- Bật extension pgvector cho tương lai (Semantic Search)
create extension if not exists vector;

-- Thêm các cột siêu dữ liệu cho GenAI filtering
alter table public.movies_cache 
  add column if not exists original_title text,
  add column if not exists type text, -- 'phim-le', 'phim-bo'
  add column if not exists release_year integer,
  add column if not exists countries text[],
  add column if not exists directors text[],
  add column if not exists actors text[],
  
  -- Sửa lại kiểu genres thành text[] cho dễ query
  drop column if exists genres,
  add column genres text[];

-- Cột Full-Text Search
alter table public.movies_cache 
  add column if not exists fts_vector tsvector generated always as (
    setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(original_title, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(overview, '')), 'C')
  ) stored;

-- Tạo index để tăng tốc độ tìm kiếm
create index if not exists movies_cache_fts_idx on public.movies_cache using gin (fts_vector);
create index if not exists movies_cache_genres_idx on public.movies_cache using gin (genres);
create index if not exists movies_cache_countries_idx on public.movies_cache using gin (countries);
create index if not exists movies_cache_actors_idx on public.movies_cache using gin (actors);

-- Tạo function RPC để GenAI gọi tìm kiếm (Search Tool)
create or replace function search_movies_for_genai(
  search_query text default null,
  filter_genres text[] default null,
  filter_countries text[] default null,
  filter_actors text[] default null,
  filter_type text default null,
  limit_num integer default 10
) returns setof public.movies_cache language plpgsql as $$
begin
  return query
  select * from public.movies_cache
  where 
    -- 1. Full Text Search
    (search_query is null or fts_vector @@ plainto_tsquery('english', search_query))
    -- 2. Array Overlap Filters
    and (filter_genres is null or genres && filter_genres)
    and (filter_countries is null or countries && filter_countries)
    and (filter_actors is null or actors && filter_actors)
    -- 3. Exact Match Filter
    and (filter_type is null or type = filter_type)
  order by 
    -- Ưu tiên phim mới nhất (nếu có search query thì order theo độ rannk của FTS)
    case when search_query is not null 
      then ts_rank(fts_vector, plainto_tsquery('english', search_query)) 
      else null 
    end desc nulls last,
    release_year desc nulls last,
    created_at desc
  limit limit_num;
end;
$$;
