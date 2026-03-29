import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';
import 'package:wholeseller/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminAddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const AdminAddProductScreen({super.key, this.product});

  @override
  State<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends State<AdminAddProductScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _dosageController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _packSizeController = TextEditingController();

  List<String> _imageUrls = [];
  List<XFile> _newImages = [];
  List<dynamic> _categories = [];
  List<Map<String, dynamic>> _variants = [];
  final List<TextEditingController> _variantStrengthCtrls = [];
  final List<TextEditingController> _variantPtrCtrls = [];
  final List<TextEditingController> _variantMrpCtrls = [];
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  bool _isActive = true;
  bool _requiresPrescription = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _nameController.text = widget.product!['name'] ?? '';
      _descriptionController.text = widget.product!['description'] ?? '';
      _selectedCategoryId = widget.product!['category'] ?? '';
      _stockController.text = (widget.product!['stock'] ?? 0).toString();
      _imageUrls = List<String>.from(widget.product!['images'] ?? []);
      _isActive = widget.product!['is_active'] ?? true;

      final pricingTiers = widget.product!['pricing_tiers'] as Map<String, dynamic>? ?? {};
      if (pricingTiers.isNotEmpty) {
        _priceController.text = pricingTiers.values.first.toString();
      }
      final vList = widget.product!['variants'] as List<dynamic>? ?? [];
      for (final v in vList) {
        final m = v as Map<String, dynamic>;
        _variants.add(Map<String, dynamic>.from(m));
        _variantStrengthCtrls.add(TextEditingController(text: (m['strength'] ?? '').toString()));
        _variantPtrCtrls.add(TextEditingController(text: (m['ptr'] ?? m['price'] ?? 0).toString()));
        _variantMrpCtrls.add(TextEditingController(text: (m['mrp'] ?? 0).toString()));
      }
    }
  }

  @override
  void dispose() {
    for (final ctrl in _variantStrengthCtrls) ctrl.dispose();
    for (final ctrl in _variantPtrCtrls) ctrl.dispose();
    for (final ctrl in _variantMrpCtrls) ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories(activeOnly: true);
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Allow picking multiple images
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImages.addAll(pickedFiles);
      });
    }
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
        setState(() => _isLoading = false);
        return;
      }

      final price = double.tryParse(_priceController.text) ?? 0.0;

      final productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'category': _selectedCategoryId,
        'moq': 1,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'pricing_tiers': {'unit': price},
        'images': _imageUrls,
        'is_active': _isActive,
        'variants': _variantStrengthCtrls.asMap().entries.map((e) {
          final i = e.key;
          return {
            'strength': _variantStrengthCtrls[i].text,
            'ptr': double.tryParse(_variantPtrCtrls[i].text) ?? 0.0,
            'mrp': double.tryParse(_variantMrpCtrls[i].text) ?? 0.0,
          };
        }).where((v) => (v['strength'] as String).isNotEmpty).toList(),
        'dosage': _dosageController.text,
        'manufacturer': _manufacturerController.text,
        'pack_size': _packSizeController.text,
        'expiry_date': null,
      };

      String productId;
      if (widget.product != null) {
        productId = widget.product!['id'];
        await _apiService.updateProduct(productId, productData);
      } else {
        final result = await _apiService.createProduct(productData);
        productId = result['id'];
      }

      // Upload new images
      for (var imageFile in _newImages) {
        final imageBytes = await imageFile.readAsBytes(); // Works on Web and Mobile
        final filename = imageFile.name; // XFile has name property
        final imageUrl = await _apiService.uploadProductImage(productId, imageBytes, filename);
        _imageUrls.add(imageUrl);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.product != null ? 'Medicine updated' : 'Medicine added')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Medicine' : 'Add Medicine', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Basic Information
                    _buildSection(
                      'Medicine Details',
                      Column(
                        children: [
                          _buildTextField(_nameController, 'Medicine Name', 'e.g., Paracetamol 500mg'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _isLoadingCategories
                                    ? const CircularProgressIndicator()
                                    : DropdownButtonFormField<String>(
                                        value: _selectedCategoryId,
                                        decoration: _inputDecoration('Category'),
                                        items: _categories.map((cat) => DropdownMenuItem<String>(value: cat['id'], child: Text(cat['name'] ?? ''))).toList(),
                                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                                  onPressed: _showAddCategoryDialog,
                                  tooltip: 'Add New Category',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(_descriptionController, 'Description', 'Usage, side effects, etc.', maxLines: 3),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pricing & Stock
                    _buildSection(
                      'Pricing & Stock',
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildTextField(_priceController, 'Price (₹)', '0.00', isNumber: true)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField(_stockController, 'Stock', '0', isNumber: true)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Variants (mg strength & price)
                    _buildSection(
                      'Variants (Strength in mg)',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add strength variants with PTR/MRP. Leave empty to use default (250mg, dosage, 1000mg).', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 12),
                          ...List.generate(_variants.length, (i) => _buildVariantRow(i)),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _variants.add({'strength': '500 mg', 'ptr': 50.0, 'mrp': 65.0});
                                _variantStrengthCtrls.add(TextEditingController(text: '500 mg'));
                                _variantPtrCtrls.add(TextEditingController(text: '50'));
                                _variantMrpCtrls.add(TextEditingController(text: '65'));
                              });
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Variant'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Medical Info
                    _buildSection(
                      'Medical Information',
                      Column(
                        children: [
                          _buildTextField(_dosageController, 'Dosage', 'e.g., 500mg'),
                          const SizedBox(height: 16),
                          _buildTextField(_manufacturerController, 'Manufacturer', 'e.g., Generic Pharma Ltd.'),
                          const SizedBox(height: 16),
                          _buildTextField(_packSizeController, 'Pack Size', 'e.g., 10 Tablets/Strip'),
                          const SizedBox(height: 16),
                          _buildSwitchRow('Prescription Required', _requiresPrescription, (v) => setState(() => _requiresPrescription = v)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Images
                    _buildSection(
                      'Medicine Images',
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_photo_alternate, size: 36, color: AppTheme.primaryColor),
                                    SizedBox(height: 8),
                                    Text('Upload Image', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_imageUrls.isNotEmpty || _newImages.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 80,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  ..._imageUrls.map((url) => _buildThumb(NetworkImage(url), () => setState(() => _imageUrls.remove(url)))),
                                  ..._newImages.map((file) => _buildThumb(_getImageProvider(file), () => setState(() => _newImages.remove(file)))),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Status
                    _buildSection(
                      'Status',
                      _buildSwitchRow('Active', _isActive, (v) => setState(() => _isActive = v)),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMedicine,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(widget.product != null ? 'Update Medicine' : 'Add Medicine', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: _inputDecoration(label, hint: hint),
      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppTheme.surfaceColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildSwitchRow(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primaryColor),
      ],
    );
  }

  Widget _buildVariantRow(int index) {
    if (index >= _variantStrengthCtrls.length) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(flex: 2, child: TextFormField(controller: _variantStrengthCtrls[index], decoration: const InputDecoration(labelText: 'Strength (e.g. 500 mg)'))),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: _variantPtrCtrls[index], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PTR'))),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: _variantMrpCtrls[index], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'MRP'))),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                _variantStrengthCtrls[index].dispose();
                _variantPtrCtrls[index].dispose();
                _variantMrpCtrls[index].dispose();
                _variantStrengthCtrls.removeAt(index);
                _variantPtrCtrls.removeAt(index);
                _variantMrpCtrls.removeAt(index);
                _variants.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThumb(ImageProvider image, VoidCallback onDelete) {
    return Container(
      width: 70,
      height: 70,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: image, fit: BoxFit.cover)),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                await _apiService.createCategory({'name': nameController.text.trim(), 'is_active': true});
                Navigator.pop(context);
                _loadCategories(); // Reload to show new category
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category added')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(XFile file) {
    if (kIsWeb) {
      return NetworkImage(file.path);
    } else {
      return FileImage(File(file.path));
    }
  }
}
