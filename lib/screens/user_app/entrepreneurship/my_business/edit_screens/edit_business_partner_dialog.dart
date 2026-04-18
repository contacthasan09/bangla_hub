// lib/screens/user_app/entrepreneurship/networing_partner/edit_business_partner_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';

class EditBusinessPartnerDialog extends StatefulWidget {
  final NetworkingBusinessPartner partner;
  final VoidCallback onUpdate;

  const EditBusinessPartnerDialog({
    Key? key,
    required this.partner,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EditBusinessPartnerDialog> createState() => _EditBusinessPartnerDialogState();
}

class _EditBusinessPartnerDialogState extends State<EditBusinessPartnerDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _businessNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _descriptionController;
  late TextEditingController _industryController;
  late TextEditingController _yearsController;
  late TextEditingController _websiteController;
  late TextEditingController _serviceController;
  
  BusinessType? _selectedBusinessType;
  List<String> _servicesOffered = [];
  List<String> _socialMediaLinks = [];
  
  // Location
  double? _latitude;
  double? _longitude;
  String? _selectedState;
  String? _selectedCity;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.partner.businessName);
    _ownerNameController = TextEditingController(text: widget.partner.ownerName);
    _emailController = TextEditingController(text: widget.partner.email);
    _phoneController = TextEditingController(text: widget.partner.phone);
    _addressController = TextEditingController(text: widget.partner.address);
    _cityController = TextEditingController(text: widget.partner.city);
    _descriptionController = TextEditingController(text: widget.partner.description);
    _industryController = TextEditingController(text: widget.partner.industry);
    _yearsController = TextEditingController(text: widget.partner.yearsInBusiness.toString());
    _websiteController = TextEditingController(text: widget.partner.website ?? '');
    _serviceController = TextEditingController();
    
    _selectedBusinessType = widget.partner.businessType;
    _servicesOffered = List.from(widget.partner.servicesOffered);
    _socialMediaLinks = List.from(widget.partner.socialMediaLinks ?? []);
    _latitude = widget.partner.latitude;
    _longitude = widget.partner.longitude;
    _selectedState = widget.partner.state;
    _selectedCity = widget.partner.city;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _industryController.dispose();
    _yearsController.dispose();
    _websiteController.dispose();
    _serviceController.dispose();
    super.dispose();
  }

  Widget _buildLocationPickerField() {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => OSMLocationPicker(
            initialLatitude: _latitude,
            initialLongitude: _longitude,
            initialAddress: _addressController.text,
            initialState: _selectedState,
            initialCity: _cityController.text,
            onLocationSelected: (lat, lng, address, state, city) {
              setState(() {
                _latitude = lat;
                _longitude = lng;
                _selectedState = state;
                _selectedCity = city;
                _addressController.text = address;
                if (city != null) _cityController.text = city;
              });
            },
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: _latitude != null ? Colors.green[50] : null,
        ),
        child: Row(
          children: [
            Icon(Icons.map_rounded, color: const Color(0xFF006A4E)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF006A4E))),
                  Text(_addressController.text.isEmpty ? 'Tap to select location' : _addressController.text,
                      style: GoogleFonts.inter(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: isTablet ? 600 : double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF004D38)]),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.edit_rounded, color: Color(0xFFFFD700), size: 24)),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Edit Business Partner', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white)),
                ],
              ),
            ),
            
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(_businessNameController, 'Business Name', Icons.business_rounded),
                      const SizedBox(height: 12),
                      _buildTextField(_ownerNameController, 'Owner Name', Icons.person_rounded),
                      const SizedBox(height: 12),
                      _buildTextField(_emailController, 'Email', Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _buildTextField(_phoneController, 'Enter a valid US number *', Icons.phone_rounded, keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      _buildLocationPickerField(),
                      const SizedBox(height: 12),
                      _buildDropdown<BusinessType>(
                        value: _selectedBusinessType,
                        hint: 'Business Type',
                        items: BusinessType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.displayName))).toList(),
                        onChanged: (value) => setState(() => _selectedBusinessType = value),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_industryController, 'Industry', Icons.category_rounded),
                      const SizedBox(height: 12),
                      _buildTextField(_descriptionController, 'Description', Icons.description_rounded, maxLines: 3),
                      const SizedBox(height: 12),
                      _buildTextField(_yearsController, 'Years in Business', Icons.calendar_today_rounded, keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildTextField(_websiteController, 'Website (Optional)', Icons.language_rounded, keyboardType: TextInputType.url),
                      const SizedBox(height: 12),
                      
                      // Services
                      Text('Services Offered', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _buildTagInput(
                        controller: _serviceController,
                        tags: _servicesOffered,
                        hint: 'Add service',
                        onAdd: () {
                          if (_serviceController.text.trim().isNotEmpty) {
                            setState(() {
                              _servicesOffered.add(_serviceController.text.trim());
                              _serviceController.clear();
                            });
                          }
                        },
                        onRemove: (index) => setState(() => _servicesOffered.removeAt(index)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006A4E), padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF006A4E)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF006A4E), width: 2)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown<T>({required T? value, required String hint, required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged}) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(Icons.business_rounded, color: const Color(0xFF006A4E)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF006A4E), width: 2)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items,
      onChanged: onChanged,
      validator: (value) => value == null ? 'Required' : null,
    );
  }

  Widget _buildTagInput({required TextEditingController controller, required List<String> tags, required String hint, required VoidCallback onAdd, required Function(int) onRemove}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: TextField(controller: controller, decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onSubmitted: (_) => onAdd())),
            const SizedBox(width: 8),
            IconButton(onPressed: onAdd, icon: const Icon(Icons.add, color: Color(0xFF006A4E)), style: IconButton.styleFrom(backgroundColor: Colors.green[50])),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: tags.asMap().entries.map((entry) => Chip(label: Text(entry.value), onDeleted: () => onRemove(entry.key))).toList()),
        ],
      ],
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusinessType == null) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select location on map')));
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null) return;

    final updatedPartner = widget.partner.copyWith(
      businessName: _businessNameController.text,
      ownerName: _ownerNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      state: _selectedState ?? '',
      city: _cityController.text,
      businessType: _selectedBusinessType!,
      industry: _industryController.text,
      description: _descriptionController.text,
      yearsInBusiness: int.tryParse(_yearsController.text) ?? 0,
      servicesOffered: _servicesOffered,
      website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
      socialMediaLinks: _socialMediaLinks.isNotEmpty ? _socialMediaLinks : null,
      latitude: _latitude,
      longitude: _longitude,
      updatedAt: DateTime.now(),
    );

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    final success = await provider.updateBusinessPartner(widget.partner.id!, updatedPartner);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      widget.onUpdate();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business partner updated successfully'), backgroundColor: Color(0xFF006A4E)));
    }
  }
}