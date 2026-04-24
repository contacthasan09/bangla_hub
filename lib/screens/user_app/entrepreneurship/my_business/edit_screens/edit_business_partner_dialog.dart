import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:bangla_hub/providers/auth_provider.dart';

class EditPartnerRequestDialog extends StatefulWidget {
  final BusinessPartnerRequest request;
  final VoidCallback onUpdate;

  const EditPartnerRequestDialog({
    Key? key,
    required this.request,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EditPartnerRequestDialog> createState() => _EditPartnerRequestDialogState();
}

class _EditPartnerRequestDialogState extends State<EditPartnerRequestDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _budgetMinController;
  late TextEditingController _budgetMaxController;
  late PartnerType _selectedPartnerType;
  late BusinessType _selectedBusinessType;
  late TextEditingController _industryController;
  late TextEditingController _locationController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactEmailController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _skillsController;
  late TextEditingController _responsibilitiesController;
  
  List<String> _skillsRequired = [];
  List<String> _responsibilities = [];
  bool _isUrgent = false;
  bool _isLoading = false;
  
  // Location coordinates (added for map)
  double? _latitude;
  double? _longitude;
  bool _isLocationSelected = false;

  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _goldAccent = const Color(0xFFFFD700);
  final Color _lightGreen = const Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.request.title);
    _descriptionController = TextEditingController(text: widget.request.description);
    _budgetMinController = TextEditingController(text: widget.request.budgetMin.toString());
    _budgetMaxController = TextEditingController(text: widget.request.budgetMax.toString());
    _selectedPartnerType = widget.request.partnerType;
    _selectedBusinessType = widget.request.businessType;
    _industryController = TextEditingController(text: widget.request.industry);
    _locationController = TextEditingController(text: widget.request.location);
    _cityController = TextEditingController(text: widget.request.city);
    _stateController = TextEditingController(text: widget.request.state);
    _contactNameController = TextEditingController(text: widget.request.contactName);
    _contactEmailController = TextEditingController(text: widget.request.contactEmail);
    _contactPhoneController = TextEditingController(text: widget.request.contactPhone);
    _skillsController = TextEditingController();
    _responsibilitiesController = TextEditingController();
    
    _skillsRequired = List.from(widget.request.skillsRequired);
    _responsibilities = List.from(widget.request.responsibilities);
    _isUrgent = widget.request.isUrgent;
    
    // Initialize location from existing data
    _latitude = widget.request.latitude;
    _longitude = widget.request.longitude;
    _isLocationSelected = _latitude != null && _longitude != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _industryController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _skillsController.dispose();
    _responsibilitiesController.dispose();
    super.dispose();
  }

  // Location picker widget (added)
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
            initialAddress: _locationController.text,
            initialState: _stateController.text,
            initialCity: _cityController.text,
            onLocationSelected: (lat, lng, address, state, city) {
              setState(() {
                _latitude = lat;
                _longitude = lng;
                _isLocationSelected = true;
                _locationController.text = address;
                if (city != null && city.isNotEmpty) _cityController.text = city;
                if (state != null && state.isNotEmpty) _stateController.text = state;
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
          color: _isLocationSelected ? _lightGreen : null,
        ),
        child: Row(
          children: [
            Icon(Icons.map_rounded, color: _primaryGreen, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location *',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _locationController.text.isEmpty 
                        ? 'Tap to select location on map' 
                        : _locationController.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _locationController.text.isEmpty ? Colors.grey[500] : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Validate location is selected
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final updatedRequest = widget.request.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      budgetMin: double.tryParse(_budgetMinController.text) ?? widget.request.budgetMin,
      budgetMax: double.tryParse(_budgetMaxController.text) ?? widget.request.budgetMax,
      partnerType: _selectedPartnerType,
      businessType: _selectedBusinessType,
      industry: _industryController.text,
      location: _locationController.text,
      city: _cityController.text,
      state: _stateController.text,
      contactName: _contactNameController.text,
      contactEmail: _contactEmailController.text,
      contactPhone: _contactPhoneController.text,
      skillsRequired: _skillsRequired,
      responsibilities: _responsibilities,
      isUrgent: _isUrgent,
      latitude: _latitude,
      longitude: _longitude,
      updatedAt: DateTime.now(),
    );

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    final success = await provider.updatePartnerRequest(widget.request.id!, updatedRequest);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      widget.onUpdate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Partner request updated successfully'),
          backgroundColor: Color(0xFF006A4E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update partner request'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                gradient: LinearGradient(colors: [_primaryGreen, const Color(0xFF004D38)]),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.edit_rounded, color: _goldAccent, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Edit Partner Request',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTextField(_titleController, 'Title *', Icons.title_rounded),
                    const SizedBox(height: 12),
                    _buildTextField(_descriptionController, 'Description *', Icons.description_rounded, maxLines: 3),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_budgetMinController, 'Min Budget *', Icons.attach_money_rounded, keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_budgetMaxController, 'Max Budget *', Icons.attach_money_rounded, keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown<PartnerType>(
                      value: _selectedPartnerType,
                      hint: 'Partner Type *',
                      items: PartnerType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedPartnerType = value!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown<BusinessType>(
                      value: _selectedBusinessType,
                      hint: 'Business Type *',
                      items: BusinessType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedBusinessType = value!),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(_industryController, 'Industry *', Icons.category_rounded),
                    const SizedBox(height: 12),
                    
                    // Location Picker Field (replaces text fields)
                    _buildLocationPickerField(),
                    const SizedBox(height: 12),
                    
                    // City and State are now handled by the location picker
                    // But keep them as read-only or hidden
                    if (_cityController.text.isNotEmpty || _stateController.text.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _lightGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_city_rounded, size: 16, color: _primaryGreen),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_cityController.text}, ${_stateController.text}',
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    
                    _buildTextField(_contactNameController, 'Contact Name *', Icons.person_rounded),
                    const SizedBox(height: 12),
                    _buildTextField(_contactEmailController, 'Contact Email *', Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _buildTextField(_contactPhoneController, 'Contact Phone *', Icons.phone_rounded, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    
                    // Skills Required
                    Text('Skills Required', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _primaryGreen)),
                    const SizedBox(height: 8),
                    _buildTagInput(
                      controller: _skillsController,
                      tags: _skillsRequired,
                      hint: 'Add skill',
                      onAdd: () {
                        if (_skillsController.text.trim().isNotEmpty) {
                          setState(() {
                            _skillsRequired.add(_skillsController.text.trim());
                            _skillsController.clear();
                          });
                        }
                      },
                      onRemove: (index) => setState(() => _skillsRequired.removeAt(index)),
                    ),
                    const SizedBox(height: 16),
                    
                    // Responsibilities
                    Text('Responsibilities', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _primaryGreen)),
                    const SizedBox(height: 8),
                    _buildTagInput(
                      controller: _responsibilitiesController,
                      tags: _responsibilities,
                      hint: 'Add responsibility',
                      onAdd: () {
                        if (_responsibilitiesController.text.trim().isNotEmpty) {
                          setState(() {
                            _responsibilities.add(_responsibilitiesController.text.trim());
                            _responsibilitiesController.clear();
                          });
                        }
                      },
                      onRemove: (index) => setState(() => _responsibilities.removeAt(index)),
                    ),
                    const SizedBox(height: 16),
                    
                    // Urgent
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isUrgent ? Colors.red[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isUrgent ? Colors.red : Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _isUrgent,
                            onChanged: (value) => setState(() => _isUrgent = value ?? false),
                            activeColor: Colors.red,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mark as Urgent',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: _isUrgent ? Colors.red : Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Urgent requests will be highlighted',
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: _primaryGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryGreen, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 14),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        prefixIcon: Icon(Icons.business_rounded, color: _primaryGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryGreen, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items,
      onChanged: onChanged,
      validator: (value) => value == null ? 'Required' : null,
    );
  }

  Widget _buildTagInput({
    required TextEditingController controller,
    required List<String> tags,
    required String hint,
    required VoidCallback onAdd,
    required Function(int) onRemove,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAdd,
              icon: Icon(Icons.add, color: _primaryGreen, size: 22),
              style: IconButton.styleFrom(
                backgroundColor: _primaryGreen.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  color: _primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.value,
                      style: GoogleFonts.inter(fontSize: 12, color: _primaryGreen),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onRemove(entry.key),
                      child: Icon(Icons.close_rounded, size: 14, color: _primaryGreen),
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
}