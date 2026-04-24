// lib/screens/user_app/education_youth/bangla_class/edit_bangla_class_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/models/education_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/education_provider.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';

class EditBanglaClassDialog extends StatefulWidget {
  final BanglaClass banglaClass;
  final VoidCallback onUpdate;

  const EditBanglaClassDialog({
    Key? key,
    required this.banglaClass,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EditBanglaClassDialog> createState() => _EditBanglaClassDialogState();
}

class _EditBanglaClassDialogState extends State<EditBanglaClassDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _instructorNameController;
  late TextEditingController _organizationController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _descriptionController;
  late TextEditingController _classFeeController;
  late TextEditingController _scheduleController;
  late TextEditingController _classDurationController;
  late TextEditingController _maxStudentsController;
  late TextEditingController _qualificationsController;
  late TextEditingController _classTypeController;
  late TextEditingController _culturalActivityController;

  // Location
  double? _latitude;
  double? _longitude;
  String? _fullAddress;
  String? _selectedState;

  List<String> _classTypes = [];
  List<TeachingMethod> _selectedMethods = [];
  List<String> _culturalActivities = [];

  bool _isLoading = false;

  final Color _primaryOrange = const Color(0xFFFF9800);
  final Color _redAccent = const Color(0xFFE53935);
  final Color _greenAccent = const Color(0xFF43A047);
  final Color _goldAccent = const Color(0xFFFFB300);

  @override
  void initState() {
    super.initState();
    _instructorNameController = TextEditingController(text: widget.banglaClass.instructorName);
    _organizationController = TextEditingController(text: widget.banglaClass.organizationName ?? '');
    _emailController = TextEditingController(text: widget.banglaClass.email);
    _phoneController = TextEditingController(text: widget.banglaClass.phone);
    _addressController = TextEditingController(text: widget.banglaClass.address);
    _cityController = TextEditingController(text: widget.banglaClass.city);
    _descriptionController = TextEditingController(text: widget.banglaClass.description);
    _classFeeController = TextEditingController(text: widget.banglaClass.classFee.toString());
    _scheduleController = TextEditingController(text: widget.banglaClass.schedule ?? '');
    _classDurationController = TextEditingController(text: widget.banglaClass.classDuration.toString());
    _maxStudentsController = TextEditingController(text: widget.banglaClass.maxStudents.toString());
    _qualificationsController = TextEditingController(text: widget.banglaClass.qualifications ?? '');
    _classTypeController = TextEditingController();
    _culturalActivityController = TextEditingController();
    
    _classTypes = List.from(widget.banglaClass.classTypes);
    _selectedMethods = List.from(widget.banglaClass.teachingMethods);
    _culturalActivities = List.from(widget.banglaClass.culturalActivities);
    _latitude = widget.banglaClass.latitude;
    _longitude = widget.banglaClass.longitude;
    _fullAddress = widget.banglaClass.address;
    _selectedState = widget.banglaClass.state;
  }

  @override
  void dispose() {
    _instructorNameController.dispose();
    _organizationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _classFeeController.dispose();
    _scheduleController.dispose();
    _classDurationController.dispose();
    _maxStudentsController.dispose();
    _qualificationsController.dispose();
    _classTypeController.dispose();
    _culturalActivityController.dispose();
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
          color: _latitude != null ? Colors.orange.shade50 : null,
        ),
        child: Row(
          children: [
            Icon(Icons.map_rounded, color: _primaryOrange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryOrange)),
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
              decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryOrange, _redAccent]), borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
              child: Row(
                children: [
                  Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.edit_rounded, color: Colors.white, size: 24)),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Edit Bangla Class', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
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
                      _buildTextField(_instructorNameController, 'Instructor Name *', Icons.person_rounded),
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
                          Expanded(child: _buildTextField(_classFeeController, 'Class Fee (\$) *', Icons.attach_money_rounded, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_classDurationController, 'Duration (min) *', Icons.schedule_rounded, keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_maxStudentsController, 'Max Students *', Icons.people_rounded, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_scheduleController, 'Schedule', Icons.calendar_today_rounded, isRequired: false)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_qualificationsController, 'Qualifications', Icons.school_rounded, isRequired: false),
                      const SizedBox(height: 16),
                      
                      // Class Types
                      Text('Class Types *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _primaryOrange)),
                      const SizedBox(height: 8),
                      _buildTagInput(_classTypeController, _classTypes, 'Add class type', () {
                        if (_classTypeController.text.trim().isNotEmpty) {
                          setState(() { _classTypes.add(_classTypeController.text.trim()); _classTypeController.clear(); });
                        }
                      }, (index) => setState(() => _classTypes.removeAt(index))),
                      const SizedBox(height: 16),
                      
                      // Teaching Methods
                      Text('Teaching Methods *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _greenAccent)),
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
                              activeColor: _greenAccent,
                              dense: true,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Cultural Activities
                      Text('Cultural Activities', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _goldAccent)),
                      const SizedBox(height: 8),
                      _buildTagInput(_culturalActivityController, _culturalActivities, 'Add cultural activity', () {
                        if (_culturalActivityController.text.trim().isNotEmpty) {
                          setState(() { _culturalActivities.add(_culturalActivityController.text.trim()); _culturalActivityController.clear(); });
                        }
                      }, (index) => setState(() => _culturalActivities.removeAt(index))),
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
                  Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _saveChanges, style: ElevatedButton.styleFrom(backgroundColor: _greenAccent, padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes'))),
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
        prefixIcon: Icon(icon, color: _primaryOrange),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryOrange, width: 2)),
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
          Icon(icon, color: _primaryOrange, size: 20),
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
            IconButton(onPressed: onAdd, icon: Icon(Icons.add, color: _primaryOrange), style: IconButton.styleFrom(backgroundColor: Colors.orange.shade50)),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: tags.asMap().entries.map((entry) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: _primaryOrange.withOpacity(0.3))),
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
    if (_classTypes.isEmpty || _selectedMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one class type and teaching method')));
      return;
    }

    setState(() => _isLoading = true);

    final fee = double.tryParse(_classFeeController.text) ?? 0;
    final duration = int.tryParse(_classDurationController.text) ?? 60;
    final maxStudents = int.tryParse(_maxStudentsController.text) ?? 10;
    
    final updatedClass = widget.banglaClass.copyWith(
      instructorName: _instructorNameController.text,
      organizationName: _organizationController.text.isNotEmpty ? _organizationController.text : null,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _fullAddress ?? _addressController.text,
      state: _selectedState ?? '',
      city: _cityController.text,
      classTypes: _classTypes,
      teachingMethods: _selectedMethods,
      description: _descriptionController.text,
      classFee: fee,
      schedule: _scheduleController.text.isNotEmpty ? _scheduleController.text : null,
      classDuration: duration,
      maxStudents: maxStudents,
      qualifications: _qualificationsController.text.isNotEmpty ? _qualificationsController.text : null,
      culturalActivities: _culturalActivities,
      latitude: _latitude,
      longitude: _longitude,
      updatedAt: DateTime.now(),
    );

    final provider = Provider.of<EducationProvider>(context, listen: false);
    final success = await provider.updateBanglaClass(widget.banglaClass.id!, updatedClass);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      widget.onUpdate();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bangla class updated successfully'), backgroundColor: Color(0xFFFF9800)));
    }
  }
}