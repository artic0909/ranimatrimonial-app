import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_matrimonial_loader.dart';

/// Screen: Contact Us
/// Contains the official contact form as on website, office info, and direct helplines.
class RaniContactUsScreen extends StatefulWidget {
  final bool showAppBar;
  const RaniContactUsScreen({super.key, this.showAppBar = true});

  @override
  State<RaniContactUsScreen> createState() => _RaniContactUsScreenState();
}

class _RaniContactUsScreenState extends State<RaniContactUsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final String _countryCode = '+91';

  bool _isSubmitting = false;

  Map<String, dynamic> _contactInfo = {
    'phone': '+91 62922 37202',
    'whatsapp': '+91 62922 37202',
    'support_email': 'support@ranimatrimonial.com',
    'address': 'Salt Lake Sector V, Kolkata, West Bengal 700091, India',
    'working_hours': 'Monday - Saturday: 10:00 AM - 7:00 PM IST',
  };

  List<dynamic> _faqs = [];

  @override
  void initState() {
    super.initState();
    _prefillCandidateData();
    _loadContactInfo();
  }

  void _prefillCandidateData() {
    final candidate = ApiService.instance.candidate;
    if (candidate != null) {
      final firstName = candidate['first_name'] ?? '';
      final lastName = candidate['last_name'] ?? '';
      final fullName = '$firstName $lastName'.trim();
      if (fullName.isNotEmpty) _nameCtrl.text = fullName;

      final email = candidate['email'] ?? '';
      if (email.isNotEmpty) _emailCtrl.text = email;

      final phone = candidate['phone'] ?? candidate['mobile'] ?? '';
      if (phone.isNotEmpty) {
        _mobileCtrl.text = phone.toString().replaceAll(RegExp(r'[^0-9]'), '');
      }
    }
  }

  Future<void> _loadContactInfo() async {
    try {
      final res = await ApiService.instance.getHelpCenter();
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          if (res['contact_info'] != null) {
            _contactInfo = Map<String, dynamic>.from(res['contact_info']);
          }
          if (res['faqs'] != null) {
            _faqs = res['faqs'] ?? [];
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    RaniMatrimonialLoader.show(context, message: 'Sending message...');
    setState(() => _isSubmitting = true);

    try {
      final res = await ApiService.instance.submitHelpQuery({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'country_code': _countryCode,
        'mobile': _mobileCtrl.text.trim(),
        'subject': _subjectCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
      });

      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      setState(() => _isSubmitting = false);

      if (res['success'] == true) {
        RaniAlert.success(
          context,
          res['message'] ?? 'Thank you! Your message has been submitted successfully.',
          title: 'Inquiry Sent',
        );
        _subjectCtrl.clear();
        _messageCtrl.clear();
      } else {
        RaniAlert.error(context, res['message'] ?? 'Failed to send message.');
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      setState(() => _isSubmitting = false);
      RaniAlert.error(context, 'Error: $e');
    }
  }

  Future<void> _launchUrlHelper(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
                'Contact Us',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Banner
            _buildContactHeaderCard(),
            const SizedBox(height: 18),

            // Quick Touch Helpline Cards
            _buildQuickHelplineCards(),
            const SizedBox(height: 20),

            // Official Inquiry Form Card
            _buildInquiryFormCard(),
            const SizedBox(height: 22),

            // FAQs Accordion
            if (_faqs.isNotEmpty) ...[
              Text(
                'Frequently Asked Questions',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 10),
              _buildFaqSection(),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B000B), Color(0xFF4A0005)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A0005).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5B842).withValues(alpha: 0.5), width: 1.5),
            ),
            child: const Icon(
              CupertinoIcons.phone_arrow_up_right,
              color: Color(0xFFE5B842),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We Are Here To Assist You',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Reach out for matchmaking help, account inquiries, or branch appointments.',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    color: const Color(0xFFFFD5D8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHelplineCards() {
    final phone = _contactInfo['phone'] ?? '+91 62922 37202';
    final email = _contactInfo['support_email'] ?? 'support@ranimatrimonial.com';
    final whatsapp = _contactInfo['whatsapp'] ?? '+91 62922 37202';

    return Row(
      children: [
        // Phone Call
        _buildActionTile(
          icon: CupertinoIcons.phone_fill,
          label: 'Call Us',
          subLabel: phone,
          color: const Color(0xFF2E7D32),
          onTap: () => _launchUrlHelper('tel:${phone.replaceAll(' ', '')}'),
        ),
        const SizedBox(width: 10),

        // WhatsApp
        _buildActionTile(
          icon: Icons.chat_rounded,
          label: 'WhatsApp',
          subLabel: 'Instant Chat',
          color: const Color(0xFF25D366),
          onTap: () {
            final clean = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
            _launchUrlHelper('https://wa.me/$clean');
          },
        ),
        const SizedBox(width: 10),

        // Email
        _buildActionTile(
          icon: CupertinoIcons.mail_solid,
          label: 'Email',
          subLabel: 'Send Mail',
          color: const Color(0xFF750000),
          onTap: () => _launchUrlHelper('mailto:$email'),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
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
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF777777),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInquiryFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE8DE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.paperplane_fill, size: 18, color: Color(0xFF750000)),
                const SizedBox(width: 8),
                Text(
                  'Send Us a Message',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF222222),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Fill out the form below and our relationship team will get back to you.',
              style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF777777)),
            ),
            const SizedBox(height: 18),

            // Full Name
            _buildFieldLabel('Full Name *'),
            _buildTextFormField(
              controller: _nameCtrl,
              hint: 'Enter your full name',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 14),

            // Email Address
            _buildFieldLabel('Email Address *'),
            _buildTextFormField(
              controller: _emailCtrl,
              hint: 'Enter your email address',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your email';
                if (!v.contains('@') || !v.contains('.')) return 'Please enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Mobile Number
            _buildFieldLabel('Mobile Number *'),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE4DAD0)),
                  ),
                  child: Text(
                    _countryCode,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextFormField(
                    controller: _mobileCtrl,
                    hint: '10-digit mobile number',
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().length < 7) {
                        return 'Enter a valid mobile number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Subject
            _buildFieldLabel('Subject *'),
            _buildTextFormField(
              controller: _subjectCtrl,
              hint: 'e.g. Account Help, Membership Question',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please specify a subject' : null,
            ),
            const SizedBox(height: 14),

            // Message
            _buildFieldLabel('Message * (At least 10 characters)'),
            _buildTextFormField(
              controller: _messageCtrl,
              hint: 'Describe your query or feedback in detail...',
              maxLines: 4,
              validator: (v) {
                if (v == null || v.trim().length < 10) {
                  return 'Please write at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF750000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _submitForm,
                child: Text(
                  'Submit Message',
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
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF222222)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFFAAAAAA)),
        filled: true,
        fillColor: const Color(0xFFFDFBF7),
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
      validator: validator,
    );
  }

  Widget _buildFaqSection() {
    return Column(
      children: _faqs.map((faq) {
        final q = faq['question'] ?? '';
        final a = faq['answer'] ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEFE8DE)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Text(
                q,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF222222),
                ),
              ),
              children: [
                Text(
                  a,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF555555),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
