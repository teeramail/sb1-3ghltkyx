/*
  # Storage bucket and policies setup

  1. Storage
    - Create public bucket for product images if it doesn't exist
    - Enable RLS on storage.objects table
    - Add policies for public read access and authenticated user uploads
    - Add policies for update and delete operations
*/

-- Create bucket if it doesn't exist
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

-- Enable RLS
alter table storage.objects enable row level security;

-- Drop existing policies if they exist
do $$
begin
    if exists (
        select 1 from pg_policies 
        where schemaname = 'storage' 
        and tablename = 'objects' 
        and policyname = 'Public Access'
    ) then
        drop policy "Public Access" on storage.objects;
    end if;

    if exists (
        select 1 from pg_policies 
        where schemaname = 'storage' 
        and tablename = 'objects' 
        and policyname = 'Authenticated users can upload images'
    ) then
        drop policy "Authenticated users can upload images" on storage.objects;
    end if;

    if exists (
        select 1 from pg_policies 
        where schemaname = 'storage' 
        and tablename = 'objects' 
        and policyname = 'Authenticated users can update images'
    ) then
        drop policy "Authenticated users can update images" on storage.objects;
    end if;

    if exists (
        select 1 from pg_policies 
        where schemaname = 'storage' 
        and tablename = 'objects' 
        and policyname = 'Authenticated users can delete images'
    ) then
        drop policy "Authenticated users can delete images" on storage.objects;
    end if;
end $$;

-- Create policies
create policy "Public Access"
on storage.objects for select
to public
using ( bucket_id = 'product-images' );

create policy "Authenticated users can upload images"
on storage.objects for insert
to authenticated
with check (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] != 'private'
);

create policy "Authenticated users can update images"
on storage.objects for update
to authenticated
using ( bucket_id = 'product-images' )
with check ( bucket_id = 'product-images' );

create policy "Authenticated users can delete images"
on storage.objects for delete
to authenticated
using ( bucket_id = 'product-images' );