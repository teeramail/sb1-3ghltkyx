import React, { useEffect, useState } from 'react';
import { Plus, Pencil, Trash2, Search, ChevronLeft, ChevronRight } from 'lucide-react';
import { toast, Toaster } from 'react-hot-toast';
import { supabase } from './lib/supabase';
import { ImageUpload } from './components/ImageUpload';
import type { Product, ProductFormData } from './types/product';

function App() {
  const [products, setProducts] = useState<Product[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalProducts, setTotalProducts] = useState(0);
  const productsPerPage = 9;

  const [formData, setFormData] = useState<ProductFormData>({
    name: '',
    sku: '',
    upc: '',
    ean: '',
    description: '',
    short_description: '',
    base_price: 0,
    stock_quantity: 0,
    status: 'draft',
    visibility: 'visible',
    is_digital: false,
    main_image_url: '',
  });

  useEffect(() => {
    fetchProducts();
  }, [searchQuery, currentPage]);

  const fetchProducts = async () => {
    try {
      setIsLoading(true);
      
      // First, get total count for pagination
      const countQuery = supabase
        .from('products')
        .select('product_id', { count: 'exact' })
        .ilike('name', `%${searchQuery}%`);

      const { count, error: countError } = await countQuery;
      
      if (countError) throw countError;
      setTotalProducts(count || 0);

      // Then fetch paginated products
      const { data, error } = await supabase
        .from('products')
        .select('*')
        .ilike('name', `%${searchQuery}%`)
        .order('created_at', { ascending: false })
        .range((currentPage - 1) * productsPerPage, currentPage * productsPerPage - 1);

      if (error) throw error;
      setProducts(data || []);
    } catch (error) {
      console.error('Error fetching products:', error);
      toast.error('Failed to fetch products');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      // Generate a unique SKU if not provided
      const sku = formData.sku || `SKU-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`.toUpperCase();
      
      const productData = {
        name: formData.name,
        sku: sku,
        upc: formData.upc || null,
        ean: formData.ean || null,
        description: formData.description || null,
        short_description: formData.short_description || null,
        base_price: formData.base_price,
        stock_quantity: formData.stock_quantity,
        status: formData.status,
        visibility: formData.visibility,
        is_digital: formData.is_digital,
        main_image_url: formData.main_image_url || null,
        slug: formData.name.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
        is_in_stock: formData.stock_quantity > 0,
      };

      if (isEditing && selectedProduct) {
        const { error } = await supabase
          .from('products')
          .update(productData)
          .eq('product_id', selectedProduct.product_id);

        if (error) throw error;
        toast.success('Product updated successfully');
      } else {
        const { error } = await supabase
          .from('products')
          .insert([productData]);

        if (error) throw error;
        toast.success('Product created successfully');
      }

      setFormData({
        name: '',
        sku: '',
        upc: '',
        ean: '',
        description: '',
        short_description: '',
        base_price: 0,
        stock_quantity: 0,
        status: 'draft',
        visibility: 'visible',
        is_digital: false,
        main_image_url: '',
      });
      setIsEditing(false);
      setSelectedProduct(null);
      fetchProducts();
    } catch (error) {
      console.error('Error saving product:', error);
      toast.error('Failed to save product');
    }
  };

  const handleEdit = (product: Product) => {
    setIsEditing(true);
    setSelectedProduct(product);
    setFormData({
      name: product.name,
      sku: product.sku || '',
      upc: product.upc || '',
      ean: product.ean || '',
      description: product.description || '',
      short_description: product.short_description || '',
      base_price: product.base_price || 0,
      stock_quantity: product.stock_quantity || 0,
      status: product.status || 'draft',
      visibility: product.visibility || 'visible',
      is_digital: product.is_digital || false,
      main_image_url: product.main_image_url || '',
    });
  };

  const handleDelete = async (productId: string) => {
    if (!confirm('Are you sure you want to delete this product?')) return;

    try {
      const { error } = await supabase
        .from('products')
        .delete()
        .eq('product_id', productId);

      if (error) throw error;
      toast.success('Product deleted successfully');
      fetchProducts();
    } catch (error) {
      console.error('Error deleting product:', error);
      toast.error('Failed to delete product');
    }
  };

  const handleImageUpload = (url: string) => {
    setFormData(prev => ({ ...prev, main_image_url: url }));
  };

  const totalPages = Math.ceil(totalProducts / productsPerPage);

  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchQuery(e.target.value);
    setCurrentPage(1); // Reset to first page when searching
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <p className="text-gray-600">Loading products...</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 p-4 sm:p-6 lg:p-8">
      <Toaster position="top-right" />
      
      <div className="max-w-6xl mx-auto">
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="p-6 border-b border-gray-100">
            <h1 className="text-xl font-semibold text-gray-900">Products</h1>
          </div>

          <form onSubmit={handleSubmit} className="p-6 border-b border-gray-100 bg-gray-50">
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="sm:col-span-2">
                <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                  Product Name *
                </label>
                <input
                  type="text"
                  id="name"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  required
                />
              </div>

              <div>
                <label htmlFor="sku" className="block text-sm font-medium text-gray-700">
                  SKU (auto-generated if empty)
                </label>
                <input
                  type="text"
                  id="sku"
                  value={formData.sku}
                  onChange={(e) => setFormData({ ...formData, sku: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  placeholder="Leave empty for auto-generation"
                />
              </div>

              <div>
                <label htmlFor="base_price" className="block text-sm font-medium text-gray-700">
                  Base Price *
                </label>
                <div className="mt-1 relative rounded-md shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <span className="text-gray-500 sm:text-sm">$</span>
                  </div>
                  <input
                    type="number"
                    id="base_price"
                    value={formData.base_price}
                    onChange={(e) => setFormData({ ...formData, base_price: Number(e.target.value) })}
                    className="pl-7 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                    min="0"
                    step="0.01"
                    required
                  />
                </div>
              </div>

              <div>
                <label htmlFor="stock_quantity" className="block text-sm font-medium text-gray-700">
                  Stock Quantity *
                </label>
                <input
                  type="number"
                  id="stock_quantity"
                  value={formData.stock_quantity}
                  onChange={(e) => setFormData({ ...formData, stock_quantity: Number(e.target.value) })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  min="0"
                  required
                />
              </div>

              <div>
                <label htmlFor="status" className="block text-sm font-medium text-gray-700">
                  Status
                </label>
                <select
                  id="status"
                  value={formData.status}
                  onChange={(e) => setFormData({ ...formData, status: e.target.value as any })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                >
                  <option value="draft">Draft</option>
                  <option value="published">Published</option>
                  <option value="archived">Archived</option>
                  <option value="discontinued">Discontinued</option>
                </select>
              </div>

              <div>
                <label htmlFor="visibility" className="block text-sm font-medium text-gray-700">
                  Visibility
                </label>
                <select
                  id="visibility"
                  value={formData.visibility}
                  onChange={(e) => setFormData({ ...formData, visibility: e.target.value as any })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                >
                  <option value="visible">Visible</option>
                  <option value="hidden">Hidden</option>
                  <option value="search_only">Search Only</option>
                  <option value="catalog_only">Catalog Only</option>
                </select>
              </div>

              <div className="sm:col-span-2">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Product Image
                </label>
                <ImageUpload onUploadComplete={handleImageUpload} />
                {formData.main_image_url && (
                  <div className="mt-2">
                    <img
                      src={formData.main_image_url}
                      alt="Product preview"
                      className="h-32 w-32 object-cover rounded-lg"
                    />
                  </div>
                )}
              </div>

              <div className="sm:col-span-2">
                <label htmlFor="description" className="block text-sm font-medium text-gray-700">
                  Description
                </label>
                <textarea
                  id="description"
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  rows={3}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
              </div>

              <div className="sm:col-span-2">
                <label htmlFor="short_description" className="block text-sm font-medium text-gray-700">
                  Short Description
                </label>
                <textarea
                  id="short_description"
                  value={formData.short_description}
                  onChange={(e) => setFormData({ ...formData, short_description: e.target.value })}
                  rows={2}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
              </div>

              <div className="sm:col-span-2">
                <button
                  type="submit"
                  className="w-full inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  {isEditing ? (
                    <>
                      <Pencil className="w-4 h-4 mr-2" />
                      Update Product
                    </>
                  ) : (
                    <>
                      <Plus className="w-4 h-4 mr-2" />
                      Add Product
                    </>
                  )}
                </button>
              </div>
            </div>
          </form>

          <div className="p-6 border-b border-gray-100 bg-white">
            <div className="relative max-w-xs mx-auto sm:max-w-md">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
              <input
                type="text"
                placeholder="Search products..."
                value={searchQuery}
                onChange={handleSearch}
                className="pl-10 pr-4 py-2 w-full border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 p-6">
            {products.map((product) => (
              <div key={product.product_id} className="bg-white rounded-lg border border-gray-200 overflow-hidden hover:shadow-md transition-shadow">
                {product.main_image_url && (
                  <div className="aspect-w-16 aspect-h-9 bg-gray-100">
                    <img
                      src={product.main_image_url}
                      alt={product.name}
                      className="w-full h-48 object-cover"
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.src = 'https://via.placeholder.com/400x300?text=No+Image';
                      }}
                    />
                  </div>
                )}
                <div className="p-4">
                  <div className="flex items-center justify-between">
                    <h3 className="text-lg font-medium text-gray-900 truncate">
                      {product.name}
                    </h3>
                    <p className="ml-2 text-lg font-medium text-gray-900">
                      ${product.base_price?.toFixed(2)}
                    </p>
                  </div>
                  <p className="mt-1 text-sm text-gray-500 truncate">
                    SKU: {product.sku}
                  </p>
                  {product.short_description && (
                    <p className="mt-2 text-sm text-gray-600 line-clamp-2">
                      {product.short_description}
                    </p>
                  )}
                  <div className="mt-4 flex items-center justify-between">
                    <span className="text-sm text-gray-500">
                      Stock: {product.stock_quantity}
                    </span>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => handleEdit(product)}
                        className="p-1 text-gray-400 hover:text-indigo-600"
                      >
                        <Pencil className="w-5 h-5" />
                      </button>
                      <button
                        onClick={() => handleDelete(product.product_id)}
                        className="p-1 text-gray-400 hover:text-red-600"
                      >
                        <Trash2 className="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            ))}
            {products.length === 0 && (
              <div className="col-span-full text-center py-12 text-sm text-gray-500">
                {searchQuery ? 'No products found matching your search.' : 'No products found. Add your first product above.'}
              </div>
            )}
          </div>

          {totalPages > 1 && (
            <div className="flex items-center justify-between px-6 py-4 border-t border-gray-100">
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                  disabled={currentPage === 1}
                  className="p-2 rounded-md border border-gray-300 disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
                >
                  <ChevronLeft className="w-5 h-5" />
                </button>
                <span className="text-sm text-gray-700">
                  Page {currentPage} of {totalPages}
                </span>
                <button
                  onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                  disabled={currentPage === totalPages}
                  className="p-2 rounded-md border border-gray-300 disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
                >
                  <ChevronRight className="w-5 h-5" />
                </button>
              </div>
              <div className="text-sm text-gray-500">
                Total products: {totalProducts}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default App;