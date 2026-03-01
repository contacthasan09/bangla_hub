import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bangla_hub/models/event_model.dart';
import 'package:bangla_hub/providers/event_provider.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;
  
  const EventDetailsScreen({Key? key, required this.event}) : super(key: key);
  
  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isInterested = false;
  bool _isLoading = false;
  bool _isGeneratingPDF = false;
  
  // Premium Color Palette - Matching ServiceProviderDetailScreen with Light Green Background
  final Color _primaryRed = Color(0xFFD32F2F); // Darker red for buttons
  final Color _primaryGreen = Color(0xFF2E7D32); // Darker green for buttons
  final Color _darkGreen = Color(0xFF1B5E20); // Very dark green
  final Color _goldAccent = Color(0xFFFFB300); // Darker gold
  
  // Dark button colors
  final Color _coralRed = Color(0xFFC62828); // Dark red
  final Color _mintGreen = Color(0xFF2E7D32); // Dark green
  final Color _softGold = Color(0xFFFF8F00); // Dark gold
  final Color _emeraldGreen = Color(0xFF1B5E20); // Dark emerald
  final Color _sapphireBlue = Color(0xFF1565C0); // Dark blue
  final Color _amethystPurple = Color(0xFF6A1B9A); // Dark purple
  final Color _deepRed = Color(0xFFB71C1C); // Deep red
  
  // Light Green Background (50% opacity)
  final Color _lightGreenBg = Color(0x80E8F5E9); // Light green with 50% opacity
  final Color _lightGreen = Color(0xFFE8F5E9);
  final Color _lightRed = Color(0xFFFFEBEE);
  final Color _lightYellow = Color(0xFFFFF3E0);
  final Color _lightBlue = Color(0xFFE3F2FD);
  final Color _creamWhite = Color(0xFFFFF9E6);
  
  // 50% opacity colors for backgrounds
  final Color _creamWhite50 = Color(0x80FFF9E6);
  final Color _lightGreen50 = Color(0x80E8F5E9);
  final Color _lightRed50 = Color(0x80FFEBEE);
  final Color _lightYellow50 = Color(0x80FFF3E0);
  final Color _lightBlue50 = Color(0x80E3F2FD);
  
  // Border and shadow colors
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _shadowColor = Color(0x1A000000);
  
  // Text Colors
  final Color _textPrimary = Color(0xFF1A2B3C);
  final Color _textSecondary = Color(0xFF5D6D7E);
  final Color _textLight = Color(0xFF6C757D);
  
  // Additional colors
  final Color _successGreen = Color(0xFF2E7D32);
  final Color _infoBlue = Color(0xFF1565C0);
  final Color _badgeGold = Color(0xFFFF8F00);
  
  @override
  void initState() {
    super.initState();
    _checkIfInterested();
    
    print('📸 EventDetailsScreen init - Banner URL: ${widget.event.bannerImageUrl}');
  }
  
  Future<void> _checkIfInterested() async {
    final authProvider = context.read<AuthProvider>();
    final eventProvider = context.read<EventProvider>();
    
    if (authProvider.user != null) {
      try {
        _isInterested = await eventProvider.isUserInterested(
          widget.event.id, 
          authProvider.user!.id
        );
        setState(() {});
      } catch (e) {
        print('❌ Error checking interest: $e');
      }
    }
  }
  
  Future<void> _toggleInterest() async {
    final authProvider = context.read<AuthProvider>();
    final eventProvider = context.read<EventProvider>();
    
    if (authProvider.user == null) {
      _showPremiumSnackBar('Please login to show interest', isError: true);
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await eventProvider.toggleUserInterest(
        widget.event.id,
        authProvider.user!.id,
      );
      setState(() {
        _isInterested = !_isInterested;
      });
    } catch (e) {
      print('❌ Error toggling interest: $e');
      _showPremiumSnackBar('Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showPremiumSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isError 
                  ? [_primaryRed, _deepRed] 
                  : [_primaryGreen, _darkGreen],
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
                isError ? Icons.error_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
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
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
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

  Widget _buildBannerImage(EventModel event, bool isTablet) {
    // Use the built-in bannerImageWidget from EventModel
    return Container(
      width: double.infinity,
      height: isTablet ? 300 : 250,
      child: event.bannerImageWidget,
    );
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

  void _showPremiumShareOptions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                offset: Offset(0, -10),
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
                SizedBox(height: 20),
                
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
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share Event',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 26 : 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Share this event with friends',
                            style: GoogleFonts.inter(
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
                
                // Share Options Grid - DARK BUTTONS
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  mainAxisSpacing: isTablet ? 20 : 15,
                  crossAxisSpacing: isTablet ? 20 : 15,
                  children: [
                    _buildPremiumShareOption(
                      icon: Icons.text_fields_rounded,
                      label: 'Text',
                      gradientColors: [_sapphireBlue, Color(0xFF0D47A1)],
                      onTap: () {
                        Navigator.pop(context);
                        _shareEventAsText();
                      },
                      isTablet: isTablet,
                    ),
                    
                    _buildPremiumShareOption(
                      icon: Icons.chat_rounded,
                      label: 'WhatsApp',
                      gradientColors: [_primaryGreen, Color(0xFF0D3B1A)],
                      onTap: () {
                        Navigator.pop(context);
                        _shareToWhatsApp();
                      },
                      isTablet: isTablet,
                    ),
                    
                    _buildPremiumShareOption(
                      icon: Icons.facebook_rounded,
                      label: 'Facebook',
                      gradientColors: [_sapphireBlue, Color(0xFF002171)],
                      onTap: () {
                        Navigator.pop(context);
                        _shareToFacebookFeed();
                      },
                      isTablet: isTablet,
                    ),
                    
                    _buildPremiumShareOption(
                      icon: Icons.copy_rounded,
                      label: 'Copy',
                      gradientColors: [_amethystPurple, Color(0xFF4A148C)],
                      onTap: () async {
                        final text = '''
🎉 ${widget.event.title} 🎉

📅 ${widget.event.fullFormattedDate}
📍 ${widget.event.location}
👤 ${widget.event.organizer}

${widget.event.description.substring(0, widget.event.description.length > 100 ? 100 : widget.event.description.length)}...

Shared via Bangla Hub App.
                        ''';
                        await Clipboard.setData(ClipboardData(text: text));
                        _showPremiumSnackBar('Event details copied to clipboard');
                        Navigator.pop(context);
                      },
                      isTablet: isTablet,
                    ),
                  ],
                ),
                
                SizedBox(height: isTablet ? 24 : 20),
                
                // PDF Share Option - DARK BUTTON
                Container(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _generateAndSharePDF();
                      },
                      borderRadius: BorderRadius.circular(isTablet ? 18 : 15),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 20,
                          vertical: isTablet ? 18 : 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryRed, _primaryGreen],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(isTablet ? 18 : 15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: Offset(0, 8),
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
                offset: Offset(0, 5),
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
                  child: Icon(
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
  
  Future<void> _generateAndSharePDF() async {
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
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Event Details',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 24,
                        color: PdfColors.green800,
                      ),
                    ),
                    pw.Container(
                      padding: pw.EdgeInsets.all(8),
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
              
              // Event Basic Info
              pw.Container(
                padding: pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      widget.event.title,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 22,
                        color: PdfColors.red700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      widget.event.organizer,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: PdfColors.green700,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Event Details
              pw.Container(
                padding: pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '📅 Date & Time',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: PdfColors.red700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      widget.event.fullFormattedDate,
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                    pw.SizedBox(height: 12),
                    
                    pw.Text(
                      '📍 Location',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: PdfColors.red700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      widget.event.location,
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                    pw.SizedBox(height: 12),
                    
                    pw.Text(
                      '👤 Organizer',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: PdfColors.red700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      widget.event.organizer,
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Description
              pw.Container(
                padding: pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '📝 Description',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: PdfColors.red700,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      widget.event.description,
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Contact Information
              pw.Container(
                padding: pw.EdgeInsets.all(16),
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
                    _buildPDFInfoRow('Contact Person:', widget.event.contactPerson, font, boldFont),
                    _buildPDFInfoRow('Email:', widget.event.contactEmail, font, boldFont),
                    _buildPDFInfoRow('Phone:', widget.event.contactPhone, font, boldFont),
                  ],
                ),
              ),
              
              if (!widget.event.isFree && widget.event.ticketPrices != null && widget.event.ticketPrices!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '🎫 Ticket Prices',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 18,
                          color: PdfColors.red700,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      ...widget.event.ticketPrices!.entries.map((entry) {
                        return pw.Padding(
                          padding: pw.EdgeInsets.only(bottom: 8),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                entry.key,
                                style: pw.TextStyle(font: font, fontSize: 12),
                              ),
                              pw.Text(
                                '\$${entry.value.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 12,
                                  color: PdfColors.red700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
                    'Bangla Hub Events',
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
      final file = File('${output.path}/event_${widget.event.id}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Event Details - ${widget.event.title}',
        text: 'Check out this event from Bangla Hub!',
      );

      _showPremiumSnackBar('✅ PDF generated and shared successfully!');
    } catch (e) {
      print('PDF Generation Error: $e');
      _showPremiumSnackBar('Error generating PDF: $e', isError: true);
    } finally {
      setState(() {
        _isGeneratingPDF = false;
      });
    }
  }

  pw.Widget _buildPDFInfoRow(String label, String value, pw.Font font, pw.Font boldFont) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 8),
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
  
  void _shareEventAsText() {
    final event = widget.event;
    final text = '''
🎉 ${event.title} 🎉

📅 Date: ${event.fullFormattedDate}
📍 Location: ${event.location}
👤 Organizer: ${event.organizer}

📝 Description:
${event.description}

${event.isFree ? '🎫 FREE ENTRY!' : '🎫 Ticket event'}

👥 Interested: ${_formatCount(event.totalInterested)} people

Shared via Bangla Hub App.
''';
    
    Share.share(
      text,
      subject: 'Check out this event: ${event.title}',
    );
  }
  
  Future<void> _shareToWhatsApp() async {
    final text = '''
*Check out this event on Bangla Hub!* 🎉

🎯 *${widget.event.title}*
📅 *Date:* ${widget.event.fullFormattedDate}
📍 *Location:* ${widget.event.location}
👤 *Organizer:* ${widget.event.organizer}
👥 *Interested:* ${_formatCount(widget.event.totalInterested)} people

_Download Bangla Hub App for more details!_ 📱
''';
    
    final url = 'whatsapp://send?text=${Uri.encodeComponent(text)}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _showPremiumSnackBar('WhatsApp not installed 📱', isError: true);
    }
  }
  
  Future<void> _shareToFacebookFeed() async {
    final text = '''
Check out this amazing event on Bangla Hub!

🎉 ${widget.event.title}
📅 ${widget.event.fullFormattedDate}
📍 ${widget.event.location}
👥 ${_formatCount(widget.event.totalInterested)} people interested

Shared via Bangla Hub App. Download now! 📲
''';
    
    Share.share(
      text,
      subject: 'Bangla Hub Event: ${widget.event.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        floatingActionButton: ScaleTransition(
          scale: AlwaysStoppedAnimation(1.0),
          child: GestureDetector(
            onTap: _isGeneratingPDF ? null : _showPremiumShareOptions,
            child: Container(
              width: isTablet ? 64 : 56,
              height: isTablet ? 64 : 56,
              decoration: BoxDecoration(
                gradient: _isGeneratingPDF
                    ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400])
                    : LinearGradient(colors: [_primaryRed, _primaryGreen]),
                borderRadius: BorderRadius.circular(isTablet ? 22 : 18),
                boxShadow: [
                  BoxShadow(
                    color: _primaryRed.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: _isGeneratingPDF
                  ? Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(
                      Icons.share_rounded,
                      color: Colors.white,
                      size: isTablet ? 28 : 24,
                    ),
            ),
          ),
        ),
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
              ...List.generate(20, (index) => _buildAnimatedParticle(index, screenWidth, MediaQuery.of(context).size.height)),
              
              // Main Content
              CustomScrollView(
                slivers: [
                  // Banner Image
                  SliverToBoxAdapter(
                    child: _buildBannerImage(widget.event, isTablet),
                  ),
                  
                  // All Information in Column Below
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.all(isTablet ? 24 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back and Interest Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(Icons.arrow_back_rounded, color: _textPrimary, size: isTablet ? 22 : 20),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: _isLoading ? null : _toggleInterest,
                                  icon: _isLoading
                                      ? SizedBox(
                                          width: isTablet ? 20 : 18,
                                          height: isTablet ? 20 : 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _primaryGreen,
                                          ),
                                        )
                                      : Icon(
                                          _isInterested ? Icons.favorite : Icons.favorite_border,
                                          color: _isInterested ? Colors.red : _textPrimary,
                                          size: isTablet ? 22 : 20,
                                        ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 20 : 16),
                          
                          // Event Title and Category
                          Text(
                            widget.event.title,
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 28 : 24,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                          
                          SizedBox(height: isTablet ? 8 : 6),
                          
                          // Category Badge - DARK RED
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
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.event.categoryIcon,
                                  color: Colors.white,
                                  size: isTablet ? 18 : 16,
                                ),
                                SizedBox(width: isTablet ? 8 : 6),
                                Text(
                                  widget.event.categoryText,
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
                              // Approved Badge - DARK GREEN
                              if (widget.event.isApproved)
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
                                        offset: Offset(0, 2),
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
                                        'APPROVED',
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
                                Container(),
                              
                              // Status Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 6 : 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: widget.event.isPast
                                      ? [Colors.grey, Colors.grey[700]!]
                                      : [_successGreen, _darkGreen],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.event.isPast
                                          ? Colors.grey.withOpacity(0.2)
                                          : _successGreen.withOpacity(0.3),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      widget.event.isPast ? Icons.event_busy_rounded : Icons.event_available_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 16 : 14,
                                    ),
                                    SizedBox(width: isTablet ? 4 : 3),
                                    Text(
                                      widget.event.isPast ? 'PAST' : 'UPCOMING',
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
                              // Interested Count
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
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.favorite_rounded,
                                      color: _primaryRed,
                                      size: isTablet ? 16 : 14,
                                    ),
                                    SizedBox(width: isTablet ? 4 : 3),
                                    Text(
                                      _formatCount(widget.event.totalInterested),
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 14 : 12,
                                        fontWeight: FontWeight.w700,
                                        color: _primaryRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Ticket Info
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 6 : 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: widget.event.isFree ? _primaryGreen.withOpacity(0.3) : _badgeGold.withOpacity(0.3), 
                                    width: 1
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      widget.event.isFree ? Icons.card_giftcard_rounded : Icons.confirmation_number_rounded,
                                      color: widget.event.isFree ? _primaryGreen : _badgeGold,
                                      size: isTablet ? 16 : 14,
                                    ),
                                    SizedBox(width: isTablet ? 4 : 3),
                                    Text(
                                      widget.event.isFree ? 'FREE' : 'TICKETED',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 14 : 12,
                                        fontWeight: FontWeight.w700,
                                        color: widget.event.isFree ? _primaryGreen : _badgeGold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // Event Details Section
                          _buildPremiumDetailSection(
                            title: 'Event Details',
                            icon: Icons.info_rounded,
                            child: Column(
                              children: [
                                // Date & Time Card
                                _buildPremiumDetailCard(
                                  icon: Icons.calendar_today_rounded,
                                  title: 'Date & Time',
                                  value: widget.event.fullFormattedDate,
                                  gradientColors: [_primaryRed, _deepRed],
                                  isTablet: isTablet,
                                ),
                                SizedBox(height: isTablet ? 14 : 12),
                                
                                // Location Card
                                _buildPremiumDetailCard(
                                  icon: Icons.location_on_rounded,
                                  title: 'Location',
                                  value: widget.event.location,
                                  gradientColors: [_primaryGreen, _darkGreen],
                                  isTablet: isTablet,
                                ),
                                SizedBox(height: isTablet ? 14 : 12),
                                
                                // Organizer Card
                                _buildPremiumDetailCard(
                                  icon: Icons.business_rounded,
                                  title: 'Organizer',
                                  value: widget.event.organizer,
                                  gradientColors: [_badgeGold, _goldAccent],
                                  isTablet: isTablet,
                                ),
                              ],
                            ),
                            isTablet: isTablet,
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // Description Section
                          _buildPremiumDetailSection(
                            title: 'Description',
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
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.event.description,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 15 : 14,
                                  color: _textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // Contact Information Section
                          _buildPremiumDetailSection(
                            title: 'Contact Information',
                            icon: Icons.contact_phone_rounded,
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
                                    offset: Offset(0, 4),
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
                                  SizedBox(height: isTablet ? 14 : 12),
                                  _buildPremiumContactItem(
                                    icon: Icons.email_rounded,
                                    title: 'Email',
                                    value: widget.event.contactEmail,
                                    isTablet: isTablet,
                                    onTap: () => _launchEmail(widget.event.contactEmail),
                                  ),
                                  SizedBox(height: isTablet ? 14 : 12),
                                  _buildPremiumContactItem(
                                    icon: Icons.phone_rounded,
                                    title: 'Phone',
                                    value: widget.event.contactPhone,
                                    isTablet: isTablet,
                                    onTap: () => _launchPhone(widget.event.contactPhone),
                                  ),
                                ],
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
                          // Ticket Information Section
                          if (!widget.event.isFree && widget.event.ticketPrices != null && widget.event.ticketPrices!.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumDetailSection(
                              title: 'Ticket Information',
                              icon: Icons.confirmation_number_rounded,
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
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: widget.event.ticketPrices!.entries.map((entry) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 6),
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
                                                      size: isTablet ? 14 : 12,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: isTablet ? 12 : 10),
                                                Expanded(
                                                  child: Text(
                                                    entry.key,
                                                    style: GoogleFonts.inter(
                                                      fontSize: isTablet ? 15 : 14,
                                                      color: _textPrimary,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isTablet ? 16 : 12,
                                              vertical: isTablet ? 8 : 6,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [_primaryRed, _deepRed],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                            ),
                                            child: Text(
                                              '\$${entry.value.toStringAsFixed(2)}',
                                              style: GoogleFonts.inter(
                                                fontSize: isTablet ? 16 : 14,
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
                          ],
                          
                          // Free Event Banner
                          if (widget.event.isFree) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            Container(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_lightGreen50, _lightGreen],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                border: Border.all(color: _primaryGreen.withOpacity(0.3), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: isTablet ? 50 : 44,
                                    height: isTablet ? 50 : 44,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_primaryGreen, _darkGreen],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primaryGreen.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.card_giftcard_rounded,
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
                                          'Free Event',
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w800,
                                            color: _primaryGreen,
                                          ),
                                        ),
                                        SizedBox(height: isTablet ? 4 : 2),
                                        Text(
                                          'No tickets required - Join for free!',
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
                          ],
                          
                          // Premium Footer
                          SizedBox(height: isTablet ? 40 : 32),
                          
                          Container(
                            padding: EdgeInsets.all(isTablet ? 24 : 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_lightGreen50, _lightGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                              border: Border.all(color: _primaryGreen.withOpacity(0.2), width: 1.5),
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
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryRed.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.event_available_rounded,
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
                                        'Premium Event',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.w700,
                                          color: _primaryGreen,
                                        ),
                                      ),
                                      SizedBox(height: isTablet ? 4 : 2),
                                      Text(
                                        'Powered by Bangla Hub Community',
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
                          
                          SizedBox(height: isTablet ? 40 : 30),
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
  
  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Clipboard.setData(ClipboardData(text: email));
      _showPremiumSnackBar('Email copied to clipboard');
    }
  }
  
  Future<void> _launchPhone(String phone) async {
    final Uri uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Clipboard.setData(ClipboardData(text: phone));
      _showPremiumSnackBar('Phone number copied to clipboard');
    }
  }
  
  Widget _buildAnimatedParticle(int index, double width, double height) {
    return Positioned(
      left: (index * 37) % width,
      top: (index * 53) % height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(seconds: 3 + (index % 3)),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
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
              padding: EdgeInsets.all(isTablet ? 8 : 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryRed, _primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
              ),
              child: Icon(
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
  }) {
    return Container(
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
            offset: Offset(0, 5),
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
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
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
                SizedBox(height: 2),
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
        ],
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
                      ? LinearGradient(colors: [_primaryRed, _primaryGreen])
                      : LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade300]),
                  borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                ),
                child: Center(
                  child: Icon(
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
                    SizedBox(height: 2),
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
}