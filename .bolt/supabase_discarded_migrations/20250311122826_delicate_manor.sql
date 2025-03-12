/*
  # Create products table

  1. New Tables
    - `products`
      - `product_id` (uuid, primary key)
      - `name` (varchar, required)
      - `description` (text, optional)
      - `price` (numeric, required)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `products` table
    - Add policies for:
      - Select: Allow all users to read products
      - Insert/Update/Delete: Only authenticated users can modify products
*/

CREATE TABLE IF NOT EXISTS products (
  product_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(255) NOT NULL,
  description text,
  price numeric(10,2) NOT NULL,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Enable Row Level Security
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow public read access"
  ON products
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Allow authenticated users to create products"
  ON products
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update their products"
  ON products
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to delete their products"
  ON products
  FOR DELETE
  TO authenticated
  USING (true);

-- Create trigger for updating the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();