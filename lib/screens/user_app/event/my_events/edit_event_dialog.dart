// lib/screens/user_app/event/edit_event_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bangla_hub/models/event_model.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';

class EditEventDialog extends StatefulWidget {
  final EventModel event;

  const EditEventDialog({Key? key, required this.event}) : super(key: key);

  @override
  State<EditEventDialog> createState() => _EditEventDialogState();
}

class _EditEventDialogState extends State<EditEventDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _organizerController;
  late TextEditingController _contactPersonController;
  late TextEditingController _contactEmailController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _ticketTypeController;
  late TextEditingController _ticketPriceController;
  
  late DateTime _eventDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _category;
  bool _isFree = true;
  
  // Location coordinates
  double? _latitude;
  double? _longitude;
  String? _selectedState;
  String? _selectedCity;
  
  // Ticket prices
  final Map<String, double> _ticketPrices = {};

  // Premium Colors
  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _darkGreen = const Color(0xFF004D38);
  final Color _lightGreen = const Color(0xFFE8F5E9);
  final Color _goldAccent = const Color(0xFFFFD700);
  final Color _softGold = const Color(0xFFFFD966);
  final Color _coralRed = const Color(0xFFFF6B6B);
  final Color _emeraldGreen = const Color(0xFF2ECC71);
  final Color _sapphireBlue = const Color(0xFF3498DB);
  final Color _amethystPurple = const Color(0xFF9B59B6);

  final List<Map<String, dynamic>> _categories = [
    {'value': 'sports', 'label': 'SPORTS', 'icon': Icons.sports_soccer_rounded, 'color': const Color(0xFF2ECC71)},
    {'value': 'religious', 'label': 'RELIGIOUS', 'icon': Icons.mosque_rounded, 'color': const Color(0xFF9B59B6)},
    {'value': 'business', 'label': 'BUSINESS', 'icon': Icons.business_rounded, 'color': const Color(0xFF3498DB)},
    {'value': 'educational', 'label': 'EDUCATIONAL', 'icon': Icons.school_rounded, 'color': const Color(0xFF2ECC71)},
    {'value': 'social', 'label': 'SOCIAL', 'icon': Icons.groups_rounded, 'color': const Color(0xFFFF6B6B)},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _organizerController = TextEditingController(text: widget.event.organizer);
    _contactPersonController = TextEditingController(text: widget.event.contactPerson);
    _contactEmailController = TextEditingController(text: widget.event.contactEmail);
    _contactPhoneController = TextEditingController(text: widget.event.contactPhone);
    _locationController = TextEditingController(text: widget.event.location);
    _descriptionController = TextEditingController(text: widget.event.description);
    _ticketTypeController = TextEditingController();
    _ticketPriceController = TextEditingController();
    
    _eventDate = widget.event.eventDate;
    _endDate = widget.event.endDate;
    _startTime = widget.event.startTime;
    _endTime = widget.event.endTime;
    _category = widget.event.category;
    _isFree = widget.event.isFree;
    _latitude = widget.event.latitude;
    _longitude = widget.event.longitude;
    _selectedState = widget.event.state;
    _selectedCity = widget.event.city;
    
    // Load existing ticket prices if any
    if (widget.event.ticketPrices != null) {
      _ticketPrices.addAll(widget.event.ticketPrices!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _organizerController.dispose();
    _contactPersonController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _ticketTypeController.dispose();
    _ticketPriceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryGreen,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _eventDate,
      firstDate: _eventDate,
      lastDate: _eventDate.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: _primaryGreen,
              dialHandColor: _primaryGreen,
              dialBackgroundColor: _lightGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  void _addTicket() {
    final type = _ticketTypeController.text.trim();
    final priceText = _ticketPriceController.text.trim();
    if (type.isNotEmpty && priceText.isNotEmpty) {
      final price = double.tryParse(priceText);
      if (price != null && price > 0) {
        setState(() {
          _ticketPrices[type] = price;
          _ticketTypeController.clear();
          _ticketPriceController.clear();
        });
      }
    }
  }

  void _removeTicket(String type) {
    setState(() {
      _ticketPrices.remove(type);
    });
  }

  Widget _buildTicketPricesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_goldAccent.withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _goldAccent.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              // Existing tickets
              if (_ticketPrices.isNotEmpty) ...[
                ..._ticketPrices.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _primaryGreen,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_goldAccent, _softGold],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\$${entry.value.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeTicket(entry.key),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _coralRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: _coralRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
              ],
              
              // Add new ticket row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextFormField(
                        controller: _ticketTypeController,
                        style: GoogleFonts.inter(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Type',
                          hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextFormField(
                        controller: _ticketPriceController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Price',
                          hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400]),
                          prefixText: '\$',
                          prefixStyle: GoogleFonts.inter(fontSize: 12),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addTicket,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_emeraldGreen, _emeraldGreen.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
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
            initialAddress: _locationController.text,
            initialState: _selectedState,
            initialCity: _selectedCity,
            onLocationSelected: (lat, lng, address, state, city) {
              setState(() {
                _latitude = lat;
                _longitude = lng;
                _selectedState = state;
                _selectedCity = city;
                _locationController.text = address;
              });
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_coralRed.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _coralRed.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_coralRed, _coralRed.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.map_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Location',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _coralRed,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _locationController.text.isEmpty ? 'Tap to select location' : _locationController.text,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _locationController.text.isEmpty ? Colors.grey[500] : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: _coralRed),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(Map<String, dynamic> category) {
    final isSelected = _category == category['value'];
    return GestureDetector(
      onTap: () => setState(() => _category = category['value']),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [category['color'], category['color'].withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? category['color'] : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category['icon'],
              color: isSelected ? Colors.white : category['color'],
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              category['label'],
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryGreen, _darkGreen],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit Event',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
            
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _titleController,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: 'Event Title',
                            labelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _primaryGreen),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _primaryGreen, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Organizer
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _organizerController,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: 'Organizer',
                            labelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _sapphireBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _sapphireBlue, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Contact Person & Email Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              child: TextFormField(
                                controller: _contactPersonController,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  labelText: 'Contact Person',
                                  labelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _amethystPurple),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: _amethystPurple, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 44,
                              child: TextFormField(
                                controller: _contactEmailController,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _sapphireBlue),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: _sapphireBlue, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Phone
                      Container(
                        height: 44,
                        child: TextFormField(
                          controller: _contactPhoneController,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            labelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _coralRed),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _coralRed, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Category Section
                      Text(
                        'Category',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((cat) => _buildCategoryChip(cat)).toList(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Date & Time
                      Text(
                        'Date & Time',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Event Date
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 16, color: _primaryGreen),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('MMM d, yyyy').format(_eventDate),
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // End Date (if multi-day)
                      GestureDetector(
                        onTap: _selectEndDate,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 16, color: _emeraldGreen),
                              const SizedBox(width: 10),
                              Text(
                                _endDate != null
                                    ? 'End: ${DateFormat('MMM d, yyyy').format(_endDate!)}'
                                    : 'End Date (Optional)',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Start Time
                      GestureDetector(
                        onTap: _selectStartTime,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 16, color: _sapphireBlue),
                              const SizedBox(width: 10),
                              Text(
                                _startTime != null
                                    ? 'Start: ${_startTime!.format(context)}'
                                    : 'Start Time (Optional)',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // End Time
                      GestureDetector(
                        onTap: _selectEndTime,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 16, color: _amethystPurple),
                              const SizedBox(width: 10),
                              Text(
                                _endTime != null
                                    ? 'End: ${_endTime!.format(context)}'
                                    : 'End Time (Optional)',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Location Picker
                      _buildLocationPickerField(),
                      const SizedBox(height: 16),
                      
                      // Description
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
                          decoration: InputDecoration(
                            labelText: 'Description',
                            labelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _goldAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _goldAccent, width: 1.5),
                            ),
                            alignLabelWithHint: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Free/Paid Toggle
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_goldAccent.withOpacity(0.1), Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _goldAccent.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.money_off_rounded, color: _goldAccent, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Free Event',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _goldAccent,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isFree,
                              onChanged: (value) => setState(() => _isFree = value),
                              activeColor: Colors.white,
                              activeTrackColor: _primaryGreen,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: Colors.grey[400],
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            //  visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                      
                      // Ticket Prices Section (if not free)
                      if (!_isFree) _buildTicketPricesSection(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _coralRed,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: _coralRed, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final updatedEvent = widget.event.copyWith(
                            title: _titleController.text,
                            organizer: _organizerController.text,
                            contactPerson: _contactPersonController.text,
                            contactEmail: _contactEmailController.text,
                            contactPhone: _contactPhoneController.text,
                            eventDate: _eventDate,
                            endDate: _endDate,
                            startTime: _startTime,
                            endTime: _endTime,
                            location: _locationController.text,
                            description: _descriptionController.text,
                            category: _category!,
                            isFree: _isFree,
                            ticketPrices: _isFree ? null : _ticketPrices,
                            latitude: _latitude,
                            longitude: _longitude,
                            state: _selectedState,
                            city: _selectedCity,
                          );
                          Navigator.pop(context, updatedEvent);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                        shadowColor: _primaryGreen.withOpacity(0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_rounded, size: 16 ,color: Colors.white,),
                          const SizedBox(width: 6),
                          Text(
                            'Save',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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
}