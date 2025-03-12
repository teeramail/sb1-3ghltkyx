/*
  # Disable Storage RLS and Configure Public Access
  
  1. Storage Configuration
    - Disable RLS on storage.objects
    - Configure bucket for public access
    
  2. Changes
    - Remove RLS from storage.objects
    - Ensure bucket exists with public access
*/

-- Create bucket if it doesn't exist with public access
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM storage.buckets WHERE id = 'product-images'
    ) THEN
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES (
            'product-images',
            'product-images',
            true,
            5242880, -- 5MB in bytes
            ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']::text[]
        );
    END IF;
END $$;

-- Disable RLS on storage.objects
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- Drop any existing policies since RLS is disabled
DO $$
BEGIN
    DROP POLICY IF EXISTS "Public Access" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can update own images" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can delete own images" ON storage.objects;
END $$;