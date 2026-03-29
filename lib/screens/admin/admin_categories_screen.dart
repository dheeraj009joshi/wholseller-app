import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';
import 'package:wholeseller/services/api_service.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories(activeOnly: false);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  static IconData _iconFromName(String? name) {
    const map = <String, IconData>{
      'medication': Icons.medication,
      'favorite': Icons.favorite,
      'eco': Icons.eco,
      'restaurant': Icons.restaurant,
      'monitor_heart': Icons.monitor_heart,
      'spa': Icons.spa,
      'local_hospital': Icons.local_hospital,
      'category': Icons.category,
    };
    return map[name ?? ''] ?? Icons.category;
  }

  Widget _buildCategoryLeading(String? imageUrl, String? iconName, bool isActive) {
    final color = isActive ? AppTheme.primaryColor : AppTheme.textSecondary;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(_iconFromName(iconName), color: color, size: 32),
          ),
        ),
      );
    }
    return Icon(_iconFromName(iconName), color: color, size: 32);
  }

  Future<void> _showAddCategoryDialog({Map<String, dynamic>? category}) async {
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final descriptionController = TextEditingController(text: category?['description'] ?? '');
    final imageUrlController = TextEditingController(text: category?['image_url'] ?? '');
    final iconController = TextEditingController(text: category?['icon'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category != null ? 'Edit Category' : 'Add Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (Optional)',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(
                  labelText: 'Icon name (Optional)',
                  hintText: 'medication, favorite, eco, restaurant, monitor_heart, spa',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category name is required')),
                );
                return;
              }

              try {
                final categoryData = {
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  'is_active': category?['is_active'] ?? true,
                  'image_url': imageUrlController.text.trim().isEmpty ? null : imageUrlController.text.trim(),
                  'icon': iconController.text.trim().isEmpty ? null : iconController.text.trim(),
                };

                if (category != null) {
                  await _apiService.updateCategory(category['id'], categoryData);
                } else {
                  await _apiService.createCategory(categoryData);
                }

                if (mounted) {
                  Navigator.pop(context);
                  _loadCategories();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(category != null
                          ? 'Category updated successfully'
                          : 'Category created successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(category != null ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(String categoryId) async {
    try {
      await _apiService.deleteCategory(categoryId);
      _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting category: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No categories found',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showAddCategoryDialog(),
                        child: const Text('Add Category'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isActive = category['is_active'] ?? true;

                    final imageUrl = category['image_url'] as String?;
                    final iconName = category['icon'] as String?;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: _buildCategoryLeading(imageUrl, iconName, isActive),
                        title: Text(
                          category['name'] ?? '',
                          style: TextStyle(
                            decoration: isActive ? null : TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: category['description'] != null
                            ? Text(category['description'])
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.textSecondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Inactive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddCategoryDialog(category: category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Category'),
                                    content: const Text(
                                        'Are you sure you want to delete this category? Products using this category will be affected.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteCategory(category['id']);
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: AppTheme.errorColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
