/*
  # Fix Storage Permissions

  1. Storage Setup
    - Create product-images bucket with public access
    - Configure proper RLS policies for storage objects
    - Enable authenticated users to manage their uploads
    - Allow public read access to images

  2. Security
    - Enable RLS on storage.objects
    - Add policies for CRUD operations
*/

-- Create bucket if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM storage.buckets WHERE id = 'product-images'
    ) THEN
        INSERT INTO storage.buckets (id, name, public)
        VALUES ('product-images', 'product-images', true);
    END IF;
END $$;

-- Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DO $$
BEGIN
    DROP POLICY IF EXISTS "Public Access" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can update images" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can delete images" ON storage.objects;
END $$;

-- Create new policies
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'product-images');

CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'product-images'
    AND owner = auth.uid()
);

CREATE POLICY "Authenticated users can update images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'product-images' AND owner = auth.uid())
WITH CHECK (bucket_id = 'product-images' AND owner = auth.uid());

CREATE POLICY "Authenticated users can delete images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'product-images' AND owner = auth.uid());