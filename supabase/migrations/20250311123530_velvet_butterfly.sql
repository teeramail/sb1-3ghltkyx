/*
  # Remove RLS from products table

  1. Security Changes
    - Disable RLS on products table
    - Drop all existing policies
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow public read access" ON products;
DROP POLICY IF EXISTS "Allow authenticated users to create products" ON products;
DROP POLICY IF EXISTS "Allow authenticated users to update their products" ON products;
DROP POLICY IF EXISTS "Allow authenticated users to delete their products" ON products;

-- Disable Row Level Security
ALTER TABLE products DISABLE ROW LEVEL SECURITY;