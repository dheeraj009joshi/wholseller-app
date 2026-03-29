import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';
import 'package:wholeseller/services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _businessNameController;
  late TextEditingController _gstController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']);
    _phoneController = TextEditingController(text: widget.user['phone']);
    _businessNameController = TextEditingController(text: widget.user['business_name']);
    _gstController = TextEditingController(text: widget.user['gst_number']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'business_name': _businessNameController.text.trim(),
        'gst_number': _gstController.text.trim(),
      };

      await _apiService.updateUser(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
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
        title: const Text('Edit Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
               _buildTextField(_nameController, 'Full Name', Icons.person),
               const SizedBox(height: 16),
               _buildTextField(_phoneController, 'Phone Number', Icons.phone, inputType: TextInputType.phone),
               const SizedBox(height: 16),
               _buildTextField(_businessNameController, 'Business Name', Icons.business),
               const SizedBox(height: 16),
               _buildTextField(_gstController, 'GST Number (Optional)', Icons.receipt),
               const SizedBox(height: 32),
               
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: _isLoading ? null : _updateProfile,
                   style: ElevatedButton.styleFrom(
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     backgroundColor: AppTheme.primaryColor,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                   child: _isLoading 
                       ? const CircularProgressIndicator(color: Colors.white)
                       : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (value) {
        if (label != 'GST Number (Optional)' && (value == null || value.isEmpty)) {
          return '$label is required';
        }
        return null;
      },
    );
  }
}
