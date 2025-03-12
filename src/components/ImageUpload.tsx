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

    // Validate file type
    if (!file.type.startsWith('image/')) {
      toast.error('Please upload an image file');
      return;
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      toast.error('File size must be less than 5MB');
      return;
    }

    try {
      setIsUploading(true);
      
      // Generate a unique file name
      const fileExt = file.name.split('.').pop();
      const fileName = `${Math.random().toString(36).substring(2)}_${Date.now()}.${fileExt}`;
      
      // Upload file to Supabase Storage
      const { data, error } = await supabase.storage
        .from('product-images')
        .upload(fileName, file);

      if (error) throw error;

      // Get the public URL
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

    // Create a drop event to reuse the upload logic
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