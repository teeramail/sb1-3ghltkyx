/*
  # Create Storage Bucket for Product Images

  1. Changes
    - Creates a new public storage bucket for product images
    - Enables public access to the bucket
*/

-- Create a storage bucket for product images
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true);

-- Create a policy to allow public access to the bucket
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'product-images');

-- Update products with image URLs
UPDATE products
SET main_image_url = CASE 
  WHEN sku = 'GM-001' THEN 'https://ctlsaoxdlxstebmdibsh.supabase.co/storage/v1/object/public/product-images/gaming-mouse.webp'
  WHEN sku = 'KB-002' THEN 'https://ctlsaoxdlxstebmdibsh.supabase.co/storage/v1/object/public/product-images/mechanical-keyboard.webp'
  WHEN sku = 'MON-003' THEN 'https://ctlsaoxdlxstebmdibsh.supabase.co/storage/v1/object/public/product-images/ultrawide-monitor.webp'
  WHEN sku = 'HS-004' THEN 'https://ctlsaoxdlxstebmdibsh.supabase.co/storage/v1/object/public/product-images/gaming-headset.webp'
  WHEN sku = 'MP-005' THEN 'https://ctlsaoxdlxstebmdibsh.supabase.co/storage/v1/object/public/product-images/mousepad.webp'
  END
WHERE sku IN ('GM-001', 'KB-002', 'MON-003', 'HS-004', 'MP-005');