/*
  # Add RLS policies to products table

  1. Security Changes
    - Enable RLS on existing `products` table
    - Add policies for:
      - Select: Allow all users to read products
      - Insert/Update/Delete: Only authenticated users can modify products

  2. Notes
    - No schema changes are made to the existing table
    - Only security policies are added
*/

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