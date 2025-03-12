/*
  # Configure Storage Settings and Policies

  1. Storage Configuration
    - Enable S3 protocol access
    - Set up storage bucket with proper configuration
    - Configure RLS policies for authenticated users

  2. Security
    - Enable RLS on storage.objects
    - Set up proper policies for file access and management
*/

-- Create bucket if it doesn't exist with proper configuration
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

-- Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DO $$
BEGIN
    DROP POLICY IF EXISTS "Public Access" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can update own images" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can delete own images" ON storage.objects;
END $$;

-- Create comprehensive policies
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'product-images');

CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'product-images'
    AND (COALESCE(owner, auth.uid()) = auth.uid())
    AND (CASE 
        WHEN metadata->>'content-type' IS NOT NULL 
        THEN metadata->>'content-type' = ANY(ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']::text[])
        ELSE false
    END)
    AND (COALESCE((metadata->>'size')::int, 0) <= 5242880)
);

CREATE POLICY "Authenticated users can update own images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'product-images' AND owner = auth.uid())
WITH CHECK (bucket_id = 'product-images' AND owner = auth.uid());

CREATE POLICY "Authenticated users can delete own images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'product-images' AND owner = auth.uid());