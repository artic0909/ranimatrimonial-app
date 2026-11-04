import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_matrimonial_loader.dart';

/// Screen: Support Desk & Tickets
/// Candidate ticket tracking, resolutions, and raising new support tickets.
class RaniSupportScreen extends StatefulWidget {
  final bool showAppBar;
  const RaniSupportScreen({super.key, this.showAppBar = true});

  @override
  State<RaniSupportScreen> createState() => _RaniSupportScreenState();
}

class _RaniSupportScreenState extends State<RaniSupportScreen> {
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'open', 'resolved'

  List<dynamic> _tickets = [];
  Map<String, dynamic> _counts = {
    'total': 0,
    'open': 0,
    'resolved': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.instance.getSupportTickets();
      if (!mounted) return;

      if (res['success'] == true) {
        final List<dynamic> loaded = List<dynamic>.from(res['tickets']?['data'] ?? []);
        loaded.sort((a, b) {
          final aDate = a['created_at']?.toString() ?? '';
          final bDate = b['created_at']?.toString() ?? '';
          if (aDate.isNotEmpty && bDate.isNotEmpty) {
            return bDate.compareTo(aDate); // latest 1st
          }
          final aId = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
          final bId = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
          return bId.compareTo(aId);
        });
        setState(() {
          _tickets = loaded;
          _counts = Map<String, dynamic>.from(res['counts'] ?? {});
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredTickets {
    if (_selectedFilter == 'open') {
      return _tickets.where((t) => t['status'] == 'open' || t['status'] == 'in_progress').toList();
    } else if (_selectedFilter == 'resolved') {
      return _tickets.where((t) => t['status'] == 'resolved').toList();
    }
    return _tickets;
  }

  Future<void> _submitTicketForm({
    required String priority,
    required String subject,
    required String message,
    required List<File> screenshots,
  }) async {
    RaniMatrimonialLoader.show(context, message: 'Submitting ticket...');
    try {
      final res = await ApiService.instance.createSupportTicket(
        priority: priority,
        subject: subject,
        message: message,
        screenshots: screenshots.isNotEmpty ? screenshots : null,
      );
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      if (res['success'] == true) {
        RaniAlert.success(
          context,
          res['message'] ?? 'Ticket created successfully!',
          title: 'Ticket Raised',
        );
        _loadTickets();
      } else {
        RaniAlert.error(context, res['message'] ?? 'Failed to create ticket.');
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      RaniAlert.error(context, 'Error: $e');
    }
  }

  void _showRaiseTicketModal() {
    final formKey = GlobalKey<FormState>();
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String priority = 'low';
    final List<File> selectedImages = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF7F2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Bar with Grab Handle
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6CBC0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF750000).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              CupertinoIcons.ticket_fill,
                              color: Color(0xFF750000),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Raise Support Ticket',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF222222),
                                  ),
                                ),
                                Text(
                                  'Our support team will assist you within 2 hours',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF777777),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF666666)),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFEBE3D7)),

                    // Scrollable Form Body
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Priority Selector
                              Text(
                                'Priority Level',
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildPriorityChip('low', 'Low', const Color(0xFF1976D2), priority, () {
                                    setModalState(() => priority = 'low');
                                  }),
                                  const SizedBox(width: 10),
                                  _buildPriorityChip('high', 'High', const Color(0xFFF57C00), priority, () {
                                    setModalState(() => priority = 'high');
                                  }),
                                  const SizedBox(width: 10),
                                  _buildPriorityChip('urgent', 'Urgent', const Color(0xFFD32F2F), priority, () {
                                    setModalState(() => priority = 'urgent');
                                  }),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Subject
                              Text(
                                'Subject',
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: subjectCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Wallet recharge inquiry, Photo blur',
                                  hintStyle: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFFAAAAAA)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE4DAD0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE4DAD0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF750000), width: 1.4),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter a ticket subject';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Message Details
                              Text(
                                'Issue Description',
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: messageCtrl,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Please describe the issue or your question in detail...',
                                  hintStyle: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFFAAAAAA)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.all(14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE4DAD0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE4DAD0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF750000), width: 1.4),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().length < 10) {
                                    return 'Please write at least 10 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Screenshots Upload
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Screenshots (Optional, max 5)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                  if (selectedImages.length < 5)
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF750000),
                                        padding: EdgeInsets.zero,
                                      ),
                                      onPressed: () async {
                                        final picker = ImagePicker();
                                        final picked = await picker.pickImage(
                                          source: ImageSource.gallery,
                                          imageQuality: 85,
                                        );
                                        if (picked != null) {
                                          setModalState(() {
                                            selectedImages.add(File(picked.path));
                                          });
                                        }
                                      },
                                      icon: const Icon(CupertinoIcons.photo_camera, size: 16),
                                      label: Text(
                                        'Add Photo',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ),
                                ],
                              ),
                              if (selectedImages.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 80,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: selectedImages.length,
                                    separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                                    itemBuilder: (context, idx) {
                                      return Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.file(
                                              selectedImages[idx],
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () {
                                                setModalState(() {
                                                  selectedImages.removeAt(idx);
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF750000),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    if (!formKey.currentState!.validate()) return;
                                    Navigator.pop(ctx);
                                    _submitTicketForm(
                                      priority: priority,
                                      subject: subjectCtrl.text.trim(),
                                      message: messageCtrl.text.trim(),
                                      screenshots: selectedImages,
                                    );
                                  },
                                  child: Text(
                                    'Submit Ticket',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildPriorityChip(String value, String label, Color color, String current, VoidCallback onTap) {
    final isSel = current == value;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSel ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? color : const Color(0xFFE4DAD0),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
              color: isSel ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: const Color(0xFF630008),
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(CupertinoIcons.back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Help & Support Tickets',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(CupertinoIcons.arrow_clockwise, color: Colors.white),
                  onPressed: _loadTickets,
                ),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF750000),
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: _showRaiseTicketModal,
        icon: const Icon(CupertinoIcons.plus_circle_fill, color: Color(0xFFF3C05D)),
        label: Text(
          'Raise Ticket',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 14))
          : RefreshIndicator(
              color: const Color(0xFF750000),
              onRefresh: _loadTickets,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Stats Card
                    _buildOverviewStatsCard(),
                    const SizedBox(height: 16),

                    // Filter Tabs
                    _buildFilterTabs(),
                    const SizedBox(height: 16),

                    // Ticket List
                    if (_filteredTickets.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredTickets.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          return _buildTicketCard(_filteredTickets[idx]);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE8DE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatColumn('Total', _counts['total'] ?? 0, const Color(0xFF222222)),
          _buildVerticalDivider(),
          _buildStatColumn('Open', _counts['open'] ?? 0, const Color(0xFFE65100)),
          _buildVerticalDivider(),
          _buildStatColumn('Resolved', _counts['resolved'] ?? 0, const Color(0xFF2E7D32)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, dynamic count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 36,
      width: 1,
      color: const Color(0xFFEFE8DE),
    );
  }

  Widget _buildFilterTabs() {
    return Row(
      children: [
        _buildFilterTabItem('all', 'All Tickets'),
        const SizedBox(width: 8),
        _buildFilterTabItem('open', 'Open'),
        const SizedBox(width: 8),
        _buildFilterTabItem('resolved', 'Resolved'),
      ],
    );
  }

  Widget _buildFilterTabItem(String key, String title) {
    final isSel = _selectedFilter == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF750000) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? const Color(0xFF750000) : const Color(0xFFEAE2D7),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
              color: isSel ? Colors.white : const Color(0xFF555555),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTicketDate(dynamic rawDate) {
    if (rawDate == null || rawDate.toString().isEmpty) return '';
    final str = rawDate.toString();
    try {
      final dt = DateTime.parse(str).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $ampm';
    } catch (_) {
      return str;
    }
  }

  /// Compact ticket item showing Subject & Status in the list view.
  /// On tap, opens a comprehensive details modal.
  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final ticketCode = ticket['ticket_code'] ?? 'TK-${ticket['id']}';
    final subject = ticket['subject'] ?? 'Support Inquiry';
    final status = (ticket['status'] ?? 'open').toString().toLowerCase();
    final date = _formatTicketDate(ticket['created_at']);

    Color statusColor = const Color(0xFFE65100);
    String statusLabel = 'Open';
    if (status == 'resolved') {
      statusColor = const Color(0xFF2E7D32);
      statusLabel = 'Resolved';
    } else if (status == 'in_progress') {
      statusColor = const Color(0xFF0288D1);
      statusLabel = 'In Progress';
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _showTicketDetailsModal(ticket),
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF750000).withValues(alpha: 0.08),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFE8DE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Subject & Status Pill
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            subject,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF222222),
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 0.8),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Row 2: Ticket Code • Formatted Date
                    Row(
                      children: [
                        Text(
                          ticketCode,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF750000),
                          ),
                        ),
                        if (date.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                color: const Color(0xFF888888),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                CupertinoIcons.chevron_forward,
                size: 15,
                color: Color(0xFFC4B8AA),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Full details modal opened on tapping any ticket card
  void _showTicketDetailsModal(Map<String, dynamic> ticket) {
    final ticketCode = ticket['ticket_code'] ?? 'TK-${ticket['id']}';
    final subject = ticket['subject'] ?? 'Support Inquiry';
    final message = ticket['message'] ?? '';
    final priority = (ticket['priority'] ?? 'low').toString().toLowerCase();
    final status = (ticket['status'] ?? 'open').toString().toLowerCase();
    final date = _formatTicketDate(ticket['created_at']);
    final adminReply = ticket['admin_reply'] ?? ticket['reply'] ?? '';
    final List<dynamic> screenshotUrls = ticket['screenshot_urls'] ?? [];

    Color priorityColor = const Color(0xFF1976D2);
    if (priority == 'urgent') priorityColor = const Color(0xFFD32F2F);
    if (priority == 'high') priorityColor = const Color(0xFFF57C00);

    Color statusColor = const Color(0xFFE65100);
    String statusLabel = 'Open';
    if (status == 'resolved') {
      statusColor = const Color(0xFF2E7D32);
      statusLabel = 'Resolved';
    } else if (status == 'in_progress') {
      statusColor = const Color(0xFF0288D1);
      statusLabel = 'In Progress';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFAF7F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6CBC0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Modal Top Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                child: Row(
                  children: [
                    Text(
                      ticketCode,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF750000),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: priorityColor.withValues(alpha: 0.35), width: 0.8),
                      ),
                      child: Text(
                        priority.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 0.8),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark, color: Color(0xFF666666), size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEBE3D7)),

              // Scrollable Details Body
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject Title
                      Text(
                        subject,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF222222),
                          height: 1.3,
                        ),
                      ),
                      if (date.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Raised on $date',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Description Section
                      Text(
                        'Description',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF444444),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEFE8DE)),
                        ),
                        child: Text(
                          message.isNotEmpty ? message : 'No description provided.',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFF333333),
                            height: 1.45,
                          ),
                        ),
                      ),

                      // Attached Screenshots
                      if (screenshotUrls.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Attached Screenshots (${screenshotUrls.length})',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF444444),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: screenshotUrls.length,
                            separatorBuilder: (c, i) => const SizedBox(width: 10),
                            itemBuilder: (context, idx) {
                              final url = screenshotUrls[idx].toString();
                              return InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(url, fit: BoxFit.contain),
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    url,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Container(
                                      width: 80,
                                      height: 80,
                                      color: const Color(0xFFF0EBE4),
                                      child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      // Admin Response
                      if (adminReply.toString().isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F6F0),
                            borderRadius: BorderRadius.circular(16),
                            border: const Border(
                              left: BorderSide(color: Color(0xFF750000), width: 4.0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(CupertinoIcons.reply, size: 16, color: Color(0xFF750000)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Admin Response',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF750000),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                adminReply.toString(),
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  color: const Color(0xFF2E2E2E),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3ECE4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.info_circle_fill, size: 16, color: Color(0xFF8D7B68)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your ticket is open. Our support team will reply shortly.',
                                  style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF6B5E52)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD6CBC0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Close',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF555555),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF750000).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.ticket,
                size: 32,
                color: Color(0xFF750000),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Support Tickets',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Need assistance with your account, photos, or matchmaking?\nTap "Raise Ticket" below to reach our support desk.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                color: const Color(0xFF777777),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF750000),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: _showRaiseTicketModal,
              icon: const Icon(CupertinoIcons.plus, size: 16),
              label: Text(
                'Raise Support Ticket',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
