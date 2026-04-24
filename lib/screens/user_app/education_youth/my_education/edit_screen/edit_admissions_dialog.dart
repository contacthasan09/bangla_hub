// lib/screens/user_app/education_youth/admissions/edit_admissions_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/models/education_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/education_provider.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';

class EditAdmissionsDialog extends StatefulWidget {
  final AdmissionsGuidance guidance;
  final VoidCallback onUpdate;

  const EditAdmissionsDialog({
    Key? key,
    required this.guidance,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EditAdmissionsDialog> createState() => _EditAdmissionsDialogState();
}

class _EditAdmissionsDialogState extends State<EditAdmissionsDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _consultantNameController;
  late TextEditingController _organizationController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _descriptionController;
  late TextEditingController _consultationFeeController;
  late TextEditingController _experienceController;
  late TextEditingController _qualificationsController;
  late TextEditingController _specializationController;
  late TextEditingController _countryController;
  late TextEditingController _serviceController;

  // Location
  double? _latitude;
  double? _longitude;
  String? _fullAddress;
  String? _selectedState;

  List<String> _specializations = [];
  List<String> _countries = [];
  List<String> _servicesOffered = [];

  bool _isLoading = false;

  final Color _primaryGreen = const Color(0xFF4CAF50);
  final Color _infoBlue = const Color(0xFF2196F3);
  final Color _purpleAccent = const Color(0xFF9B59B6);

  @override
  void initState() {
    super.initState();
    _consultantNameController = TextEditingController(text: widget.guidance.consultantName);
    _organizationController = TextEditingController(text: widget.guidance.organizationName ?? '');
    _emailController = TextEditingController(text: widget.guidance.email);
    _phoneController = TextEditingController(text: widget.guidance.phone);
    _addressController = TextEditingController(text: widget.guidance.address);
    _cityController = TextEditingController(text: widget.guidance.city);
    _descriptionController = TextEditingController(text: widget.guidance.description);
    _consultationFeeController = TextEditingController(text: widget.guidance.consultationFee.toString());
    _experienceController = TextEditingController(text: widget.guidance.experience ?? '');
    _qualificationsController = TextEditingController(text: widget.guidance.qualifications ?? '');
    _specializationController = TextEditingController();
    _countryController = TextEditingController();
    _serviceController = TextEditingController();
    
    _specializations = List.from(widget.guidance.specializations);
    _countries = List.from(widget.guidance.countries);
    _servicesOffered = List.from(widget.guidance.servicesOffered);
    _latitude = widget.guidance.latitude;
    _longitude = widget.guidance.longitude;
    _fullAddress = widget.guidance.address;
    _selectedState = widget.guidance.state;
  }

  @override
  void dispose() {
    _consultantNameController.dispose();
    _organizationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _consultationFeeController.dispose();
    _experienceController.dispose();
    _qualificationsController.dispose();
    _specializationController.dispose();
    _countryController.dispose();
    _serviceController.dispose();
    super.dispose();
  }

  Widget _buildLocationPickerField() {
    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => GoogleMapsLocationPicker(
            initialLatitude: _latitude,
            initialLongitude: _longitude,
            initialAddress: _fullAddress,
            initialState: _selectedState,
            initialCity: _cityController.text,
            onLocationSelected: (lat, lng, address, state, city) {
              setState(() {
                _latitude = lat;
                _longitude = lng;
                _fullAddress = address;
                _selectedState = state;
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
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: _latitude != null ? Colors.green.shade50 : null,
        ),
        child: Row(
          children: [
            Icon(Icons.map_rounded, color: _primaryGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryGreen)),
                  Text(_fullAddress ?? 'Tap to select location', style: GoogleFonts.inter(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
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
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryGreen, _purpleAccent]), borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
              child: Row(
                children: [
                  Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.edit_rounded, color: Colors.white, size: 24)),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Edit Admissions Guidance', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(_consultantNameController, 'Consultant Name *', Icons.person_rounded),
                      const SizedBox(height: 12),
                      _buildTextField(_organizationController, 'Organization', Icons.business_rounded, isRequired: false),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_emailController, 'Email *', Icons.email_rounded, keyboardType: TextInputType.emailAddress)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_phoneController, 'Enter a valid US number *', Icons.phone_rounded, keyboardType: TextInputType.phone)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLocationPickerField(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildReadOnlyField(_cityController.text.isEmpty ? 'Not set' : _cityController.text, Icons.location_city_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildReadOnlyField(_selectedState ?? 'Not set', Icons.map_rounded)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_descriptionController, 'Description *', Icons.description_rounded, maxLines: 3),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_consultationFeeController, 'Consultation Fee (\$) *', Icons.attach_money_rounded, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_experienceController, 'Experience', Icons.work_history_rounded, isRequired: false)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_qualificationsController, 'Qualifications', Icons.school_rounded, isRequired: false),
                      const SizedBox(height: 16),
                      
                      // Specializations
                      Text('Specializations *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _primaryGreen)),
                      const SizedBox(height: 8),
                      _buildTagInput(_specializationController, _specializations, 'Add specialization', () {
                        if (_specializationController.text.trim().isNotEmpty) {
                          setState(() { _specializations.add(_specializationController.text.trim()); _specializationController.clear(); });
                        }
                      }, (index) => setState(() => _specializations.removeAt(index))),
                      const SizedBox(height: 16),
                      
                      // Countries
                      Text('Countries Served *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _infoBlue)),
                      const SizedBox(height: 8),
                      _buildTagInput(_countryController, _countries, 'Add country', () {
                        if (_countryController.text.trim().isNotEmpty) {
                          setState(() { _countries.add(_countryController.text.trim()); _countryController.clear(); });
                        }
                      }, (index) => setState(() => _countries.removeAt(index))),
                      const SizedBox(height: 16),
                      
                      // Services Offered
                      Text('Services Offered', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _purpleAccent)),
                      const SizedBox(height: 8),
                      _buildTagInput(_serviceController, _servicesOffered, 'Add service', () {
                        if (_serviceController.text.trim().isNotEmpty) {
                          setState(() { _servicesOffered.add(_serviceController.text.trim()); _serviceController.clear(); });
                        }
                      }, (index) => setState(() => _servicesOffered.removeAt(index))),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
              child: Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _saveChanges, style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen, padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes'))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, int maxLines = 1, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryGreen, width: 2)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: isRequired ? (value) => value == null || value.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _buildReadOnlyField(String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12), color: Colors.grey.shade50),
      child: Row(
        children: [
          Icon(icon, color: _primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87))),
          Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildTagInput(TextEditingController controller, List<String> tags, String hint, VoidCallback onAdd, Function(int) onRemove) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: TextField(controller: controller, decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onSubmitted: (_) => onAdd())),
            const SizedBox(width: 8),
            IconButton(onPressed: onAdd, icon: Icon(Icons.add, color: _primaryGreen), style: IconButton.styleFrom(backgroundColor: Colors.green.shade50)),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: tags.asMap().entries.map((entry) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: _primaryGreen.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(entry.value, style: GoogleFonts.inter(fontSize: 12)),
                const SizedBox(width: 4),
                GestureDetector(onTap: () => onRemove(entry.key), child: Icon(Icons.close_rounded, size: 14, color: Colors.red)),
              ]),
            );
          }).toList()),
        ],
      ],
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a location on the map')));
      return;
    }
    if (_specializations.isEmpty || _countries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one specialization and country')));
      return;
    }

    setState(() => _isLoading = true);

    final fee = double.tryParse(_consultationFeeController.text) ?? 0;
    
    final updatedGuidance = widget.guidance.copyWith(
      consultantName: _consultantNameController.text,
      organizationName: _organizationController.text.isNotEmpty ? _organizationController.text : null,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _fullAddress ?? _addressController.text,
      state: _selectedState ?? '',
      city: _cityController.text,
      specializations: _specializations,
      countries: _countries,
      description: _descriptionController.text,
      consultationFee: fee,
      experience: _experienceController.text.isNotEmpty ? _experienceController.text : null,
      qualifications: _qualificationsController.text.isNotEmpty ? _qualificationsController.text : null,
      servicesOffered: _servicesOffered,
      latitude: _latitude,
      longitude: _longitude,
      updatedAt: DateTime.now(),
    );

    final provider = Provider.of<EducationProvider>(context, listen: false);
    final success = await provider.updateAdmissionsGuidance(widget.guidance.id!, updatedGuidance);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      widget.onUpdate();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admissions guidance updated successfully'), backgroundColor: Color(0xFF4CAF50)));
    }
  }
}