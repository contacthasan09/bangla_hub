import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bangla_hub/models/event_model.dart';
import 'package:share_plus/share_plus.dart';

class AdminEventDetailsScreen extends StatefulWidget {
  final EventModel event;
  final bool isPending;
  
  const AdminEventDetailsScreen({
    Key? key,
    required this.event,
    required this.isPending,
  }) : super(key: key);
  
  @override
  _AdminEventDetailsScreenState createState() => _AdminEventDetailsScreenState();
}

class _AdminEventDetailsScreenState extends State<AdminEventDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedStatus;
  bool _isUpdating = false;
  
  // Premium Color Palette - Bengali Flag Inspired
  final Color _primaryRed = Color(0xFFE03C32); // Bangladesh flag red
  final Color _primaryGreen = Color(0xFF006A4E); // Bangladesh flag green
  final Color _darkGreen = Color(0xFF00432D);
  final Color _lightGreen = Color(0xFFE8F5E9);
  final Color _goldAccent = Color(0xFFFFD700);
  final Color _deepRed = Color(0xFFC62828);
  final Color _bgGradient1 = Color(0xFF0A2F1D);
  final Color _bgGradient2 = Color(0xFF004D38);
  final Color _cardColor = Color(0x1AFFFFFF);
  final Color _borderColor = Color(0x33FFFFFF);
  final Color _textWhite = Color(0xFFFFFFFF);
  final Color _textLight = Color(0xFFE0E0E0);
  final Color _textMuted = Color(0xFFAAAAAA);
  final Color _offWhite = Color(0xFFF8F8F8);
  final Color _surfaceColor = Color(0xFFF5F7FA);
  final Color _purple = Color(0xFF9C27B0);
  final Color _orange = Color(0xFFFF9800);
  final Color _blue = Color(0xFF2196F3);
  final Color _amber = Color(0xFFFFC107);
  final Color _teal = Color(0xFF009688);
  final Color _indigo = Color(0xFF3F51B5);

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.event.status;
  }

  void _showPremiumSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                color == _primaryGreen ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _updateEventStatus() async {
    if (_selectedStatus == null || _selectedStatus == widget.event.status) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _firestore.collection('events').doc(widget.event.id).update({
        'status': _selectedStatus,
        'updatedAt': Timestamp.now(),
      });

      _showPremiumSnackBar(
        'Event status updated to ${_getStatusText(_selectedStatus!)}',
        _primaryGreen
      );

      Navigator.pop(context);
    } catch (e) {
      print('❌ Error updating event status: $e');
      _showPremiumSnackBar('Error updating event status: $e', _primaryRed);
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bgGradient2, _primaryRed.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: _borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryRed, _deepRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryRed.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Delete Event',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _textWhite,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this event? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: _textLight,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: _textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _deepRed],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.4),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Delete',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('events').doc(widget.event.id).delete();
        
        _showPremiumSnackBar('Event deleted successfully', _primaryGreen);
        
        Navigator.pop(context);
      } catch (e) {
        _showPremiumSnackBar('Error deleting event: $e', _primaryRed);
      }
    }
  }

  void _shareEvent() {
    final event = widget.event;
    final text = '''
🎉 ${event.title} 🎉

📅 Date: ${event.fullFormattedDate}
📍 Location: ${event.location}
👤 Organizer: ${event.organizer}

📝 Description:
${event.description}

Status: ${_getStatusText(event.status)}

Shared via Bangla Hub Admin Panel.
''';
    
    Share.share(
      text,
      subject: 'Event Details: ${event.title}',
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'suspended':
        return 'Suspended';
      case 'deleted':
        return 'Deleted';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return _amber;
      case 'approved':
        return _primaryGreen;
      case 'suspended':
        return _primaryRed;
      case 'deleted':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'suspended':
        return Icons.block_rounded;
      case 'deleted':
        return Icons.delete_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isTablet = screenWidth >= 600;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _bgGradient1,
                _bgGradient2,
                _primaryGreen,
              ],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              // Premium Sliver App Bar
              SliverAppBar(
                expandedHeight: isTablet ? 400 : 320,
                collapsedHeight: isTablet ? 120 : 100,
                floating: false,
                pinned: true,
                snap: false,
                elevation: 0,
                backgroundColor: Colors.transparent,
                leading: Container(
                  margin: EdgeInsets.only(left: 20, top: isTablet ? 10 : 0),
                  child: Material(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: isTablet ? 28 : 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Container(
                    margin: EdgeInsets.only(right: 10, top: isTablet ? 10 : 0),
                    child: Material(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _shareEvent,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: Icon(
                              Icons.share_rounded,
                              color: Colors.white,
                              size: isTablet ? 24 : 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!widget.isPending)
                  Container(
                    margin: EdgeInsets.only(right: 20, top: isTablet ? 10 : 0),
                    child: Material(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _deleteEvent,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                              size: isTablet ? 24 : 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Event Image
                      widget.event.bannerImageWidget,
                      
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.black.withOpacity(0.5),
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.0, 0.3, 0.6, 1.0],
                          ),
                        ),
                      ),
                      
                      // Event Details Overlay
                      Positioned(
                        bottom: isTablet ? 60 : 40,
                        left: isTablet ? 40 : 20,
                        right: isTablet ? 40 : 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 16 : 12,
                                    vertical: isTablet ? 10 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_primaryRed, _primaryGreen],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    widget.event.categoryText,
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 14 : 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 16 : 12,
                                    vertical: isTablet ? 10 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(widget.event.status).withOpacity(0.2),
                                    border: Border.all(
                                      color: _getStatusColor(widget.event.status),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getStatusIcon(widget.event.status),
                                        size: isTablet ? 16 : 14,
                                        color: _getStatusColor(widget.event.status),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        _getStatusText(widget.event.status).toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: isTablet ? 14 : 12,
                                          fontWeight: FontWeight.w800,
                                          color: _getStatusColor(widget.event.status),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isTablet ? 16 : 12),
                            
                            Text(
                              widget.event.title,
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 36 : 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isTablet ? 12 : 8),
                            
                            Row(
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  color: Colors.white.withOpacity(0.9),
                                  size: isTablet ? 22 : 18,
                                ),
                                SizedBox(width: isTablet ? 12 : 8),
                                Text(
                                  widget.event.organizer,
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 18 : 16,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Premium Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isTablet ? 50 : 40),
                      topRight: Radius.circular(isTablet ? 50 : 40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 32 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: isTablet ? 20 : 16),
                        
                        // Status Update Section (only for pending events)
                        if (widget.isPending)
                          Container(
                            padding: EdgeInsets.all(isTablet ? 28 : 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _primaryGreen.withOpacity(0.1),
                                  _primaryRed.withOpacity(0.05)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                              border: Border.all(
                                color: _borderColor,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: isTablet ? 60 : 50,
                                      height: isTablet ? 60 : 50,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_primaryRed, _primaryGreen],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.admin_panel_settings_rounded,
                                          color: Colors.white,
                                          size: isTablet ? 28 : 24,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 20 : 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Admin Review Panel',
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 22 : 20,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Submitted ${DateFormat('MMM d, y - h:mm a').format(widget.event.createdAt)}',
                                            style: GoogleFonts.inter(
                                              fontSize: isTablet ? 16 : 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isTablet ? 24 : 20),
                                
                                // Status Selection Card
                                Container(
                                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                    border: Border.all(
                                      color: _borderColor,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Update Event Status',
                                        style: GoogleFonts.inter(
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: isTablet ? 16 : 12),
                                      
                                      // Premium Status Dropdown
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isTablet ? 20 : 16,
                                          vertical: isTablet ? 16 : 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                          border: Border.all(
                                            color: _selectedStatus != null 
                                              ? _getStatusColor(_selectedStatus!)
                                              : _borderColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _selectedStatus != null 
                                                ? _getStatusIcon(_selectedStatus!)
                                                : Icons.info_rounded,
                                              color: _selectedStatus != null
                                                ? _getStatusColor(_selectedStatus!)
                                                : _textMuted,
                                              size: isTablet ? 24 : 20,
                                            ),
                                            SizedBox(width: isTablet ? 16 : 12),
                                            Expanded(
                                              child: DropdownButton<String>(
                                                value: _selectedStatus,
                                                isExpanded: true,
                                                underline: SizedBox(),
                                                icon: Icon(
                                                  Icons.arrow_drop_down_rounded,
                                                  color: _textMuted,
                                                  size: isTablet ? 28 : 24,
                                                ),
                                                style: GoogleFonts.inter(
                                                  fontSize: isTablet ? 18 : 16,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                items: [
                                                  DropdownMenuItem(
                                                    value: 'pending',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.access_time_rounded,
                                                          color: _amber,
                                                          size: isTablet ? 22 : 18,
                                                        ),
                                                        SizedBox(width: isTablet ? 16 : 12),
                                                        Text('Pending Review'),
                                                      ],
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'approved',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.check_circle_rounded,
                                                          color: _primaryGreen,
                                                          size: isTablet ? 22 : 18,
                                                        ),
                                                        SizedBox(width: isTablet ? 16 : 12),
                                                        Text('Approve Event'),
                                                      ],
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'suspended',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.block_rounded,
                                                          color: _primaryRed,
                                                          size: isTablet ? 22 : 18,
                                                        ),
                                                        SizedBox(width: isTablet ? 16 : 12),
                                                        Text('Suspend Event'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedStatus = value;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: isTablet ? 20 : 16),
                                
                                // Update Button
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isUpdating ? null : _updateEventStatus,
                                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        vertical: isTablet ? 20 : 18,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _selectedStatus == 'approved'
                                            ? [_primaryGreen, _darkGreen]
                                            : _selectedStatus == 'suspended'
                                              ? [_primaryRed, _deepRed]
                                              : [_amber, _orange],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _selectedStatus == 'approved'
                                              ? _primaryGreen.withOpacity(0.4)
                                              : _selectedStatus == 'suspended'
                                                ? _primaryRed.withOpacity(0.4)
                                                : _amber.withOpacity(0.4),
                                            blurRadius: 15,
                                            offset: Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _isUpdating
                                            ? SizedBox(
                                                width: isTablet ? 24 : 20,
                                                height: isTablet ? 24 : 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                _selectedStatus == 'approved'
                                                  ? 'APPROVE EVENT'
                                                  : _selectedStatus == 'suspended'
                                                    ? 'SUSPEND EVENT'
                                                    : 'UPDATE STATUS',
                                                style: GoogleFonts.poppins(
                                                  fontSize: isTablet ? 18 : 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        if (widget.isPending) SizedBox(height: isTablet ? 32 : 24),
                        
                        // Event Details Section
                        _buildPremiumDetailSection(
                          title: 'Event Details',
                          icon: Icons.event_rounded,
                          child: Column(
                            children: [
                              // Date & Time Card
                              _buildPremiumDetailCard(
                                icon: Icons.calendar_today_rounded,
                                title: 'Date & Time',
                                value: widget.event.fullFormattedDate,
                                gradientColors: [_primaryRed, _primaryGreen],
                                isTablet: isTablet,
                              ),
                              SizedBox(height: isTablet ? 20 : 16),
                              
                              // Location Card
                              _buildPremiumDetailCard(
                                icon: Icons.location_on_rounded,
                                title: 'Location',
                                value: widget.event.location,
                                gradientColors: [_primaryGreen, _darkGreen],
                                isTablet: isTablet,
                              ),
                            ],
                          ),
                          isTablet: isTablet,
                        ),
                        
                        SizedBox(height: isTablet ? 32 : 24),
                        
                        // Contact Information Section
                        _buildPremiumDetailSection(
                          title: 'Contact Information',
                          icon: Icons.contact_phone_rounded,
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 24 : 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                              border: Border.all(color: _borderColor, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildPremiumContactItem(
                                  icon: Icons.person_rounded,
                                  title: 'Contact Person',
                                  value: widget.event.contactPerson,
                                  isTablet: isTablet,
                                ),
                                SizedBox(height: isTablet ? 20 : 16),
                                _buildPremiumContactItem(
                                  icon: Icons.email_rounded,
                                  title: 'Email',
                                  value: widget.event.contactEmail,
                                  isTablet: isTablet,
                                ),
                                SizedBox(height: isTablet ? 20 : 16),
                                _buildPremiumContactItem(
                                  icon: Icons.phone_rounded,
                                  title: 'Phone',
                                  value: widget.event.contactPhone,
                                  isTablet: isTablet,
                                ),
                              ],
                            ),
                          ),
                          isTablet: isTablet,
                        ),
                        
                        SizedBox(height: isTablet ? 32 : 24),
                        
                        // Event Statistics Section
                        _buildPremiumDetailSection(
                          title: 'Event Statistics',
                          icon: Icons.bar_chart_rounded,
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 24 : 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                              border: Border.all(color: _borderColor, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildPremiumStatItem(
                                      icon: Icons.people_rounded,
                                      value: widget.event.totalInterested.toString(),
                                      label: 'Interested',
                                      color: _orange,
                                      isTablet: isTablet,
                                    ),
                                    _buildPremiumStatItem(
                                      icon: _getStatusIcon(widget.event.status),
                                      value: _getStatusText(widget.event.status),
                                      label: 'Status',
                                      color: _getStatusColor(widget.event.status),
                                      isTablet: isTablet,
                                    ),
                                    _buildPremiumStatItem(
                                      icon: Icons.calendar_today_rounded,
                                      value: DateFormat('MMM d').format(widget.event.createdAt),
                                      label: 'Created',
                                      color: _blue,
                                      isTablet: isTablet,
                                    ),
                                  ],
                                ),
                                SizedBox(height: isTablet ? 20 : 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildPremiumStatItem(
                                      icon: Icons.event_available_rounded,
                                      value: widget.event.isFree ? 'Free' : 'Paid',
                                      label: 'Type',
                                      color: widget.event.isFree ? _teal : _purple,
                                      isTablet: isTablet,
                                    ),
                                    _buildPremiumStatItem(
                                      icon: Icons.category_rounded,
                                      value: widget.event.categoryText,
                                      label: 'Category',
                                      color: _indigo,
                                      isTablet: isTablet,
                                    ),
                                    _buildPremiumStatItem(
                                      icon: Icons.update_rounded,
value: widget.event.updatedAt != null 
    ? DateFormat('MMM d').format(widget.event.updatedAt!)
    : 'N/A',                                      label: 'Updated',
                                      color: _amber,
                                      isTablet: isTablet,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          isTablet: isTablet,
                        ),
                        
                        SizedBox(height: isTablet ? 32 : 24),
                        
                        // Description Section
                        _buildPremiumDetailSection(
                          title: 'Description',
                          icon: Icons.description_rounded,
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 24 : 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                              border: Border.all(color: _borderColor, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.event.description,
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 18 : 16,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                          ),
                          isTablet: isTablet,
                        ),
                        
                        SizedBox(height: isTablet ? 32 : 24),
                        
                        // Ticket Information Section
                        if (!widget.event.isFree && widget.event.ticketPrices != null)
                          _buildPremiumDetailSection(
                            title: 'Ticket Prices',
                            icon: Icons.confirmation_number_rounded,
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 24 : 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                                border: Border.all(color: _borderColor, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 15,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: widget.event.ticketPrices!.entries.map((entry) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: isTablet ? 24 : 20,
                                                height: isTablet ? 24 : 20,
                                                decoration: BoxDecoration(
                                                  color: _primaryGreen.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.confirmation_number_rounded,
                                                    color: _primaryGreen,
                                                    size: isTablet ? 16 : 14,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: isTablet ? 16 : 12),
                                              Expanded(
                                                child: Text(
                                                  entry.key,
                                                  style: GoogleFonts.inter(
                                                    fontSize: isTablet ? 18 : 16,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isTablet ? 20 : 16,
                                            vertical: isTablet ? 10 : 8,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [_primaryRed, _deepRed],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                                          ),
                                          child: Text(
                                            '\$${entry.value.toStringAsFixed(2)}',
                                            style: GoogleFonts.inter(
                                              fontSize: isTablet ? 18 : 16,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                        
                        if (widget.event.isFree)
                          Container(
                            padding: EdgeInsets.all(isTablet ? 24 : 20),
                            margin: EdgeInsets.only(top: isTablet ? 32 : 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryGreen.withOpacity(0.1), _primaryRed.withOpacity(0.05)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                              border: Border.all(color: _primaryGreen.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: isTablet ? 60 : 50,
                                  height: isTablet ? 60 : 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_primaryGreen, _darkGreen],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryGreen.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 28 : 24,
                                    ),
                                  ),
                                ),
                                SizedBox(width: isTablet ? 20 : 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Free Event',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 22 : 20,
                                          fontWeight: FontWeight.w800,
                                          color: _primaryGreen,
                                        ),
                                      ),
                                      SizedBox(height: isTablet ? 8 : 6),
                                      Text(
                                        'No tickets required. Join for free!',
                                        style: GoogleFonts.inter(
                                          fontSize: isTablet ? 16 : 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        SizedBox(height: isTablet ? 40 : 32),
                        
                        // Premium Admin Footer
                        Container(
                          padding: EdgeInsets.all(isTablet ? 30 : 24),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(isTablet ? 30 : 24),
                            border: Border.all(color: _borderColor, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: isTablet ? 60 : 50,
                                height: isTablet ? 60 : 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryRed, _primaryGreen],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.admin_panel_settings_rounded,
                                    color: Colors.white,
                                    size: isTablet ? 28 : 24,
                                  ),
                                ),
                              ),
                              SizedBox(width: isTablet ? 20 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Admin Control Panel',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.w800,
                                        color: _primaryGreen,
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 8 : 6),
                                    Text(
                                      'Manage event status and view details',
                                      style: GoogleFonts.inter(
                                        fontSize: isTablet ? 16 : 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: isTablet ? 40 : 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPremiumDetailSection({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isTablet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: isTablet ? 50 : 40,
              height: isTablet ? 50 : 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryRed, _primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isTablet ? 24 : 20,
                ),
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 26 : 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 20 : 16),
        child,
      ],
    );
  }
  
  Widget _buildPremiumDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required List<Color> gradientColors,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 60 : 50,
            height: isTablet ? 60 : 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: isTablet ? 28 : 24,
              ),
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPremiumContactItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isTablet,
  }) {
    return Row(
      children: [
        Container(
          width: isTablet ? 50 : 40,
          height: isTablet ? 50 : 40,
          decoration: BoxDecoration(
            color: _primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
          ),
          child: Center(
            child: Icon(
              icon,
              color: _primaryGreen,
              size: isTablet ? 22 : 18,
            ),
          ),
        ),
        SizedBox(width: isTablet ? 16 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 14 : 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPremiumStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isTablet,
  }) {
    return Column(
      children: [
        Container(
          width: isTablet ? 70 : 60,
          height: isTablet ? 70 : 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: isTablet ? 28 : 24,
            ),
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 14 : 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}