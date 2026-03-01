import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunityServicesScreen extends StatelessWidget {
  final Color _primaryGreen = Color(0xFF006A4E);
  final Color _darkGreen = Color(0xFF004D38);
  final Color _offWhite = Color(0xFFF8F8F8);
  final Color _lightGreen = Color(0xFFE8F5E9);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_primaryGreen, _darkGreen],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
          //  expandedHeight: 200,
           expandedHeight: 180,
            collapsedHeight: 120,
            floating: false,
            pinned: true,
            snap: false,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryGreen.withOpacity(0.95),
                      _darkGreen.withOpacity(0.95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community Services',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Connecting Bengalis across North America',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: _offWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureCard(
                      icon: Icons.business_rounded,
                      title: 'Local Bengali Businesses',
                      description: 'Find Bengali-owned businesses in your area',
                    ),
                    SizedBox(height: 16),
                    _buildFeatureCard(
                      icon: Icons.group_rounded,
                      title: 'Community Support Groups',
                      description: 'Connect with support groups and community organizations',
                    ),
                    SizedBox(height: 16),
                    _buildFeatureCard(
                      icon: Icons.calendar_today_rounded,
                      title: 'Cultural Events Calendar',
                      description: 'Stay updated with cultural events and festivals',
                    ),
                    SizedBox(height: 16),
                    _buildFeatureCard(
                      icon: Icons.volunteer_activism_rounded,
                      title: 'Volunteer Opportunities',
                      description: 'Find volunteering opportunities in the community',
                    ),
                    SizedBox(height: 32),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _lightGreen,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _primaryGreen.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coming Soon',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _primaryGreen,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'We\'re working hard to bring you more community services features. Stay tuned for updates!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: _primaryGreen,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}