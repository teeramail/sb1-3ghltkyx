#!/bin/bash

# Get table name from argument
TABLE_NAME=$1
if [ -z "$TABLE_NAME" ]; then
  echo "Please provide a table name as an argument"
  echo "Usage: ./setup-crud.sh <table_name>"
  exit 1
fi

# Convert table name to proper case for interface name
INTERFACE_NAME="$(tr '[:lower:]' '[:upper:]' <<< ${TABLE_NAME:0:1})${TABLE_NAME:1}"

# Create necessary directories
mkdir -p src/lib src/components src/types

# Create Supabase client file if it doesn't exist
if [ ! -f src/lib/supabase.ts ]; then
  cat > src/lib/supabase.ts << 'EOL'
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
EOL
fi

# Create ImageUpload component if it doesn't exist
if [ ! -f src/components/ImageUpload.tsx ]; then
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
        .from('uploads')
        .upload(fileName, file);

      if (error) throw error;

      const { data: { publicUrl } } = supabase.storage
        .from('uploads')
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
fi

# Create types file for the table
cat > "src/types/${TABLE_NAME}.ts" << EOL
export interface ${INTERFACE_NAME} {
  id: string;
  created_at: string;
  // Add your table-specific fields here
}

export interface ${INTERFACE_NAME}FormData {
  // Add your form-specific fields here
}
EOL

# Create or update index.css with Tailwind directives
cat > src/index.css << 'EOL'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOL

# Update or create tailwind.config.js
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

# Create or update package.json if it doesn't exist
if [ ! -f package.json ]; then
  cat > package.json << EOL
{
  "name": "crud-app",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "lint": "eslint .",
    "preview": "vite preview"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.39.7",
    "lucide-react": "^0.344.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-hot-toast": "^2.4.1"
  },
  "devDependencies": {
    "@eslint/js": "^9.9.1",
    "@types/react": "^18.3.5",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.1",
    "autoprefixer": "^10.4.18",
    "eslint": "^9.9.1",
    "eslint-plugin-react-hooks": "^5.1.0-rc.0",
    "eslint-plugin-react-refresh": "^0.4.11",
    "globals": "^15.9.0",
    "postcss": "^8.4.35",
    "tailwindcss": "^3.4.1",
    "typescript": "^5.5.3",
    "typescript-eslint": "^8.3.0",
    "vite": "^5.4.2"
  }
}
EOL

  # Install dependencies
  npm install
fi

# Make the script executable
chmod +x setup-crud.sh

echo "Setup complete! Now you need to:"
echo "1. Update src/types/${TABLE_NAME}.ts with your table-specific fields"
echo "2. Create your table component in src/components/${INTERFACE_NAME}List.tsx"
echo "3. Update App.tsx to use your new component"
echo "4. Ensure your Supabase table is created with the correct schema"
echo "5. Create a storage bucket named 'uploads' in your Supabase project if you plan to use image uploads"