// lib/screens/user_app/education_youth/tutoring/edit_tutoring_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/models/education_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/education_provider.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';

class EditTutoringDialog extends StatefulWidget {
  final TutoringService service;
  final VoidCallback onUpdate;

  const EditTutoringDialog({
    Key? key,
    required this.service,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EditTutoringDialog> createState() => _EditTutoringDialogState();
}

class _EditTutoringDialogState extends State<EditTutoringDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _tutorNameController;
  late TextEditingController _organizationController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _descriptionController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _experienceController;
  late TextEditingController _qualificationsController;
  late TextEditingController _availableDaysController;
  late TextEditingController _availableTimesController;

  // Location
  double? _latitude;
  double? _longitude;
  String? _fullAddress;
  String? _selectedState;

  List<TutoringSubject> _selectedSubjects = [];
  List<EducationLevel> _selectedLevels = [];
  List<TeachingMethod> _selectedMethods = [];

  bool _isLoading = false;

  final Color _primaryBlue = const Color(0xFF2196F3);
  final Color _successGreen = const Color(0xFF4CAF50);
  final Color _tealAccent = const Color(0xFF00897B);
  final Color _purpleAccent = const Color(0xFF9B59B6);
  final Color _textPrimary = const Color(0xFF1A2B3C);

  @override
  void initState() {
    super.initState();
    _tutorNameController = TextEditingController(text: widget.service.tutorName);
    _organizationController = TextEditingController(text: widget.service.organizationName ?? '');
    _emailController = TextEditingController(text: widget.service.email);
    _phoneController = TextEditingController(text: widget.service.phone);
    _addressController = TextEditingController(text: widget.service.address);
    _cityController = TextEditingController(text: widget.service.city);
    _descriptionController = TextEditingController(text: widget.service.description);
    _hourlyRateController = TextEditingController(text: widget.service.hourlyRate.toString());
    _experienceController = TextEditingController(text: widget.service.experience ?? '');
    _qualificationsController = TextEditingController(text: widget.service.qualifications ?? '');
    _availableDaysController = TextEditingController(text: widget.service.availableDays.join(', '));
    _availableTimesController = TextEditingController(text: widget.service.availableTimes.join(', '));
    
    _selectedSubjects = List.from(widget.service.subjects);
    _selectedLevels = List.from(widget.service.levels);
    _selectedMethods = List.from(widget.service.teachingMethods);
    _latitude = widget.service.latitude;
    _longitude = widget.service.longitude;
    _fullAddress = widget.service.address;
    _selectedState = widget.service.state;
  }

  @override
  void dispose() {
    _tutorNameController.dispose();
    _organizationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    _experienceController.dispose();
    _qualificationsController.dispose();
    _availableDaysController.dispose();
    _availableTimesController.dispose();
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
          color: _latitude != null ? Colors.blue.shade50 : null,
        ),
        child: Row(
          children: [
            Icon(Icons.map_rounded, color: _primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryBlue)),
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
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_primaryBlue, _purpleAccent]),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.edit_rounded, color: Colors.white, size: 24)),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Edit Tutoring Service', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
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
                      _buildTextField(_tutorNameController, 'Tutor Name *', Icons.person_rounded),
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
                      
                      // Subjects
                      Text('Subjects *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _primaryBlue)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: TutoringSubject.values.map((subject) {
                            final isSelected = _selectedSubjects.contains(subject);
                            return CheckboxListTile(
                              title: Text(subject.displayName, style: GoogleFonts.inter(fontSize: 13)),
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) _selectedSubjects.add(subject);
                                  else _selectedSubjects.remove(subject);
                                });
                              },
                              activeColor: _primaryBlue,
                              dense: true,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Education Levels
                      Text('Education Levels *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _successGreen)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: EducationLevel.values.map((level) {
                            final isSelected = _selectedLevels.contains(level);
                            return CheckboxListTile(
                              title: Text(level.displayName, style: GoogleFonts.inter(fontSize: 13)),
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) _selectedLevels.add(level);
                                  else _selectedLevels.remove(level);
                                });
                              },
                              activeColor: _successGreen,
                              dense: true,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Teaching Methods
                      Text('Teaching Methods *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _tealAccent)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: TeachingMethod.values.map((method) {
                            final isSelected = _selectedMethods.contains(method);
                            return CheckboxListTile(
                              title: Text(method.displayName, style: GoogleFonts.inter(fontSize: 13)),
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) _selectedMethods.add(method);
                                  else _selectedMethods.remove(method);
                                });
                              },
                              activeColor: _tealAccent,
                              dense: true,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildTextField(_descriptionController, 'Description *', Icons.description_rounded, maxLines: 3),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_hourlyRateController, 'Hourly Rate (\$) *', Icons.attach_money_rounded, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_experienceController, 'Experience', Icons.work_history_rounded, isRequired: false)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_qualificationsController, 'Qualifications', Icons.school_rounded, isRequired: false),
                      const SizedBox(height: 12),
                      _buildTextField(_availableDaysController, 'Available Days (comma separated)', Icons.calendar_today_rounded, isRequired: false),
                      const SizedBox(height: 12),
                      _buildTextField(_availableTimesController, 'Available Times (comma separated)', Icons.schedule_rounded, isRequired: false),
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
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _saveChanges, style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes'))),
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
        prefixIcon: Icon(icon, color: _primaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryBlue, width: 2)),
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
          Icon(icon, color: _primaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87))),
          Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a location on the map')));
      return;
    }

    setState(() => _isLoading = true);

    final rate = double.tryParse(_hourlyRateController.text) ?? 0;
    
    final updatedService = widget.service.copyWith(
      tutorName: _tutorNameController.text,
      organizationName: _organizationController.text.isNotEmpty ? _organizationController.text : null,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _fullAddress ?? _addressController.text,
      state: _selectedState ?? '',
      city: _cityController.text,
      subjects: _selectedSubjects,
      levels: _selectedLevels,
      teachingMethods: _selectedMethods,
      description: _descriptionController.text,
      hourlyRate: rate,
      experience: _experienceController.text.isNotEmpty ? _experienceController.text : null,
      qualifications: _qualificationsController.text.isNotEmpty ? _qualificationsController.text : null,
      availableDays: _availableDaysController.text.isNotEmpty ? _availableDaysController.text.split(',').map((d) => d.trim()).toList() : [],
      availableTimes: _availableTimesController.text.isNotEmpty ? _availableTimesController.text.split(',').map((t) => t.trim()).toList() : [],
      latitude: _latitude,
      longitude: _longitude,
      updatedAt: DateTime.now(),
    );

    final provider = Provider.of<EducationProvider>(context, listen: false);
    final success = await provider.updateTutoringService(widget.service.id!, updatedService);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      widget.onUpdate();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tutoring service updated successfully'), backgroundColor: Color(0xFF2196F3)));
    }
  }
}