// lib/screens/user_app/event/my_events/my_events_screen.dart
import 'package:bangla_hub/screens/user_app/event/my_events/edit_event_dialog.dart';
import 'package:bangla_hub/screens/user_app/event/my_events/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/models/event_model.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/event_provider.dart';

import 'package:bangla_hub/screens/user_app/event/event_details_screen.dart';

class MyEventsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  
  const MyEventsScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  
  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _primaryRed = const Color(0xFFF42A41);
  final Color _goldAccent = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load user events when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        eventProvider.loadUserEvents(authProvider.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showDeleteConfirmationDialog(EventModel event) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Event',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _primaryRed),
        ),
        content: Text(
          'Are you sure you want to delete "${event.title}"? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: _primaryRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    
    if (shouldDelete == true) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      await eventProvider.deleteUserEvent(event.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event deleted successfully'),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showEditEventDialog(EventModel event) async {
    final updatedEvent = await showDialog<EventModel>(
      context: context,
      builder: (context) => EditEventDialog(event: event),
    );
    
    if (updatedEvent != null) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      await eventProvider.updateEvent(updatedEvent);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event updated successfully'),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEventDetails(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(
         
          event: event,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: isTablet ? 28 : 24,
          ),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            }
          },
        ),
        title: Text(
          'My Events',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 24 : 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryGreen,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: _goldAccent,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Approved'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyEventsList(
            onEdit: _showEditEventDialog,
            onDelete: _showDeleteConfirmationDialog,
            onTap: _showEventDetails,
          ),
          _PendingEventsList(
            onEdit: _showEditEventDialog,
            onDelete: _showDeleteConfirmationDialog,
            onTap: _showEventDetails,
          ),
        ],
      ),
    );
  }
}

class _MyEventsList extends StatelessWidget {
  final Function(EventModel) onEdit;
  final Function(EventModel) onDelete;
  final Function(EventModel) onTap;

  const _MyEventsList({
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final events = eventProvider.myEvents;
    final isLoading = eventProvider.isLoading;
    
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (events.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.event_available_rounded,
        title: 'No Events Yet',
        message: 'Events you create will be shown here',
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCard(
          event: event,
          onTap: () => onTap(event),
          onEdit: () => onEdit(event),
          onDelete: () => onDelete(event),
          showActions: true,
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required BuildContext context, required String title, required String message}) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isTablet ? 80 : 60, color: Colors.grey[400]),
            SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 20 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 14 : 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



}

class _PendingEventsList extends StatelessWidget {
  final Function(EventModel) onEdit;
  final Function(EventModel) onDelete;
  final Function(EventModel) onTap;

  const _PendingEventsList({
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final events = eventProvider.pendingEvents;
    final isLoading = eventProvider.isLoading;
    
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (events.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.hourglass_empty_rounded,
        title: 'No Pending Events',
        message: 'Events waiting for approval will appear here',
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCard(
          event: event,
          onTap: () => onTap(event),
          onEdit: () => onEdit(event),
          onDelete: () => onDelete(event),
          showActions: true,
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon,required BuildContext context, required String title, required String message}) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isTablet ? 80 : 60, color: Colors.orange[400]),
            SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 20 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
            SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 14 : 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}