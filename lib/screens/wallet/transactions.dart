import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_skeleton_loader.dart';

/// Screen: Wallet Transactions Statement (Credits & Debits)
/// Features:
/// 1. Comprehensive list of credits (+) and debits (-) with status indicators
/// 2. Interactive filters: All, Credits, Debits & Realtime Search
/// 3. Balance Summary Widget (Available, Total Inflow, Total Outflow)
/// 4. "View" button opening full Transaction Details Modal
/// 5. Single-click PDF Tax Invoice Download for Credits (Recharge / Topup) matching exact theme
class RaniTransactionsScreen extends StatefulWidget {
  final bool showAppBar;
  final String? initialFilter; // 'all', 'credit', 'debit'
  final VoidCallback? onOpenWallet;

  const RaniTransactionsScreen({
    super.key,
    this.showAppBar = true,
    this.initialFilter = 'all',
    this.onOpenWallet,
  });

  @override
  State<RaniTransactionsScreen> createState() => _RaniTransactionsScreenState();
}

class _RaniTransactionsScreenState extends State<RaniTransactionsScreen> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _selectedTab = 'all'; // 'all', 'credit', 'debit'
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _transactions = [];

  int _currentPage = 1;
  int _lastPage = 1;
  int _totalTransactions = 0;
  String? _downloadingTxnId;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialFilter ?? 'all';
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _fetchTransactions(reset: true);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTransactions({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
    }
    try {
      final res = await ApiService.instance.getWalletTransactions(
        type: _selectedTab == 'all' ? null : _selectedTab,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        page: _currentPage,
      );

      if (mounted && res['success'] == true) {
        final txData = res['transactions'];
        List<Map<String, dynamic>> list = [];
        int lastPage = 1;
        int total = 0;

        if (txData is Map) {
          final dataList = txData['data'];
          if (dataList is List) {
            list = dataList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
          lastPage = int.tryParse(txData['last_page']?.toString() ?? '1') ?? 1;
          total = int.tryParse(txData['total']?.toString() ?? '0') ?? list.length;
        } else if (txData is List) {
          list = txData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          total = list.length;
        }

        setState(() {
          if (reset) {
            _transactions = list;
          } else {
            _transactions.addAll(list);
          }
          _lastPage = lastPage;
          _totalTransactions = total;
        });
      }
    } catch (e) {
      debugPrint('[RaniTransactionsScreen] fetch error: $e');
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _lastPage) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _fetchTransactions(reset: false);
    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onTabChanged(String tab) {
    if (_selectedTab == tab) return;
    setState(() {
      _selectedTab = tab;
      _isLoading = true;
    });
    _fetchTransactions(reset: true).then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _onSearchChanged(String query) {
    _fetchTransactions(reset: true);
  }

  // ==========================================
  // INVOICE DOWNLOAD & OPENING HANDLER
  // ==========================================
  Future<void> _downloadInvoice(Map<String, dynamic> txn) async {
    final txnId = (txn['id'] ?? txn['transaction_id'])?.toString();
    if (txnId == null || txnId.isEmpty) return;

    final invYear = _formatDateYear(txn['created_at']);
    final rawId = (txn['id'] ?? '0').toString();
    final invNo = 'RANI-INV-$invYear-${rawId.padLeft(4, '0')}';

    setState(() => _downloadingTxnId = txnId);

    try {
      final res = await ApiService.instance.downloadTransactionInvoice(txnId, invoiceNo: invNo);

      if (!mounted) return;
      setState(() => _downloadingTxnId = null);

      if (res['success'] == true && res['file'] is File) {
        final File file = res['file'] as File;
        final fileName = res['fileName'] ?? 'Invoice.pdf';
        final location = res['location'] as String?;

        RaniAlert.success(context, 'Invoice downloaded: $fileName');

        // Show post-download modal offering to open or share the PDF
        if (mounted) {
          _showDownloadSuccessDialog(file, invNo, txnId, location: location);
        }
      } else {
        // Fallback: Open authenticated direct invoice view in browser
        final fallbackUrl = ApiService.instance.getInvoiceWebUrl(txnId);
        final uri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (mounted) {
            RaniAlert.info(context, 'Opening invoice in browser...');
          }
        } else {
          if (mounted) {
            RaniAlert.error(context, res['message'] ?? 'Could not download or open invoice.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadingTxnId = null);
        RaniAlert.error(context, 'Error downloading invoice: $e');
      }
    }
  }

  Future<void> _openInvoiceFile(File file, String txnId, String invNo) async {
    try {
      // 1. Primary: Open natively via OpenFilex (uses FileProvider on Android & DocumentInteractionController on iOS)
      final openRes = await OpenFilex.open(file.path, type: 'application/pdf');
      if (openRes.type == ResultType.done) {
        return;
      }

      debugPrint('[Invoice] OpenFilex status: ${openRes.type} - ${openRes.message}');

      // 2. Fallback: Share sheet so user can open in Google Drive, Mi PDF, Adobe, or save to any folder
      final fileName = file.path.split('/').last;
      final shareRes = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
          text: 'Tax Invoice: $invNo - Rani Matrimonial',
        ),
      );
      if (shareRes.status == ShareResultStatus.success) {
        return;
      }
    } catch (e) {
      debugPrint('[Invoice] Open error: $e');
    }

    // 3. Fallback: Browser external launch
    try {
      final webUrl = Uri.parse(ApiService.instance.getInvoiceWebUrl(txnId));
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _shareInvoiceFile(File file, String invNo) async {
    try {
      final fileName = file.path.split('/').last;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
          text: 'Tax Invoice: $invNo - Rani Matrimonial',
        ),
      );
    } catch (e) {
      debugPrint('[Invoice] Share error: $e');
    }
  }

  void _showDownloadSuccessDialog(File file, String invNo, String txnId, {String? location}) {
    final fileName = file.path.split('/').last;
    final whereSaved = location ?? (Platform.isAndroid ? 'Downloads folder' : 'Device Storage');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tax Invoice Saved',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tax Invoice ($invNo) has been saved successfully to your device.',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF4A4A4A), height: 1.35),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEFE8DE)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF750000), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '📁 $whereSaved',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF750000), width: 1.2),
                      foregroundColor: const Color(0xFF750000),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _shareInvoiceFile(file, invNo);
                    },
                    icon: const Icon(Icons.share_rounded, size: 15),
                    label: Text(
                      'Share / Save',
                      style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF750000),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openInvoiceFile(file, txnId, invNo);
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 15),
                    label: Text(
                      'Open PDF',
                      style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Close',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF888888),
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TRANSACTION DETAILS MODAL
  // ==========================================
  void _openTransactionDetailsModal(Map<String, dynamic> txn) {
    final isCredit = txn['type'] == 'credit';
    final amount = (txn['amount'] is num)
        ? (txn['amount'] as num).toDouble()
        : double.tryParse(txn['amount']?.toString().replaceAll(RegExp(r'[^0-9.-]'), '') ?? '') ?? 0.0;
    final balanceAfter = (txn['balance_after'] is num)
        ? (txn['balance_after'] as num).toDouble()
        : double.tryParse(txn['balance_after']?.toString().replaceAll(RegExp(r'[^0-9.-]'), '') ?? '') ?? 0.0;
    final txnId = (txn['transaction_id'] ?? txn['id'] ?? 'N/A').toString();
    final status = (txn['status'] ?? 'completed').toString().toUpperCase();
    final title = txn['title']?.toString() ?? (isCredit ? 'Wallet Recharge (Topup)' : 'Service Charge');
    final category = txn['category']?.toString() ?? (isCredit ? 'Recharge' : 'Deduction');
    final paymentMethod = txn['payment_method']?.toString() ?? (isCredit ? 'Online Payment / Razorpay' : 'Wallet Balance');
    final dateFormatted = _formatDateTime(txn['created_at']);
    final description = txn['description']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDownloadingThis = _downloadingTxnId == txn['id']?.toString() ||
                _downloadingTxnId == txn['transaction_id']?.toString();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF7F2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Top Drag Handle & Title
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(bottom: BorderSide(color: Color(0xFFEFE8DE))),
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD6CDC2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                    color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isCredit ? 'Topup Details' : 'Debit Details',
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E1E1E),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Color(0xFFA0988E), size: 24),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. Scrollable Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Amount Showcase Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCredit ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Transaction Amount',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    color: const Color(0xFF7A7067),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isCredit ? '+ ₹ ' : '- ₹ ',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: isCredit ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                                      ),
                                    ),
                                    Text(
                                      amount.toStringAsFixed(2),
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: isCredit ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: status == 'COMPLETED' || status == 'SUCCESS'
                                        ? const Color(0xFFE8F5E9)
                                        : (status == 'PENDING' ? const Color(0xFFFFF8E1) : const Color(0xFFFFEBEE)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: status == 'COMPLETED' || status == 'SUCCESS'
                                          ? const Color(0xFF2E7D32)
                                          : (status == 'PENDING' ? const Color(0xFFF57F17) : const Color(0xFFC62828)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Detailed Key-Value Table
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEFE8DE)),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                  label: 'Transaction ID',
                                  value: txnId,
                                  isCopyable: true,
                                ),
                                const Divider(height: 18, color: Color(0xFFF0EAE1)),
                                _buildDetailRow(
                                  label: 'Date & Time',
                                  value: dateFormatted,
                                ),
                                const Divider(height: 18, color: Color(0xFFF0EAE1)),
                                _buildDetailRow(
                                  label: 'Transaction Type',
                                  value: isCredit ? 'Topup History (Recharge)' : 'Debit (Deduction)',
                                  valueColor: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                ),
                                const Divider(height: 18, color: Color(0xFFF0EAE1)),
                                _buildDetailRow(
                                  label: 'Purpose / Title',
                                  value: title,
                                ),
                                const Divider(height: 18, color: Color(0xFFF0EAE1)),
                                _buildDetailRow(
                                  label: 'Category',
                                  value: category,
                                ),
                                const Divider(height: 18, color: Color(0xFFF0EAE1)),
                                _buildDetailRow(
                                  label: 'Payment Method',
                                  value: paymentMethod,
                                ),
                                if (balanceAfter > 0) ...[
                                  const Divider(height: 18, color: Color(0xFFF0EAE1)),
                                  _buildDetailRow(
                                    label: 'Closing Balance',
                                    value: '₹ ${balanceAfter.toStringAsFixed(2)}',
                                    valueColor: const Color(0xFF750000),
                                  ),
                                ],
                                if (description != null && description.isNotEmpty) ...[
                                  const Divider(height: 18, color: Color(0xFFF0EAE1)),
                                  _buildDetailRow(
                                    label: 'Notes / Remarks',
                                    value: description,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 3. EXTRA ACTION FOR CREDITS: DOWNLOAD TAX INVOICE (PDF)
                          if (isCredit) ...[
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF750000), Color(0xFF5A0000)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF750000).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: isDownloadingThis
                                    ? null
                                    : () async {
                                        setModalState(() {});
                                        await _downloadInvoice(txn);
                                        setModalState(() {});
                                      },
                                child: isDownloadingThis
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Generating Invoice PDF...',
                                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE5B842), size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Download Tax Invoice (PDF)',
                                            style: GoogleFonts.outfit(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                '• Official Computer-Generated GST & Tax Compliant Invoice •',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5,
                                  color: const Color(0xFF8C827A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isCopyable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: const Color(0xFF7A7067),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? const Color(0xFF1E1E1E),
                  ),
                ),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    RaniAlert.info(context, 'Transaction ID copied!');
                  },
                  child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF750000)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MAIN BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: const Color(0xFFFAF7F2),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(CupertinoIcons.back, color: Color(0xFF1E1E1E)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Wallet Statement',
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(CupertinoIcons.refresh, color: Color(0xFF750000), size: 20),
                  onPressed: _loadInitialData,
                ),
              ],
            )
          : null,
      body: RefreshIndicator(
        color: const Color(0xFF750000),
        onRefresh: _loadInitialData,
        child: Column(
          children: [
            const SizedBox(height: 12),

            // 1. Search Bar & Filter Tabs
            _buildFilterHeader(),

            const SizedBox(height: 8),

            // 2. Transactions List
            Expanded(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: RaniSkeletonList(itemCount: 6),
                    )
                  : _transactions.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _transactions.length + (_isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index == _transactions.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: CircularProgressIndicator(color: Color(0xFF750000), strokeWidth: 2),
                                ),
                              );
                            }
                            return _buildTransactionCard(_transactions[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET BUILDERS
  // ==========================================

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 1. Sleek Search Input Capsule
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFE8DFD5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E1E1E), fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search by TXN ID or purpose...',
                hintStyle: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF9E958C)),
                prefixIcon: const Icon(CupertinoIcons.search, size: 16, color: Color(0xFF750000)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled_solid, size: 16, color: Color(0xFFA0988E)),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 2. Refined Filter Segment Pills
          Row(
            children: [
              _buildTabPill('all', 'All Statements'),
              const SizedBox(width: 8),
              _buildTabPill('credit', 'Topup History'),
              const SizedBox(width: 8),
              _buildTabPill('debit', 'Debits (-)'),
            ],
          ),

          const SizedBox(height: 8),

          // 3. Subtle Count & Pagination Subtitle
          if (_totalTransactions > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_totalTransactions recorded entries',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF8C827A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Page $_currentPage of $_lastPage',
                    style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFFA0988E)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabPill(String tabKey, String label) {
    final isSelected = _selectedTab == tabKey;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabChanged(tabKey),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF750000) : Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isSelected ? const Color(0xFF750000) : const Color(0xFFE8DFD5),
              width: 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF750000).withValues(alpha: 0.22),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF5A4E46),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> txn) {
    final isCredit = txn['type'] == 'credit';
    final amount = (txn['amount'] is num)
        ? (txn['amount'] as num).toDouble()
        : double.tryParse(txn['amount']?.toString().replaceAll(RegExp(r'[^0-9.-]'), '') ?? '') ?? 0.0;
    final title = txn['title']?.toString() ?? (isCredit ? 'Wallet Recharge (Topup)' : 'Service Deduction');
    final txnId = (txn['transaction_id'] ?? txn['id'] ?? '').toString();
    final dateFormatted = _formatDateTime(txn['created_at']);
    final isDownloadingThis = _downloadingTxnId == txn['id']?.toString() ||
        _downloadingTxnId == txn['transaction_id']?.toString();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openTransactionDetailsModal(txn),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFE8DE), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Direction Icon Pill
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFBECE6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCredit
                            ? const Color(0xFF2E7D32).withValues(alpha: 0.2)
                            : const Color(0xFF750000).withValues(alpha: 0.15),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFF750000),
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title, TXN ID & Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 2.5),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'TXN: #$txnId',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7D7268),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('•', style: TextStyle(color: Color(0xFFB0A69C), fontSize: 10)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                dateFormatted,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF9E958C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Amount & Direction Pill
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isCredit
                            ? '+ ₹ ${_formatCurrency(amount)}'
                            : '- ₹ ${_formatCurrency(amount)}',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFF8B0014),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isCredit
                                  ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                                  : const Color(0xFF8C827A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              isCredit ? 'TOPUP' : 'DEBIT',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFF6B5E55),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            CupertinoIcons.chevron_forward,
                            size: 13,
                            color: Color(0xFFB0A69C),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // If Credit: Sleek Tax Invoice Download Bar
              if (isCredit) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: const Color(0xFFE5DDD0),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: Color(0xFFD4AF37),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'GST Tax Invoice Available',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5A4E46),
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: isDownloadingThis ? null : () => _downloadInvoice(txn),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF750000),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isDownloadingThis)
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              const SizedBox(width: 4),
                              Text(
                                isDownloadingThis ? 'Downloading...' : 'PDF Invoice',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3ECE2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: Color(0xFF750000),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No matching transactions'
                  : (_selectedTab == 'credit'
                      ? 'No topup history recorded yet'
                      : (_selectedTab == 'debit'
                          ? 'No debits recorded yet'
                          : 'No transactions statement found')),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try searching with another keyword or clearing search filter.'
                  : 'Recharge your Royal Wallet or use services to see entries here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF8C827A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================
  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final reg = RegExp(r'(\d+?)(?=(\d{3})+(?!\d))');
    final formattedInt = intPart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$formattedInt.$decPart';
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) return 'N/A';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final m = months[dt.month - 1];
      final day = dt.day.toString().padLeft(2, '0');
      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $m ${dt.year}, $hour12:$minute $ampm';
    } catch (_) {
      return raw.toString();
    }
  }

  String _formatDateYear(dynamic raw) {
    if (raw == null) return DateTime.now().year.toString();
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return dt.year.toString();
    } catch (_) {
      return DateTime.now().year.toString();
    }
  }
}
