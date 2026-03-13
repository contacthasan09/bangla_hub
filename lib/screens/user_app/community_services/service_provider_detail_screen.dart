import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/service_provider_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceProviderDetailScreen extends StatefulWidget {
  final String providerId;

  const ServiceProviderDetailScreen({super.key, required this.providerId});

  @override
  State<ServiceProviderDetailScreen> createState() => _ServiceProviderDetailScreenState();
}

class _ServiceProviderDetailScreenState extends State<ServiceProviderDetailScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Premium Color Palette - Light Green Background (50%)
  final Color _primaryRed = const Color(0xFFD32F2F);
  final Color _primaryGreen = const Color(0xFF2E7D32);
  final Color _darkGreen = const Color(0xFF1B5E20);
  final Color _goldAccent = const Color(0xFFFFB300);
  
  // Dark button colors
  final Color _coralRed = const Color(0xFFC62828);
  final Color _mintGreen = const Color(0xFF2E7D32);
  final Color _softGold = const Color(0xFFFF8F00);
  final Color _emeraldGreen = const Color(0xFF1B5E20);
  final Color _sapphireBlue = const Color(0xFF1565C0);
  final Color _amethystPurple = const Color(0xFF6A1B9A);
  final Color _deepRed = const Color(0xFFB71C1C);
  
  // Light Green Background (50% opacity)
  final Color _lightGreenBg = const Color(0x80E8F5E9);
  final Color _creamWhite = const Color(0xFFFFF9E6);
  final Color _lightGreen = const Color(0xFFE8F5E9);
  final Color _lightRed = const Color(0xFFFFEBEE);
  final Color _lightYellow = const Color(0xFFFFF3E0);
  final Color _lightBlue = const Color(0xFFE3F2FD);
  
  // 50% opacity colors for backgrounds
  final Color _creamWhite50 = const Color(0x80FFF9E6);
  final Color _lightGreen50 = const Color(0x80E8F5E9);
  final Color _lightRed50 = const Color(0x80FFEBEE);
  final Color _lightYellow50 = const Color(0x80FFF3E0);
  final Color _lightBlue50 = const Color(0x80E3F2FD);
  
  // Border and shadow colors
  final Color _borderLight = const Color(0xFFE0E7E9);
  final Color _shadowColor = const Color(0x1A000000);
  
  // Text Colors
  final Color _textPrimary = const Color(0xFF1A2B3C);
  final Color _textSecondary = const Color(0xFF5D6D7E);
  final Color _textLight = const Color(0xFF6C757D);
  
  // Additional colors
  final Color _successGreen = const Color(0xFF2E7D32);
  final Color _infoBlue = const Color(0xFF1565C0);
  final Color _badgeGold = const Color(0xFFFF8F00);
  
  bool _isLiked = false;
  bool _isLoading = false;
  bool _isGeneratingPDF = false;
  bool _isFollowing = false;
  int _likeCount = 0;
  String? _userId;
  
  // Animation Controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;
  
  // Particle animation controllers
  late List<AnimationController> _particleControllers;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<ServiceProviderModel?>? _providerSubscription;
  
  // Cache for expensive operations
  final Map<String, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    
    print('🚀 ServiceProviderDetailScreen initState called for ID: ${widget.providerId}');
    
    // ✅ Add WidgetsBindingObserver
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animations
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _rotateAnimation = CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    );
    
    // Initialize particle controllers
    _particleControllers = List.generate(10, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: 3 + (index % 3)),
      )..repeat(reverse: true);
    });
    
    // Get user ID
    _userId = context.read<AuthProvider>().user?.id;
    
    // Load provider details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
      provider.getProviderById(widget.providerId);
      _subscribeToProviderUpdates(provider);
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
    
    if (state == AppLifecycleState.resumed) {
      // App is visible - start animations
      _startAnimations();
    } else {
      // App is not visible - stop animations to save resources
      _stopAnimations();
    }
  }
  
  void _startAnimations() {
    if (_appLifecycleState == AppLifecycleState.resumed && mounted) {
      _pulseController.repeat(reverse: true);
      _rotateController.repeat();
      // Particle controllers already running via repeat
    }
  }
  
  void _stopAnimations() {
    _pulseController.stop();
    _rotateController.stop();
    // Particle controllers will continue but we don't stop them as they're repetitive
  }

  void _subscribeToProviderUpdates(ServiceProviderProvider provider) {
    _providerSubscription?.cancel();
    _providerSubscription = provider.selectedProviderStream.listen((serviceProvider) {
      if (serviceProvider != null && mounted) {
        setState(() {
          _likeCount = serviceProvider.totalLikes;
          _isLiked = serviceProvider.isLikedByUser(_userId ?? '');
        });
      }
    });
  }

  Future<void> _toggleLike() async {
    final authProvider = context.read<AuthProvider>();
    final serviceProviderProvider = context.read<ServiceProviderProvider>();
    
    if (authProvider.user == null) {
      _showPremiumSnackBar('Please login to like services ❤️', isError: true);
      return;
    }
    
    setState(() {
      _isLoading = true;
      // Optimistic update
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    
    try {
      await serviceProviderProvider.toggleLike(
        widget.providerId,
        authProvider.user!.id,
      );
    } catch (e) {
      print('❌ Error toggling like: $e');
      // Revert optimistic update on error
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
      _showPremiumSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPremiumSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isError 
                  ? [_primaryRed, _coralRed] 
                  : [_primaryGreen, _darkGreen],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      String finalNumber;
      
      if (cleanedNumber.startsWith('+1')) {
        finalNumber = cleanedNumber;
      } else if (cleanedNumber.startsWith('1') && cleanedNumber.length == 11) {
        finalNumber = '+$cleanedNumber';
      } else if (cleanedNumber.length == 10) {
        finalNumber = '+1$cleanedNumber';
      } else if (cleanedNumber.length == 11 && cleanedNumber.startsWith('0')) {
        finalNumber = '+1${cleanedNumber.substring(1)}';
      } else {
        finalNumber = '+1$cleanedNumber';
      }
      
      finalNumber = finalNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      final Uri uri = Uri(scheme: 'tel', path: finalNumber);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
      
      final String urlString = 'tel:$finalNumber';
      final Uri fallbackUri = Uri.parse(urlString);
      
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri);
        return;
      }
      
      if (Platform.isIOS) {
        final String telPromptUrl = 'telprompt:$finalNumber';
        final Uri telPromptUri = Uri.parse(telPromptUrl);
        
        if (await canLaunchUrl(telPromptUri)) {
          await launchUrl(telPromptUri);
          return;
        }
      }
      
      await Clipboard.setData(ClipboardData(text: finalNumber));
      _showPremiumSnackBar('📱 Phone number copied to clipboard');
      
    } catch (e) {
      print('❌ Phone call error: $e');
      _showPremiumSnackBar('Error making phone call. Please try dialing manually.', isError: true);
    }
  }

  Future<void> _sendEmail(String email) async {
    try {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(email)) {
        _showPremiumSnackBar('Invalid email format', isError: true);
        return;
      }
      
      final Uri uri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          'subject': 'Service Inquiry from Bangla Hub',
          'body': 'Dear Service Provider,\n\nI found your profile on Bangla Hub and I am interested in your services.\n\nPlease contact me at your earliest convenience.\n\nBest regards,\nBangla Hub User',
        },
      );
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        _showPremiumSnackBar('✉️ Opening email app...');
      } else {
        await Clipboard.setData(ClipboardData(text: email));
        _showPremiumSnackBar('📧 Email copied to clipboard');
      }
    } catch (e) {
      print('Email error: $e');
      _showPremiumSnackBar('Error sending email: $e', isError: true);
    }
  }

  Future<void> _openWebsite(String url) async {
    try {
      if (url.isEmpty) {
        _showPremiumSnackBar('No website URL provided', isError: true);
        return;
      }
      
      String formattedUrl = url.trim();
      
      if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
        formattedUrl = 'https://$formattedUrl';
      }
      
      final Uri uri = Uri.parse(formattedUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
        _showPremiumSnackBar('🌐 Opening website...');
      } else {
        await Clipboard.setData(ClipboardData(text: formattedUrl));
        _showPremiumSnackBar('🔗 Website URL copied to clipboard');
      }
    } catch (e) {
      print('Website error: $e');
      _showPremiumSnackBar('Error opening website: $e', isError: true);
    }
  }

  Future<void> _openMap(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
      final appleMapsUrl = 'https://maps.apple.com/?q=$encodedAddress';
      
      final uri = Uri.parse(Platform.isIOS ? appleMapsUrl : googleMapsUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        _showPremiumSnackBar('🗺️ Opening maps...');
      } else {
        await Clipboard.setData(ClipboardData(text: address));
        _showPremiumSnackBar('📍 Address copied to clipboard');
      }
    } catch (e) {
      print('Map error: $e');
      _showPremiumSnackBar('Error opening maps', isError: true);
    }
  }

  Future<void> _generateAndSharePDF(ServiceProviderModel provider) async {
    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      final pdf = pw.Document();
      
      final font = await PdfGoogleFonts.nunitoRegular();
      final boldFont = await PdfGoogleFonts.nunitoBold();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Service Provider Details',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 24,
                        color: PdfColors.green800,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        'Bangla Hub',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 16,
                          color: PdfColors.green700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Provider Basic Info
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      provider.fullName,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 22,
                        color: PdfColors.red700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      provider.companyName,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: PdfColors.green700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: provider.isVerified ? PdfColors.green100 : PdfColors.grey100,
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          child: pw.Text(
                            provider.isVerified ? '✓ Verified' : 'Not Verified',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 12,
                              color: provider.isVerified ? PdfColors.green700 : PdfColors.grey700,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: provider.isAvailable ? PdfColors.green100 : PdfColors.red100,
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          child: pw.Text(
                            provider.isAvailable ? 'Available' : 'Not Available',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 12,
                              color: provider.isAvailable ? PdfColors.green700 : PdfColors.red700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Contact Information
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '📞 Contact Information',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: PdfColors.red700,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    _buildPDFInfoRow('Phone:', provider.phone, font, boldFont),
                    _buildPDFInfoRow('Email:', provider.email, font, boldFont),
                    _buildPDFInfoRow('Address:', provider.formattedAddress, font, boldFont),
                    if (provider.website != null && provider.website!.isNotEmpty)
                      _buildPDFInfoRow('Website:', provider.website!, font, boldFont),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Service Details
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '🔧 Service Details',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: PdfColors.red700,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    _buildPDFInfoRow('Category:', provider.serviceCategory.displayName, font, boldFont),
                    _buildPDFInfoRow('Service:', provider.serviceProvider, font, boldFont),
                    if (provider.subServiceProvider != null && provider.subServiceProvider!.isNotEmpty)
                      _buildPDFInfoRow('Sub-Service:', provider.subServiceProvider!, font, boldFont),
                    if (provider.yearsOfExperience != null && provider.yearsOfExperience!.isNotEmpty)
                      _buildPDFInfoRow('Experience:', provider.yearsOfExperience!, font, boldFont),
                    if (provider.consultationFee != null)
                      _buildPDFInfoRow('Fee:', '\$${provider.consultationFee!.toStringAsFixed(2)}', font, boldFont),
                  ],
                ),
              ),
              
              if (provider.description != null && provider.description!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '📝 About',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 18,
                          color: PdfColors.red700,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        provider.description!,
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
              
              if (provider.languagesSpoken.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '🗣️ Languages',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 18,
                          color: PdfColors.red700,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.languagesSpoken.map((language) {
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.green50,
                              borderRadius: pw.BorderRadius.circular(16),
                            ),
                            child: pw.Text(
                              language,
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 11,
                                color: PdfColors.green700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              
              if (provider.serviceTags.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '🏷️ Service Tags',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 18,
                          color: PdfColors.red700,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.serviceTags.map((tag) {
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.blue50,
                              borderRadius: pw.BorderRadius.circular(16),
                            ),
                            child: pw.Text(
                              tag,
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 11,
                                color: PdfColors.blue700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              
              pw.SizedBox(height: 30),
              
              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated on: ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Bangla Hub Services',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 12,
                      color: PdfColors.green700,
                    ),
                  ),
                ],
              ),
            ];
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/service_provider_${provider.id}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Service Provider Details - ${provider.fullName}',
        text: 'Check out this service provider from Bangla Hub!',
      );

      if (mounted) {
        _showPremiumSnackBar('✅ PDF generated and shared successfully!');
      }
    } catch (e) {
      print('PDF Generation Error: $e');
      if (mounted) {
        _showPremiumSnackBar('Error generating PDF: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPDF = false;
        });
      }
    }
  }

  pw.Widget _buildPDFInfoRow(String label, String value, pw.Font font, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: boldFont, fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumShareOptions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final provider = context.read<ServiceProviderProvider>().selectedProvider;
        if (provider == null) return const SizedBox();
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryGreen, _darkGreen, _primaryRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isTablet ? 40 : 30),
              topRight: Radius.circular(isTablet ? 40 : 30),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 32 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle Indicator
                Center(
                  child: Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_goldAccent, _primaryRed],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Premium Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: isTablet ? 56 : 48,
                      height: isTablet ? 56 : 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryRed, _primaryGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      ),
                      child: Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                        size: isTablet ? 28 : 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share Profile',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 26 : 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share this provider with friends',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        width: isTablet ? 48 : 40,
                        height: isTablet ? 48 : 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: isTablet ? 24 : 20,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: isTablet ? 32 : 24),
                
                // Share Options Grid
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  mainAxisSpacing: isTablet ? 20 : 15,
                  crossAxisSpacing: isTablet ? 20 : 15,
                  children: [
                    _buildPremiumShareOption(
                      icon: Icons.text_fields_rounded,
                      label: 'Text',
                      gradientColors: [_infoBlue, const Color(0xFF0D47A1)],
                      onTap: () {
                        Navigator.pop(context);
                        _shareAsText(provider);
                      },
                      isTablet: isTablet,
                    ),
                    
                    _buildPremiumShareOption(
                      icon: Icons.chat_rounded,
                      label: 'WhatsApp',
                      gradientColors: [const Color(0xFF1B5E20), const Color(0xFF0D3B1A)],
                      onTap: () {
                        Navigator.pop(context);
                        _shareToWhatsApp(provider);
                      },
                      isTablet: isTablet,
                    ),
                    
                    _buildPremiumShareOption(
                      icon: Icons.facebook_rounded,
                      label: 'Facebook',
                      gradientColors: [const Color(0xFF0D47A1), const Color(0xFF002171)],
                      onTap: () {
                        Navigator.pop(context);
                        _shareToFacebook(provider);
                      },
                      isTablet: isTablet,
                    ),
                    
                    _buildPremiumShareOption(
                      icon: Icons.copy_rounded,
                      label: 'Copy',
                      gradientColors: [_amethystPurple, const Color(0xFF4A148C)],
                      onTap: () async {
                        await _copyDetails(provider);
                        if (mounted) Navigator.pop(context);
                      },
                      isTablet: isTablet,
                    ),
                  ],
                ),
                
                SizedBox(height: isTablet ? 24 : 20),
                
                // PDF Share Option
                Container(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _generateAndSharePDF(provider);
                      },
                      borderRadius: BorderRadius.circular(isTablet ? 18 : 15),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 20,
                          vertical: isTablet ? 18 : 16,
                        ),
                        decoration: BoxDecoration(
                          gradient:  LinearGradient(
                            colors: [_primaryRed, _primaryGreen],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(isTablet ? 18 : 15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.white,
                              size: isTablet ? 24 : 20,
                            ),
                            SizedBox(width: isTablet ? 16 : 12),
                            Text(
                              'Share as PDF',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumShareOption({
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isTablet ? 48 : 40,
                height: isTablet ? 48 : 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: shouldAnimate
                      ? RotationTransition(
                          turns: _rotateAnimation,
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: isTablet ? 24 : 20,
                          ),
                        )
                      : Icon(
                          icon,
                          color: Colors.white,
                          size: isTablet ? 24 : 20,
                        ),
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareAsText(ServiceProviderModel provider) {
    final text = '''
╔══════════════════════════════╗
║    🎯 SERVICE PROVIDER       ║
╚══════════════════════════════╝

✨ ${provider.fullName}
🏢 ${provider.companyName}
📍 ${provider.formattedAddress}
📞 ${provider.phone}
📧 ${provider.email}

📋 Category: ${provider.serviceCategory.displayName}
🔧 Service: ${provider.serviceProvider}
${provider.subServiceProvider != null ? '🔩 Sub-Service: ${provider.subServiceProvider!}\n' : ''}

${provider.description != null && provider.description!.isNotEmpty ? '📝 About:\n${provider.description!}\n' : ''}

⭐ ${_formatCount(provider.totalLikes)} likes • ${provider.isVerified ? '✅ Verified' : ''} • ${provider.isAvailable ? '🟢 Available' : '🔴 Not Available'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━
Shared via Bangla Hub Services
Download the app today! 📱
''';
    
    Share.share(
      text,
      subject: 'Service Provider: ${provider.fullName}',
    ).then((result) {
      if (mounted) {
        _showPremiumSnackBar('✨ Shared successfully!');
      }
    });
  }

  Future<void> _shareToWhatsApp(ServiceProviderModel provider) async {
    final text = '''
*Check out this service provider on Bangla Hub!* 🎯

👤 *Name:* ${provider.fullName}
🏢 *Company:* ${provider.companyName}
📍 *Location:* ${provider.city}, ${provider.state}
📞 *Phone:* ${provider.phone}
📋 *Category:* ${provider.serviceCategory.displayName}
${provider.isVerified ? '✅ *Verified Provider*' : ''}

_Download Bangla Hub App for more details!_ 📱
''';
    
    final url = 'whatsapp://send?text=${Uri.encodeComponent(text)}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      if (mounted) {
        _showPremiumSnackBar('WhatsApp not installed 📱', isError: true);
      }
    }
  }

  Future<void> _shareToFacebook(ServiceProviderModel provider) async {
    final text = '''
🌟 Check out this amazing service provider on Bangla Hub!

👤 ${provider.fullName}
🏢 ${provider.companyName}
📍 ${provider.city}, ${provider.state}
📋 ${provider.serviceCategory.displayName}

Shared via Bangla Hub App. Download now! 📲
''';
    
    Share.share(
      text,
      subject: 'Bangla Hub Service Provider: ${provider.fullName}',
    ).then((result) {
      if (mounted) {
        _showPremiumSnackBar('✨ Shared to Facebook!');
      }
    });
  }

  Future<void> _copyDetails(ServiceProviderModel provider) async {
    final text = '''
📋 SERVICE PROVIDER DETAILS
━━━━━━━━━━━━━━━━━━━━━━━

👤 Name: ${provider.fullName}
🏢 Company: ${provider.companyName}
📍 Address: ${provider.formattedAddress}
📞 Phone: ${provider.phone}
📧 Email: ${provider.email}
📋 Category: ${provider.serviceCategory.displayName}
🔧 Provider: ${provider.serviceProvider}
${provider.subServiceProvider != null ? '🔩 Sub-Provider: ${provider.subServiceProvider!}\n' : ''}
${provider.website != null && provider.website!.isNotEmpty ? '🌐 Website: ${provider.website!}\n' : ''}
${provider.yearsOfExperience != null && provider.yearsOfExperience!.isNotEmpty ? '📅 Experience: ${provider.yearsOfExperience!}\n' : ''}
⭐ Rating: ${provider.rating?.toStringAsFixed(1) ?? '4.5'} (${provider.totalReviews} reviews)
❤️ Likes: ${_formatCount(provider.totalLikes)}

━━━━━━━━━━━━━━━━━━━━━━━
''';
    
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      _showPremiumSnackBar('📋 Details copied to clipboard!');
    }
  }

  @override
  void dispose() {
    print('🗑️ ServiceProviderDetailScreen disposing...');
    
    // ✅ Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    _scrollController.dispose();
    _providerSubscription?.cancel();
    
    // ✅ Dispose animation controllers
    _pulseController.dispose();
    _rotateController.dispose();
    
    // ✅ Dispose particle controllers
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  String _cleanBase64String(String base64) {
    String cleaned = base64.trim();
    if (cleaned.contains(',')) {
      cleaned = cleaned.split(',').last;
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s'), '');
    while (cleaned.length % 4 != 0) {
      cleaned += '=';
    }
    return cleaned;
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  Widget _buildBannerImage(ServiceProviderModel serviceProvider, bool isTablet) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    if (serviceProvider.profileImageBase64 != null && serviceProvider.profileImageBase64!.isNotEmpty) {
      try {
        final cleanedBase64 = _cleanBase64String(serviceProvider.profileImageBase64!);
        final bytes = base64Decode(cleanedBase64);
        return ClipRRect(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(isTablet ? 30 : 24),
          ),
          child: Image.memory(
            bytes,
            width: double.infinity,
            height: isTablet ? 300 : 250,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: isTablet ? 300 : 250,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_lightGreen50, _lightGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(isTablet ? 30 : 24),
                  ),
                ),
                child: Center(
                  child: shouldAnimate
                      ? RotationTransition(
                          turns: _rotateAnimation,
                          child: Icon(
                            Icons.person_rounded,
                            color: _primaryGreen,
                            size: isTablet ? 80 : 60,
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          color: _primaryGreen,
                          size: isTablet ? 80 : 60,
                        ),
                ),
              );
            },
          ),
        );
      } catch (e) {
        return Container(
          width: double.infinity,
          height: isTablet ? 300 : 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_lightGreen50, _lightGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(isTablet ? 30 : 24),
            ),
          ),
          child: Center(
            child: shouldAnimate
                ? RotationTransition(
                    turns: _rotateAnimation,
                    child: Icon(
                      Icons.person_rounded,
                      color: _primaryGreen,
                      size: isTablet ? 80 : 60,
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    color: _primaryGreen,
                    size: isTablet ? 80 : 60,
                  ),
          ),
        );
      }
    } else {
      return Container(
        width: double.infinity,
        height: isTablet ? 300 : 250,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_lightGreen50, _lightGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(isTablet ? 30 : 24),
          ),
        ),
        child: Center(
          child: shouldAnimate
              ? RotationTransition(
                  turns: _rotateAnimation,
                  child: Icon(
                    Icons.person_rounded,
                    color: _primaryGreen,
                    size: isTablet ? 80 : 60,
                  ),
                )
              : Icon(
                  Icons.person_rounded,
                  color: _primaryGreen,
                  size: isTablet ? 80 : 60,
                ),
        ),
      );
    }
  }

  Widget _buildPremiumDetailSection({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isTablet,
  }) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 8 : 6),
              decoration: BoxDecoration(
                gradient:  LinearGradient(
                  colors: [_primaryRed, _primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
              ),
              child: shouldAnimate
                  ? RotationTransition(
                      turns: _rotateAnimation,
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: isTablet ? 18 : 16,
                      ),
                    )
                  : Icon(
                      icon,
                      color: Colors.white,
                      size: isTablet ? 18 : 16,
                    ),
            ),
            SizedBox(width: isTablet ? 12 : 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 14),
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
    VoidCallback? onTap,
  }) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, _creamWhite],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            border: Border.all(color: gradientColors.first.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 5),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isTablet ? 48 : 42,
                height: isTablet ? 48 : 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: shouldAnimate
                      ? RotationTransition(
                          turns: _rotateAnimation,
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: isTablet ? 22 : 18,
                          ),
                        )
                      : Icon(
                          icon,
                          color: Colors.white,
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 15 : 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Container(
                  padding: EdgeInsets.all(isTablet ? 8 : 6),
                  decoration: BoxDecoration(
                    color: gradientColors.first.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: gradientColors.first,
                    size: isTablet ? 18 : 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumContactItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isTablet,
    VoidCallback? onTap,
  }) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 16 : 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, _creamWhite],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
            border: Border.all(color: _borderLight, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: isTablet ? 44 : 38,
                height: isTablet ? 44 : 38,
                decoration: BoxDecoration(
                  gradient: onTap != null 
                      ?  LinearGradient(colors: [_primaryRed, _primaryGreen])
                      : LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade300]),
                  borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                ),
                child: Center(
                  child: shouldAnimate
                      ? RotationTransition(
                          turns: _rotateAnimation,
                          child: Icon(
                            icon,
                            color: onTap != null ? Colors.white : Colors.grey.shade600,
                            size: isTablet ? 20 : 18,
                          ),
                        )
                      : Icon(
                          icon,
                          color: onTap != null ? Colors.white : Colors.grey.shade600,
                          size: isTablet ? 20 : 18,
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
                        fontSize: isTablet ? 13 : 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 15 : 14,
                        fontWeight: FontWeight.w600,
                        color: onTap != null ? _primaryGreen : _textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Container(
                  padding: EdgeInsets.all(isTablet ? 6 : 4),
                  decoration: BoxDecoration(
                    color: _primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: _primaryGreen,
                    size: isTablet ? 18 : 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipGrid(List<String> items, bool isTablet) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: isTablet ? 8 : 6,
      runSpacing: isTablet ? 8 : 6,
      children: items.map((item) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 14 : 12,
            vertical: isTablet ? 8 : 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _primaryGreen.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _shadowColor,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            item,
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 13 : 12,
              fontWeight: FontWeight.w600,
              color: _primaryGreen,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGalleryImages(List<String> galleryImagesBase64, bool isTablet) {
    if (galleryImagesBase64.isEmpty) return const SizedBox.shrink();
    
    return SizedBox(
      height: isTablet ? 160 : 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: galleryImagesBase64.length,
        itemBuilder: (context, index) {
          return _buildGalleryImageItem(galleryImagesBase64[index], isTablet);
        },
      ),
    );
  }

  Widget _buildGalleryImageItem(String base64, bool isTablet) {
    try {
      final cleanedBase64 = _cleanBase64String(base64);
      final bytes = base64Decode(cleanedBase64);
      return Container(
        width: isTablet ? 200 : 160,
        height: isTablet ? 160 : 120,
        margin: EdgeInsets.only(right: isTablet ? 16 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          image: DecorationImage(
            image: MemoryImage(bytes),
            fit: BoxFit.cover,
          ),
          border: Border.all(
            color: _primaryGreen,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        width: isTablet ? 200 : 160,
        height: isTablet ? 160 : 120,
        margin: EdgeInsets.only(right: isTablet ? 16 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          color: Colors.white,
          border: Border.all(
            color: _borderLight,
            width: 1.5,
          ),
        ),
        child: Center(
          child: _appLifecycleState == AppLifecycleState.resumed
              ? RotationTransition(
                  turns: _rotateAnimation,
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.grey[400],
                    size: isTablet ? 40 : 30,
                  ),
                )
              : Icon(
                  Icons.broken_image_rounded,
                  color: Colors.grey[400],
                  size: isTablet ? 40 : 30,
                ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ServiceProviderProvider>(context);
    final serviceProvider = provider.selectedProvider;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    if (provider.isLoading && serviceProvider == null) {
      return _buildLoadingState(isTablet);
    }

    if (serviceProvider == null) {
      return _buildErrorState(isTablet);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _buildBackButton(isTablet),
          leadingWidth: isTablet ? 52 : 44,
          actions: [
            _buildLikeButton(isTablet),
          ],
        ),
        floatingActionButton: _buildShareFloatingButton(isTablet),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_lightGreenBg, _lightGreen, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Animated Background Particles
              ...List.generate(10, (index) => _buildAnimatedParticle(index, screenWidth, MediaQuery.of(context).size.height)),
              
              // Main Content
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Banner Image
                  SliverToBoxAdapter(
                    child: _buildBannerImage(serviceProvider, isTablet),
                  ),
                  
                  // All Information
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.all(isTablet ? 24 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and Basic Info
                          Text(
                            serviceProvider.fullName,
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 28 : 24,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                          
                          SizedBox(height: isTablet ? 8 : 6),
                          
                          // Company Name
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 14 : 12,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryGreen, _darkGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryGreen.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              serviceProvider.companyName,
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: isTablet ? 16 : 14),
                          
                          // Category Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 14 : 12,
                              vertical: isTablet ? 8 : 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryRed, _deepRed],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryRed.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _appLifecycleState == AppLifecycleState.resumed
                                    ? RotationTransition(
                                        turns: _rotateAnimation,
                                        child: Icon(
                                          serviceProvider.serviceCategory.icon,
                                          color: Colors.white,
                                          size: isTablet ? 18 : 16,
                                        ),
                                      )
                                    : Icon(
                                        serviceProvider.serviceCategory.icon,
                                        color: Colors.white,
                                        size: isTablet ? 18 : 16,
                                      ),
                                SizedBox(width: isTablet ? 8 : 6),
                                Text(
                                  serviceProvider.serviceCategory.displayName,
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 14 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isTablet ? 20 : 16),
                          
                          // Status Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (serviceProvider.isVerified)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 14 : 12,
                                    vertical: isTablet ? 6 : 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_successGreen, _darkGreen],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _successGreen.withOpacity(0.3),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        color: Colors.white,
                                        size: isTablet ? 16 : 14,
                                      ),
                                      SizedBox(width: isTablet ? 4 : 3),
                                      Text(
                                        'VERIFIED',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 12 : 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                const SizedBox(),
                              
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 6 : 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: serviceProvider.isAvailable
                                      ? LinearGradient(colors: [_successGreen, _darkGreen])
                                      : LinearGradient(colors: [_primaryRed, _deepRed]),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (serviceProvider.isAvailable ? _successGreen : _primaryRed).withOpacity(0.3),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      serviceProvider.isAvailable ? Icons.check_circle_rounded : Icons.remove_circle_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 16 : 14,
                                    ),
                                    SizedBox(width: isTablet ? 4 : 3),
                                    Text(
                                      serviceProvider.isAvailable ? 'AVAILABLE' : 'UNAVAILABLE',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 12 : 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 20 : 16),
                          
                          // Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Likes
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 6 : 4,
                                ),
                                margin: EdgeInsets.only(right: isTablet ? 12 : 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _primaryRed.withOpacity(0.3), width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    _appLifecycleState == AppLifecycleState.resumed
                                        ? RotationTransition(
                                            turns: _rotateAnimation,
                                            child: Icon(
                                              Icons.favorite_rounded,
                                              color: _primaryRed,
                                              size: isTablet ? 16 : 14,
                                            ),
                                          )
                                        : Icon(
                                            Icons.favorite_rounded,
                                            color: _primaryRed,
                                            size: isTablet ? 16 : 14,
                                          ),
                                    SizedBox(width: isTablet ? 4 : 3),
                                    Text(
                                      _formatCount(_likeCount),
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 14 : 12,
                                        fontWeight: FontWeight.w700,
                                        color: _primaryRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Rating
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 6 : 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _badgeGold.withOpacity(0.3), width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: _badgeGold,
                                      size: isTablet ? 16 : 14,
                                    ),
                                    SizedBox(width: isTablet ? 4 : 3),
                                    Text(
                                      (serviceProvider.rating ?? 4.5).toStringAsFixed(1),
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 14 : 12,
                                        fontWeight: FontWeight.w700,
                                        color: _badgeGold,
                                      ),
                                    ),
                                    Text(
                                      ' (${serviceProvider.totalReviews})',
                                      style: GoogleFonts.inter(
                                        fontSize: isTablet ? 12 : 11,
                                        color: _textLight,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 28 : 24),
                          
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _makePhoneCall(serviceProvider.phone),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isTablet ? 18 : 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_primaryRed, _deepRed],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primaryRed.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _appLifecycleState == AppLifecycleState.resumed
                                            ? RotationTransition(
                                                turns: _rotateAnimation,
                                                child: Icon(Icons.call_rounded, color: Colors.white, size: isTablet ? 20 : 18),
                                              )
                                            : Icon(Icons.call_rounded, color: Colors.white, size: isTablet ? 20 : 18),
                                        SizedBox(width: isTablet ? 10 : 8),
                                        Text(
                                          'Call',
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              SizedBox(width: isTablet ? 14 : 12),
                              
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _sendEmail(serviceProvider.email),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isTablet ? 18 : 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_primaryGreen, _darkGreen],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primaryGreen.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _appLifecycleState == AppLifecycleState.resumed
                                            ? RotationTransition(
                                                turns: _rotateAnimation,
                                                child: Icon(Icons.email_rounded, color: Colors.white, size: isTablet ? 20 : 18),
                                              )
                                            : Icon(Icons.email_rounded, color: Colors.white, size: isTablet ? 20 : 18),
                                        SizedBox(width: isTablet ? 10 : 8),
                                        Text(
                                          'Email',
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 28),
                          
                          // Contact Information Section
                          _buildPremiumDetailSection(
                            title: 'Contact',
                            icon: Icons.contact_phone_rounded,
                            child: Column(
                              children: [
                                _buildPremiumContactItem(
                                  icon: Icons.phone_rounded,
                                  title: 'Phone',
                                  value: serviceProvider.phone,
                                  isTablet: isTablet,
                                  onTap: () => _makePhoneCall(serviceProvider.phone),
                                ),
                                SizedBox(height: isTablet ? 12 : 10),
                                
                                _buildPremiumContactItem(
                                  icon: Icons.email_rounded,
                                  title: 'Email',
                                  value: serviceProvider.email,
                                  isTablet: isTablet,
                                  onTap: () => _sendEmail(serviceProvider.email),
                                ),
                                SizedBox(height: isTablet ? 12 : 10),
                                
                                _buildPremiumContactItem(
                                  icon: Icons.location_on_rounded,
                                  title: 'Location',
                                  value: serviceProvider.formattedAddress,
                                  isTablet: isTablet,
                                  onTap: () => _openMap(serviceProvider.formattedAddress),
                                ),
                              ],
                            ),
                            isTablet: isTablet,
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 28),
                          
                          // Service Details Section
                          _buildPremiumDetailSection(
                            title: 'Service Details',
                            icon: Icons.handyman_rounded,
                            child: Column(
                              children: [
                                _buildPremiumDetailCard(
                                  icon: serviceProvider.serviceCategory.icon,
                                  title: 'Category',
                                  value: serviceProvider.serviceCategory.displayName,
                                  gradientColors: [_primaryRed, _deepRed],
                                  isTablet: isTablet,
                                ),
                                SizedBox(height: isTablet ? 12 : 10),
                                
                                _buildPremiumDetailCard(
                                  icon: Icons.work_rounded,
                                  title: 'Service',
                                  value: serviceProvider.serviceProvider,
                                  gradientColors: [_primaryGreen, _darkGreen],
                                  isTablet: isTablet,
                                ),
                                
                                if (serviceProvider.subServiceProvider != null && serviceProvider.subServiceProvider!.isNotEmpty) ...[
                                  SizedBox(height: isTablet ? 12 : 10),
                                  _buildPremiumDetailCard(
                                    icon: Icons.work_outline_rounded,
                                    title: 'Sub-Service',
                                    value: serviceProvider.subServiceProvider!,
                                    gradientColors: [_badgeGold, _goldAccent],
                                    isTablet: isTablet,
                                  ),
                                ],
                                
                                if (serviceProvider.yearsOfExperience != null && serviceProvider.yearsOfExperience!.isNotEmpty) ...[
                                  SizedBox(height: isTablet ? 12 : 10),
                                  _buildPremiumDetailCard(
                                    icon: Icons.timeline_rounded,
                                    title: 'Experience',
                                    value: serviceProvider.yearsOfExperience!,
                                    gradientColors: [_infoBlue, _sapphireBlue],
                                    isTablet: isTablet,
                                  ),
                                ],
                                
                                if (serviceProvider.consultationFee != null) ...[
                                  SizedBox(height: isTablet ? 12 : 10),
                                  _buildPremiumDetailCard(
                                    icon: Icons.attach_money_rounded,
                                    title: 'Consultation Fee',
                                    value: '\$${serviceProvider.consultationFee!.toStringAsFixed(2)}',
                                    gradientColors: [_successGreen, _emeraldGreen],
                                    isTablet: isTablet,
                                  ),
                                ],
                              ],
                            ),
                            isTablet: isTablet,
                          ),
                          
                          // Description Section
                          if (serviceProvider.description != null && serviceProvider.description!.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 28),
                            _buildPremiumDetailSection(
                              title: 'About',
                              icon: Icons.description_rounded,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                  border: Border.all(color: _borderLight, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  serviceProvider.description!,
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 15 : 14,
                                    color: _textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Website Section
                          if (serviceProvider.website != null && serviceProvider.website!.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 28),
                            _buildPremiumDetailSection(
                              title: 'Website',
                              icon: Icons.language_rounded,
                              child: _buildPremiumDetailCard(
                                icon: Icons.language_rounded,
                                title: 'Website',
                                value: serviceProvider.website!,
                                gradientColors: [_primaryRed, _deepRed],
                                isTablet: isTablet,
                                onTap: () => _openWebsite(serviceProvider.website!),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Business Hours Section
                          if (serviceProvider.businessHours != null && serviceProvider.businessHours!.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 28),
                            _buildPremiumDetailSection(
                              title: 'Business Hours',
                              icon: Icons.access_time_rounded,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                  border: Border.all(color: _borderLight, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  serviceProvider.businessHours!,
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 15 : 14,
                                    color: _textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Specialties Section
                          if (serviceProvider.specialties != null && serviceProvider.specialties!.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 28),
                            _buildPremiumDetailSection(
                              title: 'Specialties',
                              icon: Icons.star_rounded,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                  border: Border.all(color: _borderLight, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  serviceProvider.specialties!,
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 15 : 14,
                                    color: _textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Languages Section
                          if (serviceProvider.languagesSpoken.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 28),
                            _buildPremiumDetailSection(
                              title: 'Languages',
                              icon: Icons.language_rounded,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                  border: Border.all(color: _borderLight, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _buildChipGrid(serviceProvider.languagesSpoken, isTablet),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Service Tags Section
                          if (serviceProvider.serviceTags.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 28),
                            _buildPremiumDetailSection(
                              title: 'Service Tags',
                              icon: Icons.tag_rounded,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                  border: Border.all(color: _borderLight, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _buildChipGrid(serviceProvider.serviceTags, isTablet),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Service Areas Section
                          if (serviceProvider.serviceAreas.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 28),
                            _buildPremiumDetailSection(
                              title: 'Service Areas',
                              icon: Icons.map_rounded,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                  border: Border.all(color: _borderLight, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _buildChipGrid(serviceProvider.serviceAreas, isTablet),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Gallery Section
                          if (serviceProvider.galleryImagesBase64 != null && serviceProvider.galleryImagesBase64!.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 28),
                            _buildPremiumDetailSection(
                              title: 'Gallery',
                              icon: Icons.photo_library_rounded,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildGalleryImages(serviceProvider.galleryImagesBase64!, isTablet),
                                  SizedBox(height: isTablet ? 12 : 10),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 16 : 14,
                                      vertical: isTablet ? 10 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _primaryGreen.withOpacity(0.25),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _shadowColor,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _appLifecycleState == AppLifecycleState.resumed
                                            ? RotationTransition(
                                                turns: _rotateAnimation,
                                                child: Icon(
                                                  Icons.photo_camera_rounded,
                                                  color: _primaryGreen,
                                                  size: isTablet ? 18 : 16,
                                                ),
                                              )
                                            : Icon(
                                                Icons.photo_camera_rounded,
                                                color: _primaryGreen,
                                                size: isTablet ? 18 : 16,
                                              ),
                                        SizedBox(width: isTablet ? 8 : 6),
                                        Text(
                                          '📸 ${serviceProvider.galleryImagesBase64!.length} ${serviceProvider.galleryImagesBase64!.length == 1 ? 'photo' : 'photos'}',
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 14 : 13,
                                            fontWeight: FontWeight.w600,
                                            color: _primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Insurance Information
                          if (serviceProvider.acceptsInsurance != null && serviceProvider.acceptsInsurance == true) ...[
                            SizedBox(height: isTablet ? 32 : 28),
                            _buildPremiumDetailSection(
                              title: 'Insurance',
                              icon: Icons.health_and_safety_rounded,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_lightGreen50, _lightGreen],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                  border: Border.all(
                                    color: _primaryGreen,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _primaryGreen,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: isTablet ? 24 : 20,
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 16 : 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Accepts Insurance',
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 18 : 16,
                                              fontWeight: FontWeight.w700,
                                              color: _primaryGreen,
                                            ),
                                          ),
                                          if (serviceProvider.acceptedPaymentMethods != null && serviceProvider.acceptedPaymentMethods!.isNotEmpty) ...[
                                            SizedBox(height: isTablet ? 6 : 4),
                                            Text(
                                              'Payment Methods: ${serviceProvider.acceptedPaymentMethods!.join(', ')}',
                                              style: GoogleFonts.inter(
                                                fontSize: isTablet ? 14 : 12,
                                                color: _textLight,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          ],

                          // Payment Methods
                          if (serviceProvider.acceptedPaymentMethods != null && 
                              serviceProvider.acceptedPaymentMethods!.isNotEmpty && 
                              (serviceProvider.acceptsInsurance == null || serviceProvider.acceptsInsurance == false)) ...[
                            SizedBox(height: isTablet ? 32 : 28),
                            _buildPremiumDetailSection(
                              title: 'Payment Methods',
                              icon: Icons.payment_rounded,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                  border: Border.all(color: _borderLight, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _buildChipGrid(serviceProvider.acceptedPaymentMethods!, isTablet),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // License Information
                          if (serviceProvider.licenseNumber != null && serviceProvider.licenseNumber!.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 28),
                            _buildPremiumDetailSection(
                              title: 'License',
                              icon: Icons.badge_rounded,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                  border: Border.all(color: _borderLight, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_badgeGold, _goldAccent],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.verified_rounded,
                                        color: Colors.white,
                                        size: isTablet ? 24 : 20,
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 16 : 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'License Number',
                                            style: GoogleFonts.inter(
                                              fontSize: isTablet ? 13 : 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            serviceProvider.licenseNumber!,
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 15 : 14,
                                              fontWeight: FontWeight.w600,
                                              color: _textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Premium Footer
                          SizedBox(height: isTablet ? 40 : 30),
                          
                          Container(
                            padding: EdgeInsets.all(isTablet ? 20 : 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_lightGreen50, _lightGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                              border: Border.all(color: _primaryGreen.withOpacity(0.2), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: isTablet ? 50 : 44,
                                  height: isTablet ? 50 : 44,
                                  decoration: BoxDecoration(
                                    gradient:  LinearGradient(
                                      colors: [_primaryRed, _primaryGreen],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryRed.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _appLifecycleState == AppLifecycleState.resumed
                                        ? RotationTransition(
                                            turns: _rotateAnimation,
                                            child: Icon(
                                              Icons.handshake_rounded,
                                              color: Colors.white,
                                              size: isTablet ? 24 : 20,
                                            ),
                                          )
                                        : Icon(
                                            Icons.handshake_rounded,
                                            color: Colors.white,
                                            size: isTablet ? 24 : 20,
                                          ),
                                  ),
                                ),
                                SizedBox(width: isTablet ? 16 : 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Premium Service',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.w700,
                                          color: _primaryGreen,
                                        ),
                                      ),
                                      SizedBox(height: isTablet ? 4 : 2),
                                      Text(
                                        'Trusted by the Bangla Hub Community',
                                        style: GoogleFonts.inter(
                                          fontSize: isTablet ? 14 : 12,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isTablet ? 80 : 60),
                        ],
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
  }

  // Extracted Widgets for Better Performance and Reusability

  Widget _buildBackButton(bool isTablet) {
    return Container(
      width: isTablet ? 40 : 36,
      height: isTablet ? 30 : 26,
      margin: EdgeInsets.only(left: isTablet ? 12 : 8, top: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded, 
          color: Colors.black87, 
          size: isTablet ? 18 : 16,
        ),
        onPressed: () => Navigator.pop(context),
        constraints: const BoxConstraints.expand(),
        padding: EdgeInsets.zero,
        splashRadius: isTablet ? 18 : 14,
      ),
    );
  }

  Widget _buildLikeButton(bool isTablet) {
    return Container(
      width: isTablet ? 40 : 36,
      height: isTablet ? 30 : 26,
      margin: EdgeInsets.only(right: isTablet ? 12 : 8, top: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: _isLoading
            ? SizedBox(
                width: isTablet ? 16 : 14,
                height: isTablet ? 16 : 14,
                child:  CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primaryRed,
                ),
              )
            : Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.black87,
                size: isTablet ? 18 : 16,
              ),
        onPressed: _isLoading ? null : _toggleLike,
        constraints: const BoxConstraints.expand(),
        padding: EdgeInsets.zero,
        splashRadius: isTablet ? 18 : 14,
      ),
    );
  }

  Widget _buildShareFloatingButton(bool isTablet) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed && !_isGeneratingPDF;
    
    Widget button = GestureDetector(
      onTap: _isGeneratingPDF ? null : _showPremiumShareOptions,
      child: Container(
        width: isTablet ? 64 : 56,
        height: isTablet ? 64 : 56,
        decoration: BoxDecoration(
          gradient: _isGeneratingPDF
              ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400])
              :  LinearGradient(colors: [_primaryRed, _primaryGreen]),
          borderRadius: BorderRadius.circular(isTablet ? 22 : 18),
          boxShadow: [
            BoxShadow(
              color: _primaryRed.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: _isGeneratingPDF
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : shouldAnimate
                ? RotationTransition(
                    turns: _rotateAnimation,
                    child: Icon(
                      Icons.share_rounded,
                      color: Colors.white,
                      size: isTablet ? 28 : 24,
                    ),
                  )
                : Icon(
                    Icons.share_rounded,
                    color: Colors.white,
                    size: isTablet ? 28 : 24,
                  ),
      ),
    );
    
    return shouldAnimate
        ? ScaleTransition(scale: _pulseAnimation, child: button)
        : button;
  }

  Widget _buildLoadingState(bool isTablet) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_lightGreenBg, _lightGreen, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return RotationTransition(
                      turns: AlwaysStoppedAnimation(value),
                      child: Container(
                        width: isTablet ? 120 : 100,
                        height: isTablet ? 120 : 100,
                        decoration: BoxDecoration(
                          gradient:  LinearGradient(
                            colors: [_primaryRed, _primaryGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _primaryRed.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: isTablet ? 90 : 70,
                            height: isTablet ? 90 : 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: isTablet ? 50 : 40,
                                height: isTablet ? 50 : 40,
                                child:  CircularProgressIndicator(
                                  color: _primaryGreen,
                                  strokeWidth: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: isTablet ? 30 : 20),
                Text(
                  'Loading...',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 26 : 22,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Text(
                    'Fetching service details ✨',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 16 : 14,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isTablet) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_lightGreenBg, _lightGreen, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 30 : 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.85 + (0.15 * value),
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 28 : 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_lightRed50, _lightRed50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: _appLifecycleState == AppLifecycleState.resumed
                              ? RotationTransition(
                                  turns: _rotateAnimation,
                                  child: Icon(
                                    Icons.error_outline_rounded,
                                    size: isTablet ? 70 : 60,
                                    color: _primaryRed,
                                  ),
                                )
                              : Icon(
                                  Icons.error_outline_rounded,
                                  size: isTablet ? 70 : 60,
                                  color: _primaryRed,
                                ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isTablet ? 30 : 20),
                  Text(
                    'Not Found',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 28 : 24,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  Text(
                    'The service provider you\'re looking for\ncould not be found',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 16 : 14,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isTablet ? 30 : 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.92 + (0.08 * value),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 40 : 30,
                              vertical: isTablet ? 16 : 14,
                            ),
                            decoration: BoxDecoration(
                              gradient:  LinearGradient(
                                colors: [_primaryRed, _primaryGreen],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryRed.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _appLifecycleState == AppLifecycleState.resumed
                                    ? RotationTransition(
                                        turns: _rotateAnimation,
                                        child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: isTablet ? 22 : 20),
                                      )
                                    : Icon(Icons.arrow_back_rounded, color: Colors.white, size: isTablet ? 22 : 20),
                                const SizedBox(width: 10),
                                Text(
                                  'GO BACK',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedParticle(int index, double width, double height) {
    final controller = _particleControllers[index % _particleControllers.length];
    
    return Positioned(
      left: (index * 37) % width,
      top: (index * 53) % height,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Opacity(
            opacity: (0.1 + (value * 0.2)) * (0.5 + (index % 3) * 0.1),
            child: Transform.rotate(
              angle: value * 6.28,
              child: Container(
                width: 2 + (index % 3) * 2,
                height: 2 + (index % 3) * 2,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _primaryGreen.withOpacity(0.1),
                      _primaryRed.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}