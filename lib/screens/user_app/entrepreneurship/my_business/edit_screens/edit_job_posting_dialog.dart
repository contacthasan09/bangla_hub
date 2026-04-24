// lib/screens/user_app/entrepreneurship/job_posting/edit_job_posting_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';

class EditJobPostingDialog extends StatefulWidget {
  final JobPosting job;
  final VoidCallback onUpdate;

  const EditJobPostingDialog({Key? key, required this.job, required this.onUpdate}) : super(key: key);

  @override
  State<EditJobPostingDialog> createState() => _EditJobPostingDialogState();
}

class _EditJobPostingDialogState extends State<EditJobPostingDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _jobTitleController;
  late TextEditingController _companyNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _requirementsController;
  late TextEditingController _locationController;
  late TextEditingController _cityController;
  late TextEditingController _contactEmailController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _skillsController;
  late TextEditingController _benefitsController;
  
  JobType? _selectedJobType;
  ExperienceLevel? _selectedExperienceLevel;
  DateTime? _selectedDeadline;
  List<String> _skillsRequired = [];
  List<String> _benefits = [];
  bool _isUrgent = false;
  
  // Location
  double? _latitude;
  double? _longitude;
  String? _selectedState;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _jobTitleController = TextEditingController(text: widget.job.jobTitle);
    _companyNameController = TextEditingController(text: widget.job.companyName);
    _descriptionController = TextEditingController(text: widget.job.description);
    _requirementsController = TextEditingController(text: widget.job.requirements);
    _locationController = TextEditingController(text: widget.job.location);
    _cityController = TextEditingController(text: widget.job.city);
    _contactEmailController = TextEditingController(text: widget.job.contactEmail);
    _contactPhoneController = TextEditingController(text: widget.job.contactPhone);
    _skillsController = TextEditingController();
    _benefitsController = TextEditingController();
    
    _selectedJobType = widget.job.jobType;
    _selectedExperienceLevel = widget.job.experienceLevel;
    _selectedDeadline = widget.job.applicationDeadline;
    _skillsRequired = List.from(widget.job.skillsRequired);
    _benefits = List.from(widget.job.benefits);
    _isUrgent = widget.job.isUrgent;
    _latitude = widget.job.latitude;
    _longitude = widget.job.longitude;
    _selectedState = widget.job.state;
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _companyNameController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _skillsController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDeadline = picked);
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
            initialAddress: _locationController.text,
            initialState: _selectedState,
            initialCity: _cityController.text,
            onLocationSelected: (lat, lng, address, state, city) {
              setState(() {
                _latitude = lat;
                _longitude = lng;
                _selectedState = state;
                _locationController.text = address;
                if (city != null) _cityController.text = city;
              });
            },
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12), color: _latitude != null ? Colors.red[50] : null),
        child: Row(
          children: [
            Icon(Icons.map_rounded, color: const Color(0xFFE74C3C)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Location', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFE74C3C))),
              Text(_locationController.text.isEmpty ? 'Tap to select location' : _locationController.text, style: GoogleFonts.inter(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
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
            Container(
              padding: EdgeInsets.all(20),
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE74C3C), Color(0xFFC0392B)]), borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
              child: Row(
                children: [
                  Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.edit_rounded, color: Color(0xFFFFD700), size: 24)),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Edit Job Posting', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white)),
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
                      _buildTextField(_jobTitleController, 'Job Title', Icons.title_rounded),
                      const SizedBox(height: 12),
                      _buildTextField(_companyNameController, 'Company Name', Icons.business_rounded),
                      const SizedBox(height: 12),
                      _buildLocationPickerField(),
                      const SizedBox(height: 12),
                      _buildDropdown<JobType>(
                        value: _selectedJobType,
                        hint: 'Job Type',
                        items: JobType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.displayName))).toList(),
                        onChanged: (value) => setState(() => _selectedJobType = value),
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown<ExperienceLevel>(
                        value: _selectedExperienceLevel,
                        hint: 'Experience Level',
                        items: ExperienceLevel.values.map((level) => DropdownMenuItem(value: level, child: Text(level.displayName))).toList(),
                        onChanged: (value) => setState(() => _selectedExperienceLevel = value),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_descriptionController, 'Job Description', Icons.description_rounded, maxLines: 4),
                      const SizedBox(height: 12),
                      _buildTextField(_requirementsController, 'Requirements', Icons.checklist_rounded, maxLines: 3),
                      const SizedBox(height: 12),
                      _buildTextField(_contactEmailController, 'Contact Email', Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _buildTextField(_contactPhoneController, 'Enter a valid US number *', Icons.phone_rounded, keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      
                      // Deadline
                      GestureDetector(
                        onTap: _selectDeadline,
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, color: const Color(0xFFE74C3C)),
                              const SizedBox(width: 12),
                              Expanded(child: Text(_selectedDeadline != null ? DateFormat('MMMM d, yyyy').format(_selectedDeadline!) : 'Select Application Deadline', style: GoogleFonts.inter(fontSize: 14))),
                              Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Skills
                      Text('Skills Required', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _buildTagInput(_skillsController, _skillsRequired, 'Add skill', () {
                        if (_skillsController.text.trim().isNotEmpty) {
                          setState(() { _skillsRequired.add(_skillsController.text.trim()); _skillsController.clear(); });
                        }
                      }, (index) => setState(() => _skillsRequired.removeAt(index))),
                      const SizedBox(height: 12),
                      
                      // Benefits
                      Text('Benefits', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _buildTagInput(_benefitsController, _benefits, 'Add benefit', () {
                        if (_benefitsController.text.trim().isNotEmpty) {
                          setState(() { _benefits.add(_benefitsController.text.trim()); _benefitsController.clear(); });
                        }
                      }, (index) => setState(() => _benefits.removeAt(index))),
                      const SizedBox(height: 12),
                      
                      // Urgent
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _isUrgent ? Colors.red[50] : Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: _isUrgent ? Colors.red : Colors.grey[300]!)),
                        child: Row(
                          children: [
                            Checkbox(value: _isUrgent, onChanged: (value) => setState(() => _isUrgent = value ?? false), activeColor: Colors.red),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Mark as Urgent', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _isUrgent ? Colors.red : Colors.black87)),
                              Text('Urgent jobs will be highlighted', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                            ])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
              child: Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _saveChanges, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C), padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes' , style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),))),
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
        prefixIcon: Icon(icon, color: const Color(0xFFE74C3C)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2)),
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
        prefixIcon: Icon(Icons.work_rounded, color: const Color(0xFFE74C3C)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items,
      onChanged: onChanged,
      validator: (value) => value == null ? 'Required' : null,
    );
  }

  Widget _buildTagInput(TextEditingController controller, List<String> tags, String hint, VoidCallback onAdd, Function(int) onRemove) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: TextField(controller: controller, decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onSubmitted: (_) => onAdd())),
            const SizedBox(width: 8),
            IconButton(onPressed: onAdd, icon: const Icon(Icons.add, color: Color(0xFFE74C3C)), style: IconButton.styleFrom(backgroundColor: Colors.red[50])),
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
    if (_selectedJobType == null || _selectedExperienceLevel == null || _selectedDeadline == null) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select location on map')));
      return;
    }

    setState(() => _isLoading = true);

    final updatedJob = widget.job.copyWith(
      jobTitle: _jobTitleController.text,
      companyName: _companyNameController.text,
      description: _descriptionController.text,
      requirements: _requirementsController.text,
      jobType: _selectedJobType!,
      experienceLevel: _selectedExperienceLevel!,
      location: _locationController.text,
      state: _selectedState ?? '',
      city: _cityController.text,
      contactEmail: _contactEmailController.text,
      contactPhone: _contactPhoneController.text,
      applicationDeadline: _selectedDeadline!,
      skillsRequired: _skillsRequired,
      benefits: _benefits,
      isUrgent: _isUrgent,
      latitude: _latitude,
      longitude: _longitude,
      updatedAt: DateTime.now(),
    );

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    final success = await provider.updateJobPosting(widget.job.id!, updatedJob);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      widget.onUpdate();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job posting updated successfully'), backgroundColor: Color(0xFFE74C3C)));
    }
  }
}