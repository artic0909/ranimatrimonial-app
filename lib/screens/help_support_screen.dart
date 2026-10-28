import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../components/rani_alert.dart';
import '../components/rani_matrimonial_loader.dart';

/// Screen: Help & Support Desk (matching website help_center.blade.php & support.blade.php)
/// Sub-tabs:
/// 1. FAQs & Direct Helplines
/// 2. My Support Tickets (List & Raise New Ticket)
class RaniHelpSupportScreen extends StatefulWidget {
  const RaniHelpSupportScreen({super.key});

  @override
  State<RaniHelpSupportScreen> createState() => _RaniHelpSupportScreenState();
}

class _RaniHelpSupportScreenState extends State<RaniHelpSupportScreen> {
  int _selectedTab = 0; // 0 = FAQs & Contact, 1 = Support Tickets
  bool _isLoading = true;

  // FAQs data
  List<dynamic> _faqs = [];
  Map<String, dynamic> _contactInfo = {};

  // Tickets data
  List<dynamic> _tickets = [];
  Map<String, dynamic> _counts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final helpRes = await ApiService.instance.getHelpCenter();
      final ticketRes = await ApiService.instance.getSupportTickets();

      if (mounted) {
        setState(() {
          if (helpRes['success'] == true) {
            _faqs = helpRes['faqs'] ?? [];
            _contactInfo = helpRes['contact_info'] ?? {};
          }
          if (ticketRes['success'] == true) {
            _tickets = ticketRes['tickets']?['data'] ?? [];
            _counts = ticketRes['counts'] ?? {};
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitTicket({
    required String priority,
    required String subject,
    required String message,
    File? screenshot,
  }) async {
    RaniMatrimonialLoader.show(context, message: 'Submitting ticket...');
    try {
      final res = await ApiService.instance.createSupportTicket(
        priority: priority,
        subject: subject,
        message: message,
        screenshots: screenshot != null ? [screenshot] : null,
      );

      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        RaniAlert.success(
          context,
          res['message'] ?? 'Ticket submitted successfully!',
          title: 'Ticket Raised',
        );
        _loadData();
      } else {
        RaniAlert.error(context, res['message'] ?? 'Failed to submit ticket.');
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      RaniAlert.error(context, 'Error: $e');
    }
  }

  void _showRaiseTicketSheet() {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String priority = 'low';
    File? screenshotFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF200707),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Raise Support Ticket',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF3E5AB),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white60),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Priority
                    Text('Priority Level', style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFFD5CCC4))),
                    const SizedBox(height: 6),
                    Row(
                      children: ['low', 'high', 'urgent'].map((p) {
                        final isSel = priority == p;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(p.toUpperCase()),
                            selected: isSel,
                            onSelected: (val) {
                              if (val) setSheetState(() => priority = p);
                            },
                            selectedColor: const Color(0xFFD4A034),
                            backgroundColor: const Color(0xFF140505),
                            labelStyle: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? const Color(0xFF1E0A0A) : const Color(0xFFD5CCC4),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    // Subject
                    Text('Subject', style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFFD5CCC4))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subjectCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Brief summary of issue...',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF140505),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Message
                    Text('Detailed Description', style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFFD5CCC4))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: messageCtrl,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Explain the issue or question in detail...',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF140505),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Screenshot Upload
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E0C0C),
                            foregroundColor: const Color(0xFFF3E5AB),
                            side: const BorderSide(color: Color(0xFFD4A034), width: 0.8),
                          ),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(source: ImageSource.gallery);
                            if (picked != null) {
                              setSheetState(() => screenshotFile = File(picked.path));
                            }
                          },
                          icon: const Icon(Icons.attach_file, size: 16),
                          label: Text(screenshotFile != null ? 'Change Screenshot' : 'Attach Screenshot'),
                        ),
                        if (screenshotFile != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle, color: Color(0xFF81C784), size: 18),
                        ],
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A034),
                          foregroundColor: const Color(0xFF1E0A0A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          final subject = subjectCtrl.text.trim();
                          final message = messageCtrl.text.trim();
                          if (subject.isEmpty || message.isEmpty) {
                            RaniAlert.error(context, 'Please fill in both subject and description.');
                            return;
                          }

                          Navigator.pop(ctx);
                          _submitTicket(
                            priority: priority,
                            subject: subject,
                            message: message,
                            screenshot: screenshotFile,
                          );
                        },
                        child: Text(
                          'Submit Ticket',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF200707),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Help & Support Desk',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF3E5AB),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF160404),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildSegmentButton(0, 'Help Center & FAQs'),
                _buildSegmentButton(1, 'Support Tickets'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: RaniMatrimonialLoader(
                size: 110,
                message: 'Loading Help Resources...',
              ),
            )
          : (_selectedTab == 0 ? _buildHelpCenterTab() : _buildTicketsTab()),
    );
  }

  Widget _buildSegmentButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4A034) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF1E0A0A) : const Color(0xFFD5CCC4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpCenterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Direct Helpline Cards
          Text(
            'Direct Support Channels',
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF3E5AB),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHelplineCard(
                  icon: Icons.phone_in_talk,
                  title: 'Call Support',
                  subtitle: _contactInfo['phone'] ?? '+91 62922 37202',
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHelplineCard(
                  icon: Icons.chat,
                  title: 'WhatsApp Desk',
                  subtitle: _contactInfo['whatsapp'] ?? '+91 62922 37202',
                  color: const Color(0xFF25D366),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // FAQs
          Text(
            'Frequently Asked Questions',
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF3E5AB),
            ),
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _faqs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final faq = _faqs[i];
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF200707),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF381212)),
                ),
                child: ExpansionTile(
                  iconColor: const Color(0xFFD4A034),
                  collapsedIconColor: const Color(0xFFD4A034),
                  title: Text(
                    faq['question'] ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF3E5AB),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Text(
                        faq['answer'] ?? '',
                        style: GoogleFonts.outfit(fontSize: 13, height: 1.45, color: const Color(0xFFD5CCC4)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF200707),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF381212)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFFF3E5AB)),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.outfit(fontSize: 11.5, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsTab() {
    final total = _counts['total'] ?? 0;
    final open = _counts['open'] ?? 0;
    final resolved = _counts['resolved'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Summary Row
          Row(
            children: [
              _buildTicketStatCard('Total', '$total', const Color(0xFFF3E5AB)),
              const SizedBox(width: 8),
              _buildTicketStatCard('Open', '$open', const Color(0xFFFFB74D)),
              const SizedBox(width: 8),
              _buildTicketStatCard('Resolved', '$resolved', const Color(0xFF81C784)),
            ],
          ),

          const SizedBox(height: 16),

          // Raise Ticket Primary Action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A034),
                foregroundColor: const Color(0xFF1E0A0A),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _showRaiseTicketSheet,
              icon: const Icon(Icons.add),
              label: Text(
                'Raise New Support Ticket',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Your Raised Tickets',
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF3E5AB),
            ),
          ),

          const SizedBox(height: 12),

          if (_tickets.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF200707),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF381212)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.confirmation_num_outlined, size: 40, color: Color(0xFFD4A034)),
                  const SizedBox(height: 10),
                  Text(
                    'No Support Tickets Raised',
                    style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFFF3E5AB)),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tickets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final t = _tickets[i];
                final code = t['ticket_code'] ?? 'RM-TCK';
                final subject = t['subject'] ?? 'Query';
                final status = t['status'] ?? 'open';
                final priority = t['priority'] ?? 'low';
                final date = t['created_at']?.toString().substring(0, 10) ?? '';

                Color statusColor = const Color(0xFFFFB74D);
                if (status == 'resolved') statusColor = const Color(0xFF81C784);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF200707),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF381212)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            code,
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFD4A034)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor, width: 0.8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subject,
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFF3E5AB)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Priority: ${priority.toUpperCase()} • $date',
                        style: GoogleFonts.outfit(fontSize: 11.5, color: Colors.white54),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTicketStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF200707),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF381212)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFFD5CCC4))),
          ],
        ),
      ),
    );
  }
}
