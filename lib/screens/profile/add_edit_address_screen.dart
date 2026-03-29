import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';
import 'package:wholeseller/services/api_service.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _labelController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.address?['label'] ?? 'Home');
    _addressController = TextEditingController(text: widget.address?['address']);
    _cityController = TextEditingController(text: widget.address?['city']);
    _stateController = TextEditingController(text: widget.address?['state']);
    _pincodeController = TextEditingController(text: widget.address?['pincode']);
    _isDefault = widget.address?['is_default'] ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final addressData = {
        'label': _labelController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'is_default': _isDefault,
      };

      if (widget.address != null) {
        await _apiService.updateAddress(widget.address!['id'], addressData);
      } else {
        await _apiService.createAddress(addressData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.address != null ? 'Address updated' : 'Address added')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.address != null ? 'Edit Address' : 'Add New Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_labelController, 'Label (e.g. Home, Office)', Icons.label),
              const SizedBox(height: 16),
              _buildTextField(_addressController, 'Address Line', Icons.location_on, maxLines: 2),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_cityController, 'City', Icons.location_city)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_stateController, 'State', Icons.map)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_pincodeController, 'Pincode', Icons.pin_drop, inputType: TextInputType.number),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Set as Default Address'),
                value: _isDefault,
                activeColor: AppTheme.primaryColor,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.address != null ? 'Update Address' : 'Save Address', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType inputType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (value) => value == null || value.isEmpty ? '$label is required' : null,
    );
  }
}
