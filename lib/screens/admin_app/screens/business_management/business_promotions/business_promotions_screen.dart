// lib/screens/admin/entrepreneurship/admin_business_promotions_screen.dart

import 'dart:typed_data';

import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class AdminBusinessPromotionsScreen extends StatefulWidget {
  @override
  _AdminBusinessPromotionsScreenState createState() => _AdminBusinessPromotionsScreenState();
}

class _AdminBusinessPromotionsScreenState extends State<AdminBusinessPromotionsScreen> with SingleTickerProviderStateMixin {
  final Color _primaryGreen = Color(0xFF006A4E);
  final Color _darkGreen = Color(0xFF004D38);
  
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPromotions();
    });
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {
        _searchQuery = '';
        _searchController.clear();
      });
    }
  }

  Future<void> _loadPromotions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    await provider.loadBusinessPromotions(adminView: true);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _permanentDeletePromotion(dynamic item) async {
  final id = item.id!;
  final title = item.businessName;
  
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Permanent Delete'),
      content: Text(
        'Are you sure you want to permanently delete "$title"? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete Permanently'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    final success = await provider.permanentDeleteBusinessPromotion(id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business promotion permanently deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isTablet = screenSize.width >= 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: isSmallScreen ? 200 : (isTablet ? 260 : 220),
              floating: false,
              pinned: true,
              backgroundColor: _primaryGreen,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryGreen, _darkGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : 20, 
                        vertical: isTablet ? 30 : 20
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Business Promotions',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 28 : (isSmallScreen ? 20 : 24),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 8),
                          Text(
                            'Review, verify, and manage business promotions',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : (isSmallScreen ? 12 : 14),
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(isTablet ? 140 : 120),
                child: Container(
                  color: _primaryGreen,
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 16,
                          vertical: isTablet ? 12 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: isTablet 
                                ? 'Search by business name, owner, location, tags...'
                                : 'Search promotions...',
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: isTablet ? 16 : 12,
                            ),
                          ),
                        ),
                      ),
                      
                      // Tab Bar with Count Badges
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 800 : double.infinity,
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.white,
                          indicatorWeight: 3,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white.withOpacity(0.7),
                          isScrollable: isSmallScreen,
                          tabs: [
                            Tab(
                              child: Consumer<EntrepreneurshipProvider>(
                                builder: (context, provider, child) {
                                  final count = provider.businessPromotions
                                      .where((p) => !p.isVerified && !p.isDeleted && p.isActive)
                                      .length;
                                  return _buildTabContent(
                                    icon: Icons.pending_actions_rounded,
                                    label: isSmallScreen ? 'Pend' : 'Pending',
                                    count: count,
                                    color: Colors.orange,
                                    isSmallScreen: isSmallScreen,
                                  );
                                },
                              ),
                            ),
                            Tab(
                              child: Consumer<EntrepreneurshipProvider>(
                                builder: (context, provider, child) {
                                  final count = provider.businessPromotions
                                      .where((p) => p.isVerified && !p.isDeleted && p.isActive)
                                      .length;
                                  return _buildTabContent(
                                    icon: Icons.check_circle_rounded,
                                    label: 'Active',
                                    count: count,
                                    color: Colors.green,
                                    isSmallScreen: isSmallScreen,
                                  );
                                },
                              ),
                            ),
                            Tab(
                              child: Consumer<EntrepreneurshipProvider>(
                                builder: (context, provider, child) {
                                  final count = provider.businessPromotions
                                      .where((p) => p.isDeleted || !p.isActive)
                                      .length;
                                  return _buildTabContent(
                                    icon: Icons.block_rounded,
                                    label: 'Rejected',
                                    count: count,
                                    color: Colors.red,
                                    isSmallScreen: isSmallScreen,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: Consumer<EntrepreneurshipProvider>(
          builder: (context, provider, child) {
            if (_isLoading && provider.businessPromotions.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: _primaryGreen),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildPromotionList(provider, 'pending'),
                _buildPromotionList(provider, 'active'),
                _buildPromotionList(provider, 'rejected'),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPromotions,
        backgroundColor: _primaryGreen,
        child: Icon(Icons.refresh_rounded),
      ),
    );
  }

  Widget _buildTabContent({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 4 : 8,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 16 : 18),
          SizedBox(width: isSmallScreen ? 4 : 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: isSmallScreen ? 4 : 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 4 : 6, 
              vertical: 2
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12, 
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionList(EntrepreneurshipProvider provider, String type) {
    List<SmallBusinessPromotion> filteredPromotions;
    
    switch (type) {
      case 'pending':
        filteredPromotions = provider.businessPromotions
            .where((p) => !p.isVerified && !p.isDeleted && p.isActive)
            .toList();
        break;
      case 'active':
        filteredPromotions = provider.businessPromotions
            .where((p) => p.isVerified && !p.isDeleted && p.isActive)
            .toList();
        break;
      case 'rejected':
        filteredPromotions = provider.businessPromotions
            .where((p) => p.isDeleted || !p.isActive)
            .toList();
        break;
      default:
        filteredPromotions = [];
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredPromotions = filteredPromotions.where((promo) {
        return promo.businessName.toLowerCase().contains(_searchQuery) ||
               promo.ownerName.toLowerCase().contains(_searchQuery) ||
               promo.description.toLowerCase().contains(_searchQuery) ||
               promo.city.toLowerCase().contains(_searchQuery) ||
               promo.state.toLowerCase().contains(_searchQuery) ||
               promo.location.toLowerCase().contains(_searchQuery) ||
               promo.businessTags.any((tag) => tag.toLowerCase().contains(_searchQuery));
      }).toList();
    }

    // Sort by date (newest first) and featured first
    filteredPromotions.sort((a, b) {
      if (a.isFeatured && !b.isFeatured) return -1;
      if (!a.isFeatured && b.isFeatured) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    if (filteredPromotions.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty 
            ? 'No matching results found'
            : type == 'pending' 
                ? 'No pending promotions' 
                : type == 'active' 
                    ? 'No active promotions' 
                    : 'No rejected promotions',
        type == 'pending' ? Icons.pending_actions_rounded :
        type == 'active' ? Icons.storefront_rounded : Icons.block_rounded,
        hasSearch: _searchQuery.isNotEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPromotions,
      color: _primaryGreen,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredPromotions.length,
        itemBuilder: (context, index) {
          return _buildPromotionCard(filteredPromotions[index], type);
        },
      ),
    );
  }

  Widget _buildPromotionCard(SmallBusinessPromotion promotion, String type) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final imageBytes = promotion.logoImageBase64 != null && promotion.logoImageBase64!.isNotEmpty
        ? _base64ToImage(promotion.logoImageBase64!)
        : null;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: promotion.isFeatured && type == 'active'
              ? Border.all(color: Colors.amber, width: 2)
              : null,
        ),
        child: InkWell(
          onTap: () => _showPromotionDetails(promotion, type),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Container(
                      width: isSmallScreen ? 60 : 70,
                      height: isSmallScreen ? 60 : 70,
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: imageBytes != null && imageBytes.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                imageBytes,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.storefront_rounded,
                                    color: _getTypeColor(type),
                                    size: isSmallScreen ? 30 : 35,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.storefront_rounded,
                              color: _getTypeColor(type),
                              size: isSmallScreen ? 30 : 35,
                            ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    
                    // Business Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  promotion.businessName,
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (promotion.isFeatured && type == 'active')
                                Container(
                                  margin: EdgeInsets.only(left: 8),
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'FEATURED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 8 : 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            promotion.ownerName,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: _primaryGreen,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            promotion.location,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: isSmallScreen ? 8 : 12),
                
                // Description
                Text(
                  promotion.description.length > (isSmallScreen ? 80 : 100)
                      ? '${promotion.description.substring(0, isSmallScreen ? 80 : 100)}...'
                      : promotion.description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: isSmallScreen ? 8 : 12),
                
                // Info Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildInfoChip(
                      Icons.location_on_rounded, 
                      isSmallScreen ? promotion.city : '${promotion.city}, ${promotion.state}',
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.visibility_rounded, 
                      '${promotion.totalViews} views',
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.share_rounded, 
                      '${promotion.totalShares} shares',
                      isSmallScreen: isSmallScreen,
                    ),
                    if (promotion.specialOfferDiscount != null && promotion.specialOfferDiscount! > 0)
                      _buildInfoChip(
                        Icons.local_offer_rounded,
                        '${promotion.specialOfferDiscount}% OFF',
                        color: Colors.red,
                        isSmallScreen: isSmallScreen,
                      ),
                  ],
                ),
                
                SizedBox(height: isSmallScreen ? 6 : 8),
                
                // Posted By and Status Row
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_rounded, size: isSmallScreen ? 10 : 12, color: Colors.blue[700]),
                          SizedBox(width: 4),
                          Text(
                            'Posted by: ${promotion.createdBy}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 10,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(promotion, type, isSmallScreen: isSmallScreen),
                  ],
                ),
                
                // Admin Actions based on type
                _buildActionButtons(promotion, type, isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(SmallBusinessPromotion promotion, String type, bool isSmallScreen) {
    if (type == 'pending') {
      return Column(
        children: [
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showVerificationDialog(promotion),
                  icon: Icon(Icons.check_circle_rounded, size: isSmallScreen ? 14 : 18),
                  label: Text(
                    'Verify',
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectionDialog(promotion),
                  icon: Icon(Icons.block_rounded, size: isSmallScreen ? 14 : 18),
                  label: Text(
                    'Reject',
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (type == 'active') {
      return Column(
        children: [
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _toggleFeatured(promotion),
                  icon: Icon(
                    promotion.isFeatured ? Icons.star_rounded : Icons.star_border_rounded,
                    size: isSmallScreen ? 14 : 18,
                  ),
                  label: Text(
                    promotion.isFeatured ? 'Remove\nFeatured' : 'Mark\nFeatured',
                    style: TextStyle(fontSize: isSmallScreen ? 9 : 12),
                    textAlign: TextAlign.center,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    side: BorderSide(color: Colors.amber),
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deactivatePromotion(promotion),
                  icon: Icon(Icons.pause_circle_rounded, size: isSmallScreen ? 14 : 18),
                  label: Text(
                    'Deactivate',
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: BorderSide(color: Colors.orange),
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (promotion.specialOfferDiscount != null && promotion.specialOfferDiscount! > 0) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer_rounded, color: Colors.red, size: isSmallScreen ? 14 : 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      promotion.formattedOffer,
                      style: TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 11 : 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    } else if (type == 'rejected') {
      return Column(
        children: [
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _restorePromotion(promotion),
                  icon: Icon(Icons.restore_rounded, size: isSmallScreen ? 14 : 18),
                  label: Text(
                    'Restore',
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue),
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _permanentDeletePromotion(promotion),
               
                  icon: Icon(Icons.delete_forever_rounded, size: isSmallScreen ? 14 : 18),
                  label: Text(
                    'Delete\nPermanently',
                    style: TextStyle(fontSize: isSmallScreen ? 9 : 12),
                    textAlign: TextAlign.center,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color, required bool isSmallScreen}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 10 : 12, color: color ?? Colors.grey[600]),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: isSmallScreen ? 9 : 11, color: color ?? Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(SmallBusinessPromotion promotion, String type, {required bool isSmallScreen}) {
    Color color;
    String text;
    IconData icon;

    switch (type) {
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        icon = Icons.pending_rounded;
        break;
      case 'active':
        color = Colors.green;
        text = 'Verified';
        icon = Icons.verified_rounded;
        break;
      case 'rejected':
        if (promotion.isDeleted) {
          color = Colors.red;
          text = 'Deleted';
          icon = Icons.delete_rounded;
        } else {
          color = Colors.grey;
          text = 'Inactive';
          icon = Icons.block_rounded;
        }
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
        icon = Icons.help_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 10 : 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: isSmallScreen ? 9 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState(String message, IconData icon, {bool hasSearch = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (hasSearch) ...[
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              child: Text('Clear Search'),
            ),
          ] else ...[
            SizedBox(height: 8),
            Text(
              'Pull down to refresh',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Uint8List _base64ToImage(String base64String) {
    try {
      String cleaned = base64String.trim();
      if (cleaned.contains('base64,')) {
        cleaned = cleaned.split('base64,').last;
      }
      cleaned = cleaned.replaceAll(RegExp(r'\s'), '');
      if (cleaned.length % 4 != 0) {
        cleaned = cleaned.padRight(cleaned.length + (4 - cleaned.length % 4), '=');
      }
      return base64Decode(cleaned);
    } catch (e) {
      print('Error decoding base64: $e');
      return Uint8List(0);
    }
  }

  void _showPromotionDetails(SmallBusinessPromotion promotion, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AdminPromotionDetailsSheet(
        promotion: promotion,
        type: type,
        onStatusChanged: _loadPromotions,
        primaryGreen: _primaryGreen,
      ),
    );
  }

  void _showVerificationDialog(SmallBusinessPromotion promotion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify Promotion'),
        content: Text('Are you sure you want to verify "${promotion.businessName}"? This will make it visible to all users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyPromotion(promotion);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(SmallBusinessPromotion promotion) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Promotion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject "${promotion.businessName}"?'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Rejection Reason (Optional)',
                hintText: 'Provide a reason for rejection',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectPromotion(promotion, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _verifyPromotion(SmallBusinessPromotion promotion) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedPromotion = SmallBusinessPromotion(
      id: promotion.id,
      businessName: promotion.businessName,
      ownerName: promotion.ownerName,
      description: promotion.description,
      uniqueSellingPoints: promotion.uniqueSellingPoints,
      productsServices: promotion.productsServices,
      targetAudience: promotion.targetAudience,
      location: promotion.location,
      state: promotion.state,
      city: promotion.city,
      contactEmail: promotion.contactEmail,
      contactPhone: promotion.contactPhone,
      website: promotion.website,
      socialMediaLinks: promotion.socialMediaLinks,
      promoVideoLink: promotion.promoVideoLink,
      logoImageBase64: promotion.logoImageBase64,
      galleryImagesBase64: promotion.galleryImagesBase64,
      businessHours: promotion.businessHours,
      specialOfferDiscount: promotion.specialOfferDiscount,
      offerValidity: promotion.offerValidity,
      paymentMethods: promotion.paymentMethods,
      isVerified: true,
      isActive: true,
      isDeleted: false,
      isFeatured: promotion.isFeatured,
      totalViews: promotion.totalViews,
      totalShares: promotion.totalShares,
      createdBy: promotion.createdBy,
      createdAt: promotion.createdAt,
      updatedAt: DateTime.now(),
      category: promotion.category,
      businessTags: promotion.businessTags,
    );

    final success = await provider.updateBusinessPromotion(promotion.id!, updatedPromotion);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${promotion.businessName} verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPromotions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify promotion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectPromotion(SmallBusinessPromotion promotion, String reason) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedPromotion = SmallBusinessPromotion(
      id: promotion.id,
      businessName: promotion.businessName,
      ownerName: promotion.ownerName,
      description: promotion.description,
      uniqueSellingPoints: promotion.uniqueSellingPoints,
      productsServices: promotion.productsServices,
      targetAudience: promotion.targetAudience,
      location: promotion.location,
      state: promotion.state,
      city: promotion.city,
      contactEmail: promotion.contactEmail,
      contactPhone: promotion.contactPhone,
      website: promotion.website,
      socialMediaLinks: promotion.socialMediaLinks,
      promoVideoLink: promotion.promoVideoLink,
      logoImageBase64: promotion.logoImageBase64,
      galleryImagesBase64: promotion.galleryImagesBase64,
      businessHours: promotion.businessHours,
      specialOfferDiscount: promotion.specialOfferDiscount,
      offerValidity: promotion.offerValidity,
      paymentMethods: promotion.paymentMethods,
      isVerified: false,
      isActive: false,
      isDeleted: true,
      isFeatured: promotion.isFeatured,
      totalViews: promotion.totalViews,
      totalShares: promotion.totalShares,
      createdBy: promotion.createdBy,
      createdAt: promotion.createdAt,
      updatedAt: DateTime.now(),
      category: promotion.category,
      businessTags: promotion.businessTags,
    );

    final success = await provider.updateBusinessPromotion(promotion.id!, updatedPromotion);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${promotion.businessName} rejected${reason.isNotEmpty ? ': $reason' : ''}'),
            backgroundColor: Colors.red,
          ),
        );
        _loadPromotions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject promotion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleFeatured(SmallBusinessPromotion promotion) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedPromotion = SmallBusinessPromotion(
      id: promotion.id,
      businessName: promotion.businessName,
      ownerName: promotion.ownerName,
      description: promotion.description,
      uniqueSellingPoints: promotion.uniqueSellingPoints,
      productsServices: promotion.productsServices,
      targetAudience: promotion.targetAudience,
      location: promotion.location,
      state: promotion.state,
      city: promotion.city,
      contactEmail: promotion.contactEmail,
      contactPhone: promotion.contactPhone,
      website: promotion.website,
      socialMediaLinks: promotion.socialMediaLinks,
      promoVideoLink: promotion.promoVideoLink,
      logoImageBase64: promotion.logoImageBase64,
      galleryImagesBase64: promotion.galleryImagesBase64,
      businessHours: promotion.businessHours,
      specialOfferDiscount: promotion.specialOfferDiscount,
      offerValidity: promotion.offerValidity,
      paymentMethods: promotion.paymentMethods,
      isVerified: promotion.isVerified,
      isActive: promotion.isActive,
      isDeleted: promotion.isDeleted,
      isFeatured: !promotion.isFeatured,
      totalViews: promotion.totalViews,
      totalShares: promotion.totalShares,
      createdBy: promotion.createdBy,
      createdAt: promotion.createdAt,
      updatedAt: DateTime.now(),
      category: promotion.category,
      businessTags: promotion.businessTags,
    );

    final success = await provider.updateBusinessPromotion(promotion.id!, updatedPromotion);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(promotion.isFeatured 
                ? 'Removed from featured' 
                : 'Marked as featured'),
            backgroundColor: Colors.amber,
          ),
        );
        _loadPromotions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update featured status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deactivatePromotion(SmallBusinessPromotion promotion) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedPromotion = SmallBusinessPromotion(
      id: promotion.id,
      businessName: promotion.businessName,
      ownerName: promotion.ownerName,
      description: promotion.description,
      uniqueSellingPoints: promotion.uniqueSellingPoints,
      productsServices: promotion.productsServices,
      targetAudience: promotion.targetAudience,
      location: promotion.location,
      state: promotion.state,
      city: promotion.city,
      contactEmail: promotion.contactEmail,
      contactPhone: promotion.contactPhone,
      website: promotion.website,
      socialMediaLinks: promotion.socialMediaLinks,
      promoVideoLink: promotion.promoVideoLink,
      logoImageBase64: promotion.logoImageBase64,
      galleryImagesBase64: promotion.galleryImagesBase64,
      businessHours: promotion.businessHours,
      specialOfferDiscount: promotion.specialOfferDiscount,
      offerValidity: promotion.offerValidity,
      paymentMethods: promotion.paymentMethods,
      isVerified: promotion.isVerified,
      isActive: false,
      isDeleted: false,
      isFeatured: promotion.isFeatured,
      totalViews: promotion.totalViews,
      totalShares: promotion.totalShares,
      createdBy: promotion.createdBy,
      createdAt: promotion.createdAt,
      updatedAt: DateTime.now(),
      category: promotion.category,
      businessTags: promotion.businessTags,
    );

    final success = await provider.updateBusinessPromotion(promotion.id!, updatedPromotion);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${promotion.businessName} deactivated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadPromotions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deactivate promotion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _restorePromotion(SmallBusinessPromotion promotion) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedPromotion = SmallBusinessPromotion(
      id: promotion.id,
      businessName: promotion.businessName,
      ownerName: promotion.ownerName,
      description: promotion.description,
      uniqueSellingPoints: promotion.uniqueSellingPoints,
      productsServices: promotion.productsServices,
      targetAudience: promotion.targetAudience,
      location: promotion.location,
      state: promotion.state,
      city: promotion.city,
      contactEmail: promotion.contactEmail,
      contactPhone: promotion.contactPhone,
      website: promotion.website,
      socialMediaLinks: promotion.socialMediaLinks,
      promoVideoLink: promotion.promoVideoLink,
      logoImageBase64: promotion.logoImageBase64,
      galleryImagesBase64: promotion.galleryImagesBase64,
      businessHours: promotion.businessHours,
      specialOfferDiscount: promotion.specialOfferDiscount,
      offerValidity: promotion.offerValidity,
      paymentMethods: promotion.paymentMethods,
      isVerified: false,
      isActive: true,
      isDeleted: false,
      isFeatured: promotion.isFeatured,
      totalViews: promotion.totalViews,
      totalShares: promotion.totalShares,
      createdBy: promotion.createdBy,
      createdAt: promotion.createdAt,
      updatedAt: DateTime.now(),
      category: promotion.category,
      businessTags: promotion.businessTags,
    );

    final success = await provider.updateBusinessPromotion(promotion.id!, updatedPromotion);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${promotion.businessName} restored to pending'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPromotions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore promotion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

/*  void _permanentDeletePromotion(SmallBusinessPromotion promotion) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanently Delete'),
        content: Text(
          'Are you sure you want to permanently delete "${promotion.businessName}"? '
          'This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    // Implement permanent delete method in your provider
    final success = await provider.permanentDeleteBusinessPromotion(promotion.id!);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promotion permanently deleted'),
            backgroundColor: Colors.red,
          ),
        );
        _loadPromotions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to permanently delete promotion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }  */
}

class AdminPromotionDetailsSheet extends StatelessWidget {
  final SmallBusinessPromotion promotion;
  final String type;
  final VoidCallback onStatusChanged;
  final Color primaryGreen;

  const AdminPromotionDetailsSheet({
    Key? key,
    required this.promotion,
    required this.type,
    required this.onStatusChanged,
    required this.primaryGreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isTablet = screenSize.width >= 600;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        initialChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Promotion Details',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.w600,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1, thickness: 1),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  children: [
                    // Header with business info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Container(
                          width: isTablet ? 100 : 80,
                          height: isTablet ? 100 : 80,
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: promotion.logoImageBase64 != null && promotion.logoImageBase64!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    _base64ToImage(promotion.logoImageBase64!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.storefront_rounded,
                                        size: isTablet ? 50 : 40,
                                        color: primaryGreen,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.storefront_rounded,
                                  size: isTablet ? 50 : 40,
                                  color: primaryGreen,
                                ),
                        ),
                        SizedBox(width: isTablet ? 20 : 16),
                        
                        // Business Name and Owner
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                promotion.businessName,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 24 : 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                promotion.ownerName,
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildDetailStatusChip(isTablet: isTablet),
                                  if (promotion.isFeatured)
                                    _buildFeaturedChip(isTablet: isTablet),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Quick Stats
                    Container(
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(Icons.visibility_rounded, 'Views', promotion.totalViews.toString(), isTablet: isTablet),
                          _buildStatItem(Icons.share_rounded, 'Shares', promotion.totalShares.toString(), isTablet: isTablet),
                          _buildStatItem(Icons.access_time_rounded, 'Posted', _formatTimeAgo(promotion.createdAt), isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 28 : 24),
                    
                    // Description
                    _buildSectionTitle('Description', Icons.description_rounded, Colors.blue, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Text(
                        promotion.description,
                        style: TextStyle(fontSize: isTablet ? 16 : 15, height: 1.5),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Unique Selling Points
                    _buildSectionTitle('Unique Selling Points', Icons.star_rounded, Colors.purple, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Text(
                        promotion.uniqueSellingPoints,
                        style: TextStyle(fontSize: isTablet ? 16 : 15, height: 1.5),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Target Audience
                    _buildSectionTitle('Target Audience', Icons.people_rounded, Colors.orange, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Text(
                        promotion.targetAudience,
                        style: TextStyle(fontSize: isTablet ? 16 : 15, height: 1.5),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Location
                    _buildSectionTitle('Location', Icons.location_on_rounded, Colors.red, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(promotion.location, style: TextStyle(fontSize: isTablet ? 16 : 15)),
                          SizedBox(height: 4),
                          Text(
                            '${promotion.city}, ${promotion.state}',
                            style: TextStyle(fontSize: isTablet ? 16 : 15),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Contact Information
                    _buildSectionTitle('Contact Information', Icons.contact_phone_rounded, primaryGreen, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildContactInfo(Icons.phone_rounded, promotion.contactPhone, isLink: true, isTablet: isTablet),
                          const Divider(height: 16),
                          _buildContactInfo(Icons.email_rounded, promotion.contactEmail, isLink: true, isTablet: isTablet),
                          if (promotion.website != null && promotion.website!.isNotEmpty) ...[
                            const Divider(height: 16),
                            _buildContactInfo(Icons.language_rounded, promotion.website!, isLink: true, isTablet: isTablet),
                          ],
                        ],
                      ),
                    ),
                    
                    // Products & Services
                    if (promotion.productsServices.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Products & Services', Icons.shopping_bag_rounded, Colors.green, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: promotion.productsServices.map((product) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12, 
                                vertical: isTablet ? 8 : 6
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                product,
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 13,
                                  color: Colors.green[800],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    // Business Hours
                    if (promotion.businessHours.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Business Hours', Icons.schedule_rounded, Colors.orange, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: promotion.businessHours.map((hour) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: isTablet ? 16 : 14, color: Colors.orange[700]),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      hour,
                                      style: TextStyle(fontSize: isTablet ? 15 : 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    // Payment Methods
                    if (promotion.paymentMethods.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Payment Methods', Icons.payment_rounded, Colors.teal, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: promotion.paymentMethods.map((method) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12, 
                                vertical: isTablet ? 8 : 6
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                method,
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 13,
                                  color: Colors.teal[800],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    // Business Tags
                    if (promotion.businessTags.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Business Tags', Icons.tag_rounded, Colors.blue, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: promotion.businessTags.map((tag) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12, 
                                vertical: isTablet ? 8 : 6
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 13,
                                  color: Colors.blue[800],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    // Special Offer
                    if (promotion.specialOfferDiscount != null && promotion.specialOfferDiscount! > 0) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Special Offer', Icons.local_offer_rounded, Colors.red, isTablet: isTablet),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(isTablet ? 20 : 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.percent_rounded, color: Colors.red, size: isTablet ? 24 : 20),
                                SizedBox(width: 8),
                                Text(
                                  '${promotion.specialOfferDiscount}% OFF',
                                  style: TextStyle(
                                    fontSize: isTablet ? 20 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[800],
                                  ),
                                ),
                              ],
                            ),
                            if (promotion.offerValidity != null && promotion.offerValidity!.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: isTablet ? 18 : 16, color: Colors.red[700]),
                                  SizedBox(width: 8),
                                  Text(
                                    'Valid until: ${promotion.offerValidity}',
                                    style: TextStyle(
                                      fontSize: isTablet ? 15 : 14,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    
                    // Gallery Images
                    if (promotion.galleryImagesBase64 != null && promotion.galleryImagesBase64!.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Gallery', Icons.image_rounded, Colors.purple, isTablet: isTablet),
                      SizedBox(height: 8),
                      SizedBox(
                        height: isTablet ? 120 : 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: promotion.galleryImagesBase64!.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: isTablet ? 120 : 100,
                              height: isTablet ? 120 : 100,
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: MemoryImage(
                                    _base64ToImage(promotion.galleryImagesBase64![index]),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    
                    // Promo Video
                    if (promotion.promoVideoLink != null && promotion.promoVideoLink!.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Promo Video', Icons.video_library_rounded, Colors.red, isTablet: isTablet),
                      SizedBox(height: 8),
                      InkWell(
                        onTap: () => _launchUrl(promotion.promoVideoLink!),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 20 : 16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.play_circle_rounded, color: Colors.red, size: isTablet ? 50 : 40),
                              SizedBox(width: isTablet ? 16 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Watch Promo Video',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red[800],
                                        fontSize: isTablet ? 16 : 14,
                                      ),
                                    ),
                                    Text(
                                      promotion.promoVideoLink!,
                                      style: TextStyle(
                                        fontSize: isTablet ? 14 : 12,
                                        color: Colors.red[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.open_in_new_rounded, color: Colors.red, size: isTablet ? 20 : 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Timestamps
                    _buildSectionTitle('Timestamps', Icons.access_time_rounded, Colors.grey, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildInfoRow('Posted By', promotion.createdBy, isTablet: isTablet),
                          _buildInfoRow('Created', _formatDateTime(promotion.createdAt), isTablet: isTablet),
                          _buildInfoRow('Updated', _formatDateTime(promotion.updatedAt), isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 28 : 24),
                    
                    // Admin Actions based on type
                    _buildDetailsActionButtons(context, isTablet),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailsActionButtons(BuildContext context, bool isTablet) {
    if (type == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Trigger rejection from parent
              },
              icon: Icon(Icons.block_rounded, size: isTablet ? 20 : 18),
              label: Text(
                'Reject',
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Trigger verification from parent
              },
              icon: Icon(Icons.check_circle_rounded, size: isTablet ? 20 : 18),
              label: Text(
                'Verify',
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (type == 'active') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Toggle featured from parent
              },
              icon: Icon(promotion.isFeatured ? Icons.star_rounded : Icons.star_border_rounded, size: isTablet ? 20 : 18),
              label: Text(
                promotion.isFeatured ? 'Remove Featured' : 'Mark Featured',
                style: TextStyle(fontSize: isTablet ? 14 : 12),
                textAlign: TextAlign.center,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber,
                side: const BorderSide(color: Colors.amber),
                padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Trigger deactivation from parent
              },
              icon: Icon(Icons.pause_circle_rounded, size: isTablet ? 20 : 18),
              label: Text(
                'Deactivate',
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (type == 'rejected') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Trigger restore from parent
              },
              icon: Icon(Icons.restore_rounded, size: isTablet ? 20 : 18),
              label: Text(
                'Restore',
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDetailStatusChip({required bool isTablet}) {
    Color color;
    String text;
    IconData icon;

    if (!promotion.isVerified && !promotion.isDeleted && promotion.isActive) {
      color = Colors.orange;
      text = 'Pending';
      icon = Icons.pending_rounded;
    } else if (promotion.isVerified && !promotion.isDeleted && promotion.isActive) {
      color = Colors.green;
      text = 'Verified';
      icon = Icons.verified_rounded;
    } else if (promotion.isDeleted) {
      color = Colors.red;
      text = 'Deleted';
      icon = Icons.delete_rounded;
    } else {
      color = Colors.grey;
      text = 'Inactive';
      icon = Icons.block_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 12, 
        vertical: isTablet ? 8 : 6
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isTablet ? 16 : 14, color: color),
          SizedBox(width: isTablet ? 6 : 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedChip({required bool isTablet}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 12, 
        vertical: isTablet ? 8 : 6
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: isTablet ? 16 : 14, color: Colors.amber),
          SizedBox(width: isTablet ? 6 : 4),
          Text(
            'Featured',
            style: TextStyle(
              color: Colors.amber,
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, {required bool isTablet}) {
    return Column(
      children: [
        Icon(icon, color: primaryGreen, size: isTablet ? 26 : 22),
        SizedBox(height: isTablet ? 6 : 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 20 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 13 : 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color, {required bool isTablet}) {
    return Row(
      children: [
        Icon(icon, color: color, size: isTablet ? 24 : 20),
        SizedBox(width: isTablet ? 10 : 8),
        Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 20 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value, {required bool isTablet}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isTablet ? 100 : 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: isTablet ? 14 : 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 15 : 14, 
                color: Colors.grey[800]
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String value, {bool isLink = false, required bool isTablet}) {
    return InkWell(
      onTap: isLink ? () => _launchUrl(value) : null,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, size: isTablet ? 20 : 18, color: Colors.grey[600]),
          SizedBox(width: isTablet ? 14 : 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: isLink ? primaryGreen : Colors.grey[800],
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
          if (isLink)
            Icon(Icons.open_in_new_rounded, size: isTablet ? 18 : 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Uint8List _base64ToImage(String base64String) {
    try {
      String cleaned = base64String.trim();
      if (cleaned.contains('base64,')) {
        cleaned = cleaned.split('base64,').last;
      }
      cleaned = cleaned.replaceAll(RegExp(r'\s'), '');
      if (cleaned.length % 4 != 0) {
        cleaned = cleaned.padRight(cleaned.length + (4 - cleaned.length % 4), '=');
      }
      return base64Decode(cleaned);
    } catch (e) {
      print('Error decoding base64: $e');
      return Uint8List(0);
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}