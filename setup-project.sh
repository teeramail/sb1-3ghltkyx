#!/bin/bash

# Create a new Vite project with React and TypeScript
npm create vite@latest . --template react-ts -- --yes

# Install required dependencies
npm install @supabase/supabase-js lucide-react react-hot-toast

# Install dev dependencies
npm install -D autoprefixer postcss tailwindcss

# Initialize Tailwind CSS
npx tailwindcss init -p

# Create necessary directories
mkdir -p src/lib src/components src/types

# Create Supabase client file
cat > src/lib/supabase.ts << 'EOL'
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
EOL

# Create product types
cat > src/types/product.ts << 'EOL'
export interface Product {
  product_id: string;
  sku: string | null;
  upc: string | null;
  ean: string | null;
  name: string;
  slug: string;
  description: string | null;
  short_description: string | null;
  category_id: string | null;
  brand_id: string | null;
  tags: string[] | null;
  base_price: number;
  discount_price: number | null;
  cost_price: number | null;
  currency: string;
  tax_category: string | null;
  tax_rate: number | null;
  is_taxable: boolean;
  stock_quantity: number;
  min_stock_threshold: number;
  is_in_stock: boolean;
  backorder_allowed: boolean;
  weight: number | null;
  weight_unit: string;
  length: number | null;
  width: number | null;
  height: number | null;
  dimension_unit: string;
  has_variants: boolean;
  parent_product_id: string | null;
  variant_attributes: Record<string, any> | null;
  is_digital: boolean;
  digital_file_path: string | null;
  download_limit: number | null;
  main_image_url: string | null;
  additional_images: string[] | null;
  video_url: string | null;
  meta_title: string | null;
  meta_description: string | null;
  meta_keywords: string | null;
  search_terms: string[] | null;
  status: 'draft' | 'published' | 'archived' | 'discontinued';
  visibility: 'visible' | 'hidden' | 'search_only' | 'catalog_only';
  featured: boolean;
  is_shippable: boolean;
  shipping_class: string | null;
  free_shipping: boolean;
  shipping_weight: number | null;
  supplier_id: string | null;
  supplier_sku: string | null;
  lead_time: number | null;
  min_order_quantity: number;
  warranty_info: string | null;
  return_policy_id: string | null;
  average_rating: number | null;
  rating_count: number;
  review_count: number;
  related_products: string[] | null;
  upsell_products: string[] | null;
  cross_sell_products: string[] | null;
  created_at: string;
  updated_at: string;
  published_at: string | null;
  created_by: string | null;
  updated_by: string | null;
  custom_attributes: Record<string, any> | null;
}

export interface ProductFormData {
  name: string;
  sku: string;
  upc: string;
  ean: string;
  description: string;
  short_description: string;
  base_price: number;
  stock_quantity: number;
  status: 'draft' | 'published' | 'archived' | 'discontinued';
  visibility: 'visible' | 'hidden' | 'search_only' | 'catalog_only';
  is_digital: boolean;
  main_image_url: string;
}
EOL

# Create ImageUpload component
cat > src/components/ImageUpload.tsx << 'EOL'
import React, { useCallback, useState } from 'react';
import { Upload } from 'lucide-react';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';

interface ImageUploadProps {
  onUploadComplete: (url: string) => void;
}

export function ImageUpload({ onUploadComplete }: ImageUploadProps) {
  const [isDragging, setIsDragging] = useState(false);
  const [isUploading, setIsUploading] = useState(false);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
  }, []);

  const handleDrop = useCallback(async (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);

    const file = e.dataTransfer.files[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      toast.error('Please upload an image file');
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      toast.error('File size must be less than 5MB');
      return;
    }

    try {
      setIsUploading(true);
      
      const fileExt = file.name.split('.').pop();
      const fileName = `${Math.random().toString(36).substring(2)}_${Date.now()}.${fileExt}`;
      
      const { data, error } = await supabase.storage
        .from('product-images')
        .upload(fileName, file);

      if (error) throw error;

      const { data: { publicUrl } } = supabase.storage
        .from('product-images')
        .getPublicUrl(fileName);

      onUploadComplete(publicUrl);
      toast.success('Image uploaded successfully');
    } catch (error) {
      console.error('Error uploading image:', error);
      toast.error('Failed to upload image');
    } finally {
      setIsUploading(false);
    }
  }, [onUploadComplete]);

  const handleFileSelect = useCallback(async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const dropEvent = new Event('drop', { bubbles: true }) as unknown as React.DragEvent;
    dropEvent.dataTransfer = {
      files: [file]
    } as DataTransfer;

    handleDrop(dropEvent);
  }, [handleDrop]);

  return (
    <div
      className={`relative border-2 border-dashed rounded-lg p-6 transition-colors ${
        isDragging ? 'border-indigo-500 bg-indigo-50' : 'border-gray-300 hover:border-gray-400'
      }`}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      <input
        type="file"
        accept="image/*"
        className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
        onChange={handleFileSelect}
      />
      <div className="text-center">
        <Upload className="mx-auto h-12 w-12 text-gray-400" />
        <div className="mt-4 flex text-sm leading-6 text-gray-600">
          <label className="relative cursor-pointer rounded-md font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500">
            <span>Upload a file</span>
          </label>
          <p className="pl-1">or drag and drop</p>
        </div>
        <p className="text-xs leading-5 text-gray-600">PNG, JPG, GIF up to 5MB</p>
      </div>
      {isUploading && (
        <div className="absolute inset-0 bg-white bg-opacity-75 flex items-center justify-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        </div>
      )}
    </div>
  );
}
EOL

# Update index.css with Tailwind directives
cat > src/index.css << 'EOL'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOL

# Update tailwind.config.js
cat > tailwind.config.js << 'EOL'
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {},
  },
  plugins: [],
};
EOL

# Make the script executable
chmod +x setup-project.sh