// lib/screens/user_app/education_youth/sports_club/edit_sports_club_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/models/education_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/education_provider.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';

class EditSportsClubDialog extends StatefulWidget {
  final SportsClub club;
  final VoidCallback onUpdate;

  const EditSportsClubDialog({
    Key? key,
    required this.club,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EditSportsClubDialog> createState() => _EditSportsClubDialogState();
}

class _EditSportsClubDialogState extends State<EditSportsClubDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _clubNameController;
  late TextEditingController _coachNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _venueController;
  late TextEditingController _descriptionController;
  late TextEditingController _membershipFeeController;
  late TextEditingController _scheduleController;
  late TextEditingController _coachQualificationsController;
  late TextEditingController _maxMembersController;
  late TextEditingController _ageGroupController;
  late TextEditingController _skillLevelController;
  late TextEditingController _equipmentController;
  late TextEditingController _amenityController;
  late TextEditingController _tournamentController;

  // Location
  double? _latitude;
  double? _longitude;
  String? _fullAddress;
  String? _selectedState;

  SportsType? _selectedSportType;
  List<String> _ageGroups = [];
  List<String> _skillLevels = [];
  List<String> _equipmentProvided = [];
  List<String> _amenities = [];
  List<String> _tournaments = [];

  bool _isLoading = false;

  final Color _primaryRed = const Color(0xFFF44336);
  final Color _successGreen = const Color(0xFF4CAF50);
  final Color _infoBlue = const Color(0xFF2196F3);
  final Color _purpleAccent = const Color(0xFF9B59B6);

  @override
  void initState() {
    super.initState();
    _clubNameController = TextEditingController(text: widget.club.clubName);
    _coachNameController = TextEditingController(text: widget.club.coachName ?? '');
    _emailController = TextEditingController(text: widget.club.email);
    _phoneController = TextEditingController(text: widget.club.phone);
    _addressController = TextEditingController(text: widget.club.address);
    _cityController = TextEditingController(text: widget.club.city);
    _venueController = TextEditingController(text: widget.club.venue);
    _descriptionController = TextEditingController(text: widget.club.description);
    _membershipFeeController = TextEditingController(text: widget.club.membershipFee.toString());
    _scheduleController = TextEditingController(text: widget.club.schedule ?? '');
    _coachQualificationsController = TextEditingController(text: widget.club.coachQualifications ?? '');
    _maxMembersController = TextEditingController(text: widget.club.maxMembers.toString());
    _ageGroupController = TextEditingController();
    _skillLevelController = TextEditingController();
    _equipmentController = TextEditingController();
    _amenityController = TextEditingController();
    _tournamentController = TextEditingController();
    
    _selectedSportType = widget.club.sportType;
    _ageGroups = List.from(widget.club.ageGroups);
    _skillLevels = List.from(widget.club.skillLevels);
    _equipmentProvided = List.from(widget.club.equipmentProvided);
    _amenities = List.from(widget.club.amenities);
    _tournaments = List.from(widget.club.tournaments);
    _latitude = widget.club.latitude;
    _longitude = widget.club.longitude;
    _fullAddress = widget.club.address;
    _selectedState = widget.club.state;
  }

  @override
  void dispose() {
    _clubNameController.dispose();
    _coachNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _venueController.dispose();
    _descriptionController.dispose();
    _membershipFeeController.dispose();
    _scheduleController.dispose();
    _coachQualificationsController.dispose();
    _maxMembersController.dispose();
    _ageGroupController.dispose();
    _skillLevelController.dispose();
    _equipmentController.dispose();
    _amenityController.dispose();
    _tournamentController.dispose();
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
          color: _latitude != null ? Colors.red.shade50 : null,
        ),
        child: Row(
          children: [
            Icon(Icons.map_rounded, color: _primaryRed),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryRed)),
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
              decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryRed, _purpleAccent]), borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
              child: Row(
                children: [
                  Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.edit_rounded, color: Colors.white, size: 24)),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Edit Sports Club', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
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
                      _buildTextField(_clubNameController, 'Club Name *', Icons.sports_rounded),
                      const SizedBox(height: 12),
                      _buildDropdown<SportsType>(
                        value: _selectedSportType,
                        label: 'Sport Type *',
                        items: SportsType.values.map((sport) => DropdownMenuItem(value: sport, child: Text(sport.displayName))).toList(),
                        onChanged: (value) => setState(() => _selectedSportType = value),
                      ),
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
                      _buildTextField(_venueController, 'Venue *', Icons.location_on_rounded),
                      const SizedBox(height: 12),
                      _buildTextField(_descriptionController, 'Description *', Icons.description_rounded, maxLines: 3),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_membershipFeeController, 'Monthly Fee (\$) *', Icons.attach_money_rounded, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_maxMembersController, 'Max Members *', Icons.people_rounded, keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_scheduleController, 'Schedule', Icons.calendar_today_rounded, isRequired: false),
                      const SizedBox(height: 16),
                      
                      // Coach Information
                      Text('Coach Information', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _infoBlue)),
                      const SizedBox(height: 8),
                      _buildTextField(_coachNameController, 'Coach Name', Icons.person_rounded, isRequired: false),
                      const SizedBox(height: 12),
                      _buildTextField(_coachQualificationsController, 'Coach Qualifications', Icons.school_rounded, isRequired: false),
                      const SizedBox(height: 16),
                      
                      // Age Groups
                      Text('Age Groups *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _infoBlue)),
                      const SizedBox(height: 8),
                      _buildTagInput(_ageGroupController, _ageGroups, 'Add age group', () {
                        if (_ageGroupController.text.trim().isNotEmpty) {
                          setState(() { _ageGroups.add(_ageGroupController.text.trim()); _ageGroupController.clear(); });
                        }
                      }, (index) => setState(() => _ageGroups.removeAt(index))),
                      const SizedBox(height: 16),
                      
                      // Skill Levels
                      Text('Skill Levels *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _successGreen)),
                      const SizedBox(height: 8),
                      _buildTagInput(_skillLevelController, _skillLevels, 'Add skill level', () {
                        if (_skillLevelController.text.trim().isNotEmpty) {
                          setState(() { _skillLevels.add(_skillLevelController.text.trim()); _skillLevelController.clear(); });
                        }
                      }, (index) => setState(() => _skillLevels.removeAt(index))),
                      const SizedBox(height: 16),
                      
                      // Equipment
                      Text('Equipment Provided *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _primaryRed)),
                      const SizedBox(height: 8),
                      _buildTagInput(_equipmentController, _equipmentProvided, 'Add equipment', () {
                        if (_equipmentController.text.trim().isNotEmpty) {
                          setState(() { _equipmentProvided.add(_equipmentController.text.trim()); _equipmentController.clear(); });
                        }
                      }, (index) => setState(() => _equipmentProvided.removeAt(index))),
                      const SizedBox(height: 16),
                      
                      // Amenities
                      Text('Amenities', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _purpleAccent)),
                      const SizedBox(height: 8),
                      _buildTagInput(_amenityController, _amenities, 'Add amenity', () {
                        if (_amenityController.text.trim().isNotEmpty) {
                          setState(() { _amenities.add(_amenityController.text.trim()); _amenityController.clear(); });
                        }
                      }, (index) => setState(() => _amenities.removeAt(index))),
                      const SizedBox(height: 16),
                      
                      // Tournaments
                      Text('Tournaments', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.amber.shade700)),
                      const SizedBox(height: 8),
                      _buildTagInput(_tournamentController, _tournaments, 'Add tournament', () {
                        if (_tournamentController.text.trim().isNotEmpty) {
                          setState(() { _tournaments.add(_tournamentController.text.trim()); _tournamentController.clear(); });
                        }
                      }, (index) => setState(() => _tournaments.removeAt(index))),
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
                  Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _saveChanges, style: ElevatedButton.styleFrom(backgroundColor: _primaryRed, padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes'))),
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
        prefixIcon: Icon(icon, color: _primaryRed),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryRed, width: 2)),
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
          Icon(icon, color: _primaryRed, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87))),
          Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({required T? value, required String label, required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged}) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.sports_rounded, color: _primaryRed),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryRed, width: 2)),
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
            IconButton(onPressed: onAdd, icon: Icon(Icons.add, color: _primaryRed), style: IconButton.styleFrom(backgroundColor: Colors.red.shade50)),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: tags.asMap().entries.map((entry) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: _primaryRed.withOpacity(0.3))),
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
    if (_selectedSportType == null || _ageGroups.isEmpty || _skillLevels.isEmpty || _equipmentProvided.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    setState(() => _isLoading = true);

    final fee = double.tryParse(_membershipFeeController.text) ?? 0;
    final maxMembers = int.tryParse(_maxMembersController.text) ?? 50;
    
    final updatedClub = widget.club.copyWith(
      clubName: _clubNameController.text,
      sportType: _selectedSportType!,
      coachName: _coachNameController.text.isNotEmpty ? _coachNameController.text : null,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _fullAddress ?? _addressController.text,
      state: _selectedState ?? '',
      city: _cityController.text,
      venue: _venueController.text,
      description: _descriptionController.text,
      ageGroups: _ageGroups,
      skillLevels: _skillLevels,
      membershipFee: fee,
      schedule: _scheduleController.text.isNotEmpty ? _scheduleController.text : null,
      equipmentProvided: _equipmentProvided,
      coachQualifications: _coachQualificationsController.text.isNotEmpty ? _coachQualificationsController.text : null,
      amenities: _amenities,
      tournaments: _tournaments,
      maxMembers: maxMembers,
      latitude: _latitude,
      longitude: _longitude,
      updatedAt: DateTime.now(),
    );

    final provider = Provider.of<EducationProvider>(context, listen: false);
    final success = await provider.updateSportsClub(widget.club.id!, updatedClub);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      widget.onUpdate();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sports club updated successfully'), backgroundColor: Color(0xFFF44336)));
    }
  }
}