// lib/screens/user_app/entrepreneurship/small_business_promotion/edit_business_promotion_dialog.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';

class EditBusinessPromotionDialog extends StatefulWidget {
  final SmallBusinessPromotion promotion;
  final VoidCallback onUpdate;

  const EditBusinessPromotionDialog({
    Key? key,
    required this.promotion,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EditBusinessPromotionDialog> createState() => _EditBusinessPromotionDialogState();
}

class _EditBusinessPromotionDialogState extends State<EditBusinessPromotionDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _businessNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _contactEmailController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _websiteController;
  late TextEditingController _socialMediaController;
  late TextEditingController _productController;
  late TextEditingController _offerDiscountController;
  late TextEditingController _offerValidityController;
  late TextEditingController _paymentMethodController;
  
  // Location variables
  double? _businessLatitude;
  double? _businessLongitude;
  String? _businessFullAddress;
  String? _businessCity;
  String? _businessState;
  
  List<String> _productsServices = [];
  List<String> _paymentMethods = [];
  
  bool _isLoading = false;

  final Color _primaryOrange = const Color(0xFFFF9800);
  final Color _redAccent = const Color(0xFFE53935);
  final Color _greenAccent = const Color(0xFF43A047);
  final Color _goldAccent = const Color(0xFFFFB300);
  final Color _lightOrange = const Color(0xFFFFF3E0);

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.promotion.businessName);
    _ownerNameController = TextEditingController(text: widget.promotion.ownerName);
    _descriptionController = TextEditingController(text: widget.promotion.description);
    _contactEmailController = TextEditingController(text: widget.promotion.contactEmail);
    _contactPhoneController = TextEditingController(text: widget.promotion.contactPhone);
    _websiteController = TextEditingController(text: widget.promotion.website ?? '');
    _socialMediaController = TextEditingController(text: widget.promotion.socialMediaLinks ?? '');
    _productController = TextEditingController();
    _offerDiscountController = TextEditingController(text: widget.promotion.specialOfferDiscount?.toString() ?? '');
    _offerValidityController = TextEditingController(text: widget.promotion.offerValidity ?? '');
    _paymentMethodController = TextEditingController();
    
    _productsServices = List.from(widget.promotion.productsServices);
    _paymentMethods = List.from(widget.promotion.paymentMethods);
    _businessLatitude = widget.promotion.latitude;
    _businessLongitude = widget.promotion.longitude;
    _businessFullAddress = widget.promotion.location;
    _businessCity = widget.promotion.city;
    _businessState = widget.promotion.state;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _descriptionController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _websiteController.dispose();
    _socialMediaController.dispose();
    _productController.dispose();
    _offerDiscountController.dispose();
    _offerValidityController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  Widget _buildLocationPickerField() {
    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => OSMLocationPicker(
            initialLatitude: _businessLatitude,
            initialLongitude: _businessLongitude,
            initialAddress: _businessFullAddress,
            initialState: _businessState,
            initialCity: _businessCity,
            onLocationSelected: (lat, lng, address, state, city) {
              setState(() {
                _businessLatitude = lat;
                _businessLongitude = lng;
                _businessFullAddress = address;
                _businessState = state;
                _businessCity = city;
              });
            },
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: _businessLatitude != null ? _lightOrange : null,
        ),
        child: Row(
          children: [
            Icon(Icons.map_rounded, color: _primaryOrange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Business Location *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryOrange)),
                  Text(_businessFullAddress ?? 'Tap to select location', style: GoogleFonts.inter(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
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
        width: isTablet ? 700 : double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_primaryOrange, _redAccent, _greenAccent]),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.edit_rounded, color: _goldAccent, size: 24)),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Edit Business Promotion', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: Colors.white)),
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
                      _buildTextField(_businessNameController, 'Business Name *', Icons.storefront_rounded),
                      const SizedBox(height: 12),
                      _buildTextField(_ownerNameController, 'Owner Name *', Icons.person_rounded),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_contactEmailController, 'Email *', Icons.email_rounded, keyboardType: TextInputType.emailAddress)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_contactPhoneController, 'Enter a valid US number *', Icons.phone_rounded, keyboardType: TextInputType.phone)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLocationPickerField(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildReadOnlyField(_businessCity ?? 'Not set', Icons.location_city_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildReadOnlyField(_businessState ?? 'Not set', Icons.map_rounded)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_descriptionController, 'Description *', Icons.description_rounded, maxLines: 4),
                      const SizedBox(height: 16),
                      
                      // Products & Services
                      Text('Products & Services *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _primaryOrange)),
                      const SizedBox(height: 8),
                      _buildTagInput(
                        controller: _productController,
                        tags: _productsServices,
                        hint: 'Add product or service',
                        onAdd: () {
                          if (_productController.text.trim().isNotEmpty) {
                            setState(() { _productsServices.add(_productController.text.trim()); _productController.clear(); });
                          }
                        },
                        onRemove: (index) => setState(() => _productsServices.removeAt(index)),
                      ),
                      const SizedBox(height: 16),
                      
                      // Payment Methods
                      Text('Payment Methods', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _greenAccent)),
                      const SizedBox(height: 8),
                      _buildTagInput(
                        controller: _paymentMethodController,
                        tags: _paymentMethods,
                        hint: 'Add payment method',
                        onAdd: () {
                          if (_paymentMethodController.text.trim().isNotEmpty) {
                            setState(() { _paymentMethods.add(_paymentMethodController.text.trim()); _paymentMethodController.clear(); });
                          }
                        },
                        onRemove: (index) => setState(() => _paymentMethods.removeAt(index)),
                      ),
                      const SizedBox(height: 16),
                      
                      // Special Offer
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(color: _goldAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: _goldAccent.withOpacity(0.3))),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildTextField(_offerDiscountController, 'Discount %', Icons.percent_rounded, keyboardType: TextInputType.number, isRequired: false)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildTextField(_offerValidityController, 'Valid Until', Icons.calendar_today_rounded, isRequired: false)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Website & Social Media
                      _buildTextField(_websiteController, 'Website', Icons.language_rounded, isRequired: false),
                      const SizedBox(height: 12),
                      _buildTextField(_socialMediaController, 'Social Media Link', Icons.link_rounded, isRequired: false),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _greenAccent,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // Editable TextField with controller
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, int maxLines = 1, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryOrange),
        prefixIcon: Icon(icon, color: _primaryOrange),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryOrange, width: 2)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 12),
      ),
      validator: isRequired ? (value) => value == null || value.isEmpty ? 'Required' : null : null,
    );
  }

  // Read-only field for displaying values (City and State)
  Widget _buildReadOnlyField(String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Icon(icon, color: _primaryOrange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ),
          Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildTagInput({required TextEditingController controller, required List<String> tags, required String hint, required VoidCallback onAdd, required Function(int) onRemove}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryOrange, width: 2)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_primaryOrange, _redAccent]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: onAdd,
                icon: Icon(Icons.add_rounded, color: Colors.white, size: 22),
                padding: EdgeInsets.all(10),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.asMap().entries.map((entry) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _lightOrange,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primaryOrange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.value, style: GoogleFonts.inter(fontSize: 12, color: _primaryOrange, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onRemove(entry.key),
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded, size: 14, color: _redAccent),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_businessLatitude == null || _businessLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a location on the map')));
      return;
    }
    if (_productsServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one product or service')));
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null) return;

    final updatedPromotion = widget.promotion.copyWith(
      businessName: _businessNameController.text,
      ownerName: _ownerNameController.text,
      description: _descriptionController.text,
      location: _businessFullAddress!,
      state: _businessState ?? '',
      city: _businessCity ?? '',
      contactEmail: _contactEmailController.text,
      contactPhone: _contactPhoneController.text,
      website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
      socialMediaLinks: _socialMediaController.text.isNotEmpty ? _socialMediaController.text : null,
      productsServices: _productsServices,
      paymentMethods: _paymentMethods,
      specialOfferDiscount: _offerDiscountController.text.isNotEmpty ? double.tryParse(_offerDiscountController.text) : null,
      offerValidity: _offerValidityController.text.isNotEmpty ? _offerValidityController.text : null,
      latitude: _businessLatitude,
      longitude: _businessLongitude,
      updatedAt: DateTime.now(),
    );

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    final success = await provider.updateBusinessPromotion(widget.promotion.id!, updatedPromotion);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      widget.onUpdate();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business promotion updated successfully'), backgroundColor: Color(0xFFFF9800)));
    }
  }
}