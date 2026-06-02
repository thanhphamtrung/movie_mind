-- Create movies_cache table
create table if not exists public.movies_cache (
  id bigint primary key,
  title text not null,
  overview text,
  poster_url text,
  trailer_key text,
  release_date date,
  genres jsonb,
  last_validated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- Enable RLS
alter table public.movies_cache enable row level security;

-- Policies for anon/authenticated roles to read cache
create policy "Enable read access for all users"
on public.movies_cache
for select
to authenticated, anon
using (true);
