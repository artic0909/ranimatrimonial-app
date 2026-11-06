import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/razorpay_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_matrimonial_loader.dart';
import '../../components/rani_skeleton_loader.dart';
import '../../components/rani_privacy_photo_widget.dart';

/// Screen: Candidate Details Screen (Matches Theme)
/// Features:
/// 0. Profile images carousel with bottom pill dots; tap image to view in full-screen pinch-zoom viewer
/// 1. About Myself section
/// 2. Match compatibility score (%) & specific matching criteria items
/// 3. Personal details (Gender, Height, Marital status, Mother tongue, Religion, Community/Caste, Sub community, Gotra, Manglik, Diet, Blood group)
/// 4. Education & career details (Highest qualification, Working with, Annual income, Profession)
/// 5. Family background (Father's profession, Mother's profession, Financial status, Family location)
/// 6. Fixed bottom action bar: Shortlist heart button & Connect / Send connection button
class RaniMatchDetailsScreen extends StatefulWidget {
  final String profileId;
  final Map<String, dynamic>? initialProfileData;

  const RaniMatchDetailsScreen({
    super.key,
    required this.profileId,
    this.initialProfileData,
  });

  @override
  State<RaniMatchDetailsScreen> createState() => _RaniMatchDetailsScreenState();
}

class _RaniMatchDetailsScreenState extends State<RaniMatchDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  Map<String, dynamic> _status = {};
  bool _isWpChatLoading = false;
  int _activePhotoIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    if (widget.initialProfileData != null) {
      _data = Map<String, dynamic>.from(widget.initialProfileData!);
      if (_data!['is_accepted'] == true ||
          _data!['request_type'] == 'accepted' ||
          _data!['status']?.toString().toLowerCase() == 'accepted') {
        _status['is_accepted'] = true;
      }
      if (_data!['is_wp_chat_accepted'] == true) {
        _status['is_wp_chat_accepted'] = true;
      }
      _isLoading = false;
    }
    _fetchDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    try {
      final res = await ApiService.instance.getProfileDetails(widget.profileId);
      if (mounted) {
        if (res['success'] == true) {
          final profileData = res['profile'] ?? res['candidate'] ?? res['data'];
          setState(() {
            if (profileData is Map) {
              final fetched = Map<String, dynamic>.from(profileData);
              if (res['status'] is Map) {
                fetched.addAll(Map<String, dynamic>.from(res['status']));
              }
              if (res['photos'] is List) {
                fetched['photos'] = res['photos'];
              }
              if (_data != null) {
                _data!.addAll(fetched);
              } else {
                _data = fetched;
              }
            }
            if (res['status'] is Map) {
              _status = Map<String, dynamic>.from(res['status']);
            }
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleShortlist() async {
    if (_data == null) return;
    final isCurrentlyShortlisted = _data!['is_shortlisted'] == true;
    final name = _data!['first_name'] ?? 'Candidate';

    setState(() {
      _data!['is_shortlisted'] = !isCurrentlyShortlisted;
    });

    try {
      final res = await ApiService.instance.toggleShortlist(widget.profileId);
      if (!mounted) return;

      if (res['success'] == true) {
        final isShortlisted = res['shortlisted'] == true;
        setState(() {
          _data!['is_shortlisted'] = isShortlisted;
        });
        RaniAlert.success(
          context,
          isShortlisted ? '$name added to your shortlist.' : 'Removed from shortlist.',
          title: isShortlisted ? 'Shortlisted' : 'Removed',
        );
      } else {
        setState(() {
          _data!['is_shortlisted'] = isCurrentlyShortlisted;
        });
        RaniAlert.error(context, res['message'] ?? 'Action failed.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _data!['is_shortlisted'] = isCurrentlyShortlisted;
        });
        RaniAlert.error(context, 'Error: $e');
      }
    }
  }

  Future<void> _sendRoyalInterest() async {
    if (_data == null) return;
    final name = _data!['first_name'] ?? 'Candidate';
    final candidateId = (_data!['candidate_code'] ?? _data!['profile_id'] ?? _data!['id']?.toString() ?? widget.profileId).toString();

    RaniMatrimonialLoader.show(context, message: 'Sending connection request to $name...');

    try {
      final res = await ApiService.instance.sendInterest(candidateId);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        setState(() {
          _data!['request_type'] = 'sent';
          _data!['is_connected'] = true;
          _status['is_sent_by_me'] = true;
        });
        RaniAlert.success(
          context,
          res['message'] ?? 'Connection request sent to $name!',
          title: 'Connected! 🎉',
        );
      } else {
        if (res['insufficient_balance'] == true || (res['message'] != null && res['message'].toString().toLowerCase().contains('balance'))) {
          _showInsufficientBalanceDialog(res['message'] ?? 'Please recharge your wallet.');
        } else {
          RaniAlert.error(context, res['message'] ?? 'Unable to send connection request.');
        }
      }
    } catch (e) {
      if (mounted) {
        RaniMatrimonialLoader.hide(context);
        RaniAlert.error(context, 'Error: $e');
      }
    }
  }

  Future<void> _respondRoyalInterest(String action) async {
    if (_data == null) return;
    final candidateId = (_data!['candidate_code'] ?? _data!['profile_id'] ?? _data!['id']?.toString() ?? widget.profileId).toString();
    final isAccept = action == 'accept';

    RaniMatrimonialLoader.show(
      context,
      message: isAccept ? 'Accepting connection request...' : 'Declining request...',
    );

    try {
      final res = await ApiService.instance.respondInterest(candidateId, action);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        setState(() {
          if (isAccept) {
            _data!['request_type'] = 'accepted';
            _data!['is_accepted'] = true;
            _status['is_accepted'] = true;
            _status['is_received_by_me'] = false;
          } else {
            _data!['request_type'] = 'declined';
            _data!['is_accepted'] = false;
            _status['is_received_by_me'] = false;
          }
        });
        RaniAlert.success(
          context,
          res['message'] ?? (isAccept ? 'Connection accepted successfully!' : 'Connection declined.'),
        );
      } else {
        RaniAlert.error(context, res['message'] ?? 'Action failed.');
      }
    } catch (e) {
      if (mounted) {
        RaniMatrimonialLoader.hide(context);
        RaniAlert.error(context, 'Error: $e');
      }
    }
  }

  void _showInsufficientBalanceDialog(String message) {
    RaniRazorpayService.showRechargeModal(
      context: context,
      defaultAmount: 100,
      subtitle: message,
      onPaymentSuccess: (amount) {
        _sendRoyalInterest();
      },
    );
  }

  String _getProfileCode() {
    final d = _data ?? {};
    final raw = (d['candidate_code'] ?? d['profile_id'] ?? d['id'] ?? widget.profileId).toString().trim();
    String clean = raw;
    while (clean.toUpperCase().startsWith('RMRM')) {
      clean = clean.substring(2);
    }
    if (!clean.toUpperCase().startsWith('RM')) {
      if (int.tryParse(clean) != null) {
        clean = 'RM${clean.padLeft(5, '0')}';
      } else {
        clean = 'RM$clean';
      }
    }
    return clean;
  }

  Future<void> _requestWhatsAppChat() async {
    final profileCode = _getProfileCode();
    final name = _data?['first_name'] ?? 'Candidate';

    setState(() => _isWpChatLoading = true);
    RaniMatrimonialLoader.show(context, message: 'Requesting WhatsApp chat access...');

    try {
      final res = await ApiService.instance.requestWhatsAppChat(profileCode);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      setState(() => _isWpChatLoading = false);

      if (res['success'] == true) {
        setState(() {
          _status['is_wp_chat_sent_by_me'] = true;
          _status['is_wp_chat_cooldown'] = true;
          _status['is_wp_chat_pending'] = true;
        });
        RaniAlert.success(
          context,
          res['message'] ?? 'WhatsApp chat request sent to $name! A notification has been delivered.',
          title: 'Request Sent! 💬',
        );
      } else {
        if (res['cooldown'] == true) {
          setState(() {
            _status['is_wp_chat_cooldown'] = true;
          });
        }
        RaniAlert.error(
          context,
          res['message'] ?? 'Unable to send WhatsApp chat request.',
          title: 'Notice',
        );
      }
    } catch (e) {
      if (mounted) {
        RaniMatrimonialLoader.hide(context);
        setState(() => _isWpChatLoading = false);
        RaniAlert.error(context, 'Error: $e');
      }
    }
  }

  Future<void> _respondWhatsAppChat(String action) async {
    final profileCode = _getProfileCode();
    final name = _data?['first_name'] ?? 'Candidate';

    RaniMatrimonialLoader.show(
      context,
      message: action == 'accept' ? 'Accepting WhatsApp chat request...' : 'Declining request...',
    );

    try {
      final res = await ApiService.instance.respondWhatsAppChat(profileCode, action);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        if (action == 'accept') {
          setState(() {
            _status['is_wp_chat_accepted'] = true;
            _status['is_wp_chat_received_by_me'] = false;
            _status['is_wp_chat_pending'] = false;
            if (res['unmasked_mobile'] != null) {
              _data?['mobile'] = res['unmasked_mobile'];
            }
          });
          RaniAlert.success(
            context,
            'You accepted the WhatsApp chat request with $name! Full verified contact particulars unlocked.',
            title: 'Chat Unlocked! 🎉',
          );
        } else {
          setState(() {
            _status['is_wp_chat_received_by_me'] = false;
            _status['is_wp_chat_pending'] = false;
          });
          RaniAlert.info(
            context,
            'WhatsApp chat request declined.',
            title: 'Request Declined',
          );
        }
      } else {
        RaniAlert.error(context, res['message'] ?? 'Unable to process request.');
      }
    } catch (e) {
      if (mounted) {
        RaniMatrimonialLoader.hide(context);
        RaniAlert.error(context, 'Error: $e');
      }
    }
  }

  Future<void> _openWhatsApp(String rawMobile) async {
    final clean = rawMobile.replaceAll(RegExp(r'[^0-9]'), '');
    final phone = clean.startsWith('91') ? clean : '91$clean';

    // Auto-copy number to clipboard for user convenience
    Clipboard.setData(ClipboardData(text: '+$phone'));

    final nativeWhatsappUri = Uri.parse('whatsapp://send?phone=$phone');
    final webWhatsappUri = Uri.parse('https://wa.me/$phone');

    try {
      // 1. First attempt direct native WhatsApp app via whatsapp:// scheme
      if (await canLaunchUrl(nativeWhatsappUri)) {
        await launchUrl(nativeWhatsappUri, mode: LaunchMode.externalApplication);
        return;
      }

      // 2. Fallback to universal wa.me link with externalApplication
      final launched = await launchUrl(webWhatsappUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(webWhatsappUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      // 3. Fallback attempt via platformDefault
      try {
        await launchUrl(webWhatsappUri, mode: LaunchMode.platformDefault);
        return;
      } catch (_) {}

      if (mounted) {
        RaniAlert.info(
          context,
          'Phone (+${phone.substring(0, 2)} ${phone.substring(2)}) has been copied to your clipboard. If WhatsApp didn\'t open automatically, please ensure WhatsApp is installed and restart the app.',
          title: 'WhatsApp Contact',
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    RaniAlert.info(context, '$label copied to clipboard');
  }

  String _maskPhone(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length >= 10) {
      final last10 = clean.substring(clean.length - 10);
      return '+91 ${last10.substring(0, 3)}XXXXX${last10.substring(8)}';
    }
    return '+91 629XXXXX08';
  }

  String _formatPhone(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length >= 10) {
      final last10 = clean.substring(clean.length - 10);
      return '+91 ${last10.substring(0, 5)} ${last10.substring(5)}';
    }
    return raw.isNotEmpty ? raw : '+91 62922 37208';
  }

  String _maskEmail(String raw) {
    if (raw.contains('@')) {
      final parts = raw.split('@');
      final username = parts[0];
      final domain = parts[1];
      if (username.length <= 2) {
        return '$username*****@$domain';
      }
      return '${username.substring(0, 2)}*****${username.substring(username.length - 1)}@$domain';
    }
    return 'ro*****a@gmail.com';
  }

  String _maskAddress(String addr) {
    if (addr.isEmpty) {
      return 'M Plaza, Near SBI Bank, *****, Amta Road';
    }
    final parts = addr.split(',');
    if (parts.length >= 3) {
      final list = <String>[];
      for (int i = 0; i < parts.length; i++) {
        final p = parts[i].trim();
        if (i == 0 || i == parts.length - 1) {
          list.add(p);
        } else {
          list.add('***** ${p.length > 3 ? p.substring(p.length - 3) : ''}'.trim());
        }
      }
      return list.join(', ');
    } else if (parts.length == 2) {
      return '${parts[0].trim()}, *****, ${parts[1].trim()}';
    }
    if (addr.length > 10) {
      return '${addr.substring(0, 4)} ********** ${addr.substring(addr.length - 4)}';
    }
    return '***** Protected Address *****';
  }

  String _maskPincode(String pin) {
    final clean = pin.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length >= 4) {
      return '${clean.substring(0, 3)}***';
    }
    return '711***';
  }

  List<String> _extractPhotos() {
    final List<String> list = [];
    if (_data == null) return list;

    if (_data!['photos'] is List && (_data!['photos'] as List).isNotEmpty) {
      for (final p in _data!['photos']) {
        if (p is String && p.trim().isNotEmpty) {
          list.add(p);
        } else if (p is Map && p['photo_path'] != null) {
          list.add(p['photo_path'].toString());
        }
      }
    }

    final singlePhoto = _data!['photo'] ?? _data!['profile_picture'];
    if (singlePhoto is String && singlePhoto.isNotEmpty && !list.contains(singlePhoto)) {
      list.insert(0, singlePhoto);
    }

    return list;
  }

  void _openFullScreenViewer(List<String> photos, int initialIndex) {
    if (photos.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenPhotoViewer(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _data == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF7F2),
        body: SafeArea(child: RaniSkeletonProfile()),
      );
    }

    final d = _data ?? {};
    final photos = _extractPhotos();
    final firstName = d['first_name'] ?? 'Candidate';
    final lastName = d['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final rawCode = (d['candidate_code'] ?? d['profile_id'] ?? d['id'] ?? widget.profileId).toString().trim();
    String cleanCode = rawCode;
    while (cleanCode.toUpperCase().startsWith('RMRM')) {
      cleanCode = cleanCode.substring(2);
    }
    if (!cleanCode.toUpperCase().startsWith('RM')) {
      if (int.tryParse(cleanCode) != null) {
        cleanCode = 'RM${cleanCode.padLeft(5, '0')}';
      } else {
        cleanCode = 'RM$cleanCode';
      }
    }
    final profileCode = cleanCode;
    final age = d['age']?.toString() ?? '24';
    final height = d['height']?.toString() ?? "5' 4\"";
    final profession = d['profession'] ?? d['designation'] ?? 'Professional';
    final city = d['city']?.toString() ?? 'Kolkata';
    final state = d['state']?.toString() ?? 'West Bengal';
    final locationText = (city.isNotEmpty && state.isNotEmpty) ? '$city, $state' : (city.isNotEmpty ? city : state);
    final isVerified = d['verified'] == true || d['is_verified'] == 1 || (d['bluetick'] != null && d['bluetick']['is_accept'] == 1);
    final matchScore = int.tryParse(d['match_score']?.toString() ?? d['match_percentage']?.toString() ?? '95') ?? 95;
    final isShortlisted = d['is_shortlisted'] == true || d['is_shortlisted'] == 1 || d['is_shortlisted'] == '1';
    final requestType = (d['request_type'] ?? _status['request_type'] ?? '').toString().toLowerCase();
    final status = _status;
    final isAccepted = status['is_accepted'] == true ||
        requestType == 'accepted' ||
        d['is_accepted'] == true ||
        (d['status']?.toString().toLowerCase() == 'accepted');
    final isReceived = requestType == 'received' ||
        status['is_received_by_me'] == true ||
        d['is_interest_received'] == true;
    final isSent = requestType == 'sent' ||
        status['is_sent_by_me'] == true ||
        d['is_interest_sent'] == true ||
        d['is_connected'] == true;
    final isConnected = isSent || isAccepted;
    final isWpChatAccepted = status['is_wp_chat_accepted'] == true ||
        d['is_wp_chat_accepted'] == true;
    final isWpChatSentByMe = status['is_wp_chat_sent_by_me'] == true ||
        d['is_wp_chat_sent_by_me'] == true;
    final isWpChatReceivedByMe = status['is_wp_chat_received_by_me'] == true ||
        d['is_wp_chat_received_by_me'] == true;
    final isWpChatCooldown = status['is_wp_chat_cooldown'] == true ||
        d['is_wp_chat_cooldown'] == true;

    // Contact details
    final rawMobile = (d['mobile'] ?? d['raw_mobile'] ?? d['details']?['mobile'] ?? d['details']?['raw_mobile'] ?? '').toString();
    final rawEmail = (d['email'] ?? d['details']?['email'] ?? '').toString();
    final rawAddress = (d['full_address'] ?? d['details']?['full_address'] ?? d['address'] ?? '').toString();
    final rawPincode = (d['pincode'] ?? d['details']?['pincode'] ?? d['zip_code'] ?? '711302').toString();
    final policeSt = (d['police_st'] ?? d['details']?['police_st'] ?? 'Panchla').toString();
    final residencyStatus = (d['residency_status'] ?? d['details']?['residency_status'] ?? 'Citizen').toString();

    // About Myself
    final aboutMyself = (d['about_yourself'] ?? d['about'] ?? d['bio'] ?? d['details']?['about_yourself'] ?? '').toString().trim();
    final displayBio = aboutMyself.isNotEmpty
        ? aboutMyself
        : 'I am a warm, values-driven individual with strong cultural and family values. Looking for a compatible and understanding partner to share life\'s beautiful journey.';

    // Personal details
    final gender = d['gender'] ?? 'Female';
    final maritalStatus = d['marital_status'] ?? d['marital'] ?? 'Never Married';
    final motherTongue = d['mother_tongue'] ?? 'Bengali';
    final religion = d['religion'] ?? 'Muslim';
    final community = d['community'] ?? d['caste'] ?? 'Sunni';
    final subCommunity = d['sub_community'] ?? d['sub_caste'] ?? d['sect'] ?? 'General';
    final gotra = d['gothra'] ?? d['gotra'] ?? d['details']?['gothra'] ?? 'Kashyap';
    final manglik = d['manglik'] ?? d['details']?['manglik'] ?? 'Non-Manglik';
    final diet = d['diet'] ?? 'Non-Vegetarian';
    final bloodGroup = d['blood_group'] ?? d['details']?['blood_group'] ?? 'O+';

    // Education & Career
    final highestQualification = d['highest_qualification'] ?? d['qualification'] ?? d['education'] ?? 'Post Graduate';
    final workingWith = d['working_with'] ?? d['details']?['working_with'] ?? d['employed_in'] ?? 'Private Company';
    final annualIncome = d['annual_income'] ?? d['income'] ?? '₹ 15 - 20 Lakh';

    // Family Background
    final fatherProfession = d['father_profession'] ?? d['father_occupation'] ?? d['details']?['father_profession'] ?? 'Business Owner';
    final motherProfession = d['mother_profession'] ?? d['mother_occupation'] ?? d['details']?['mother_profession'] ?? 'Homemaker';
    final familyType = d['family_type'] ?? d['details']?['family_type'] ?? 'Joint Family';
    final financialStatus = d['family_financial_status'] ?? d['details']?['family_financial_status'] ?? 'Upper Middle Class';
    final familyLocation = d['family_location'] ?? d['details']?['family_location'] ?? locationText;

    // Match criteria breakdown
    final List<String> matchReasons = [];
    if (d['match_reasons'] is List && (d['match_reasons'] as List).isNotEmpty) {
      for (final r in d['match_reasons']) {
        matchReasons.add(r.toString());
      }
    }
    if (matchReasons.isEmpty) {
      if (religion.isNotEmpty) matchReasons.add('$religion Religion Match');
      if (community.isNotEmpty && community.toLowerCase() != 'all') matchReasons.add('$community Community Compatibility');
      if (city.isNotEmpty) matchReasons.add('$city Resident Preference');
      if (diet.isNotEmpty) matchReasons.add('$diet Diet Lifestyle');
      if (motherTongue.isNotEmpty) matchReasons.add('$motherTongue Mother Tongue');
      matchReasons.add('Educational Compatibility');
    }

    final popResult = {
      'profile_id': widget.profileId,
      'is_shortlisted': isShortlisted,
      'request_type': isAccepted ? 'accepted' : (isReceived ? 'received' : (isSent ? 'sent' : 'none')),
      'is_sent': isSent,
      'is_accepted': isAccepted,
      'is_received': isReceived,
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, popResult);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF7F2),
        body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 0. Profile Images Carousel with bottom pill dots & tap to view full-screen
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Carousel View
                    SizedBox(
                      height: 380,
                      width: double.infinity,
                      child: photos.isNotEmpty
                          ? PageView.builder(
                              controller: _pageController,
                              itemCount: photos.length,
                              onPageChanged: (idx) => setState(() => _activePhotoIndex = idx),
                              itemBuilder: (context, idx) {
                                final isBlurred = RaniPhotoPrivacyHelper.shouldBlurGalleryPhoto(
                                  candidate: _data,
                                  photoIndex: idx,
                                );
                                return GestureDetector(
                                  onTap: isBlurred ? null : () => _openFullScreenViewer(photos, idx),
                                  child: RaniPrivacyPhotoWidget(
                                    imageUrl: photos[idx].toString(),
                                    isBlurred: isBlurred,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    lockText: idx == 0 ? 'Photo Protected' : 'Album Locked',
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: const Color(0xFFDED5C9),
                              child: const Center(
                                child: Icon(CupertinoIcons.person_fill, size: 80, color: Colors.white70),
                              ),
                            ),
                    ),

                    // Top Gradient Shadow for app bar buttons
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom subtle gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 70,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              const Color(0xFF150002).withValues(alpha: 0.65),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top Action Bar: Back button, Candidate ID pill, Tap to full-screen hint
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Button
                          GestureDetector(
                            onTap: () => Navigator.pop(context, popResult),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(CupertinoIcons.back, color: Colors.white, size: 20),
                            ),
                          ),

                          Row(
                            children: [
                              // Shortlist Heart Button
                              GestureDetector(
                                onTap: _toggleShortlist,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isShortlisted
                                        ? const Color(0xFFC62828).withValues(alpha: 0.85)
                                        : Colors.black.withValues(alpha: 0.45),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isShortlisted
                                          ? const Color(0xFFEF5350)
                                          : Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Icon(
                                    isShortlisted ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Full-screen zoom indicator
                              GestureDetector(
                                onTap: () => _openFullScreenViewer(photos, _activePhotoIndex),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(CupertinoIcons.fullscreen, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Carousel Pill Dots Indicator at the bottom
                    if (photos.length > 1)
                      Positioned(
                        bottom: 14,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            photos.length,
                            (idx) => AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _activePhotoIndex == idx ? 22 : 7,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _activePhotoIndex == idx
                                    ? const Color(0xFFE5B842) // Brand Gold
                                    : Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Candidate Main Header Card
                      _buildMainHeaderCard(
                        fullName: fullName,
                        age: age,
                        height: height,
                        profession: profession,
                        locationText: locationText,
                        isVerified: isVerified,
                        profileCode: profileCode,
                      ),

                      const SizedBox(height: 16),

                      // UNLOCKED CONTACT & RESIDENTIAL CARD (Highlighted for Accepted Match - matches website)
                      if (isAccepted) ...[
                        _buildVerifiedContactParticularsCard(
                          profileCode: profileCode,
                          rawMobile: rawMobile,
                          rawEmail: rawEmail,
                          rawAddress: rawAddress,
                          locationText: locationText,
                          rawPincode: rawPincode,
                          policeSt: policeSt,
                          residencyStatus: residencyStatus,
                          isWpChatAccepted: isWpChatAccepted,
                          isWpChatSentByMe: isWpChatSentByMe,
                          isWpChatReceivedByMe: isWpChatReceivedByMe,
                          isWpChatCooldown: isWpChatCooldown,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 2. Compatibility Match Score & What items matched
                      _buildMatchCompatibilitySection(
                        matchScore: matchScore,
                        matchReasons: matchReasons,
                      ),

                      const SizedBox(height: 16),

                      // 1. About Myself
                      _buildSectionCard(
                        icon: CupertinoIcons.sparkles,
                        title: 'About Myself',
                        child: Text(
                          displayBio,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            height: 1.55,
                            color: const Color(0xFF3A3A3A),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 3. Personal Details
                      _buildSectionCard(
                        icon: CupertinoIcons.person_crop_circle,
                        title: 'Personal Details',
                        child: Column(
                          children: [
                            _buildDetailRow('Gender', gender),
                            _buildDetailRow('Height', height),
                            _buildDetailRow('Marital Status', maritalStatus),
                            _buildDetailRow('Mother Tongue', motherTongue),
                            _buildDetailRow('Religion', religion),
                            _buildDetailRow('Community / Caste', community),
                            _buildDetailRow('Sub Community', subCommunity),
                            _buildDetailRow('Gotra', gotra),
                            _buildDetailRow('Manglik Status', manglik),
                            _buildDetailRow('Diet', diet),
                            _buildDetailRow('Blood Group', bloodGroup, isLast: true),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 4. Education & Career Details
                      _buildSectionCard(
                        icon: CupertinoIcons.briefcase,
                        title: 'Education & Career',
                        child: Column(
                          children: [
                            _buildDetailRow('Highest Qualification', highestQualification),
                            _buildDetailRow('Working With', workingWith),
                            _buildDetailRow('Profession / Role', profession),
                            _buildDetailRow('Annual Income', annualIncome, isLast: true),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 5. Family Background
                      _buildSectionCard(
                        icon: CupertinoIcons.person_3,
                        title: 'Family Background',
                        child: Column(
                          children: [
                            _buildDetailRow("Father's Profession", fatherProfession),
                            _buildDetailRow("Mother's Profession", motherProfession),
                            _buildDetailRow('Family Type', familyType),
                            _buildDetailRow('Financial Status', financialStatus),
                            _buildDetailRow('Family Location', familyLocation, isLast: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 6. Fixed Bottom Action Button (Full-width)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActionBar(
              isConnected: isConnected,
              isAccepted: isAccepted,
              isReceived: isReceived,
              isSent: isSent,
              isWpChatAccepted: isWpChatAccepted,
              isWpChatSentByMe: isWpChatSentByMe,
              isWpChatReceivedByMe: isWpChatReceivedByMe,
              isWpChatCooldown: isWpChatCooldown,
              rawMobile: rawMobile,
            ),
          ),
        ],
      ),
    ),
  );
  }

  /// Main Candidate Header Card
  Widget _buildMainHeaderCard({
    required String fullName,
    required String age,
    required String height,
    required String profession,
    required String locationText,
    required bool isVerified,
    required String profileCode,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DFD5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF750000).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  '$fullName, $age',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1E1E),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 20,
                  color: Color(0xFF2196F3), // Verified Blue Tick
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'ID: $profileCode',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8E8E93),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(CupertinoIcons.briefcase, size: 14, color: Color(0xFF750000)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$profession • $height',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A4A4A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(CupertinoIcons.location_solid, size: 14, color: Color(0xFF750000)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  locationText,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B6B6B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Compatibility Match Score & Matched Items
  Widget _buildMatchCompatibilitySection({
    required int matchScore,
    required List<String> matchReasons,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DFD5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF750000).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF750000).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.heart_circle_fill,
                        color: Color(0xFF750000),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Compatibility',
                        style: GoogleFonts.outfit(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Percentage Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE5B842), Color(0xFFD4AF37)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE5B842).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.star_fill, size: 12, color: Color(0xFF4A0000)),
                    const SizedBox(width: 4),
                    Text(
                      '$matchScore% Match',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4A0000),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Compatibility Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (matchScore / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFEFE8DE),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF750000)),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'What matches with your partner preferences:',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6E6E6E),
            ),
          ),

          const SizedBox(height: 8),

          // Matched item pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: matchReasons.map((reason) {
              final screenWidth = MediaQuery.of(context).size.width;
              final maxChipWidth = screenWidth > 64 ? screenWidth - 64 : 260.0;
              return Container(
                constraints: BoxConstraints(maxWidth: maxChipWidth),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE8DFD5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.checkmark_alt, size: 13, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        reason,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2B2B2B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Reusable Card Container for Sections
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DFD5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF750000).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF750000).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF750000), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Reusable Key-Value Detail Row
  Widget _buildDetailRow(String label, dynamic value, {bool isLast = false}) {
    final textValue = value?.toString() ?? 'Not Specified';
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7A7A7A),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              textValue.isNotEmpty ? textValue : 'Not Specified',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Verified Contact Particulars Card for Accepted Connection
  Widget _buildVerifiedContactParticularsCard({
    required String profileCode,
    required String rawMobile,
    required String rawEmail,
    required String rawAddress,
    required String locationText,
    required String rawPincode,
    required String policeSt,
    required String residencyStatus,
    required bool isWpChatAccepted,
    required bool isWpChatSentByMe,
    required bool isWpChatReceivedByMe,
    required bool isWpChatCooldown,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6EE7B7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon + Title + Subtitle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(CupertinoIcons.phone_fill, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified Contact Particulars',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isWpChatAccepted
                          ? 'Direct WhatsApp Communication Unlocked ✓'
                          : 'Mutual Connection Established • Request Direct WhatsApp Access',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF047857),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Header Action Banner (WhatsApp Request / Accept / Open)
          _buildWhatsAppActionBanner(
            rawMobile: rawMobile,
            isWpChatAccepted: isWpChatAccepted,
            isWpChatSentByMe: isWpChatSentByMe,
            isWpChatReceivedByMe: isWpChatReceivedByMe,
            isWpChatCooldown: isWpChatCooldown,
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFD1FAE5), height: 1, thickness: 1),
          const SizedBox(height: 14),

          // Two side-by-side cards: Mobile & Email
          Row(
            children: [
              // Mobile Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA7F3D0).withValues(alpha: 0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Mobile Phone / WhatsApp',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusPill(isProtected: !isWpChatAccepted),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              !isWpChatAccepted
                                  ? _maskPhone(rawMobile)
                                  : _formatPhone(rawMobile),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isWpChatAccepted)
                            GestureDetector(
                              onTap: () => _copyToClipboard(rawMobile, 'Mobile Number'),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(CupertinoIcons.doc_on_doc, size: 14, color: Color(0xFF059669)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Email Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA7F3D0).withValues(alpha: 0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Verified Email Address',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusPill(isProtected: !isWpChatAccepted),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              !isWpChatAccepted
                                  ? _maskEmail(rawEmail)
                                  : (rawEmail.isNotEmpty ? rawEmail : 'email@ranimatrimonial.com'),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isWpChatAccepted && rawEmail.isNotEmpty)
                            GestureDetector(
                              onTap: () => _copyToClipboard(rawEmail, 'Email'),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(CupertinoIcons.doc_on_doc, size: 14, color: Color(0xFF059669)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Full Residential Address Card (Masked with *** when protected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA7F3D0).withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Full Residential Address',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    _buildStatusPill(isProtected: !isWpChatAccepted),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  !isWpChatAccepted
                      ? _maskAddress(rawAddress)
                      : (rawAddress.isNotEmpty ? rawAddress : '$locationText, India'),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
                const SizedBox(height: 12),
                // 2x2 grid for City & State, Pincode, Police Station, Residency Status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('City & State', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          Text(
                            locationText.isNotEmpty ? locationText : 'Howrah, West Bengal',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pincode / Zip', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          Text(
                            !isWpChatAccepted ? _maskPincode(rawPincode) : (rawPincode.isNotEmpty ? rawPincode : '711302'),
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Police Station', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          Text(
                            policeSt.isNotEmpty ? policeSt : 'Panchla',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Residency Status', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          Text(
                            residencyStatus.isNotEmpty ? residencyStatus : 'Citizen',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Status Pill Widget (Protected vs Unlocked)
  Widget _buildStatusPill({required bool isProtected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isProtected ? const Color(0xFFECFDF5) : const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isProtected ? const Color(0xFFA7F3D0) : const Color(0xFF6EE7B7),
        ),
      ),
      child: Text(
        isProtected ? 'Protected' : 'Unlocked ✓',
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isProtected ? const Color(0xFF047857) : const Color(0xFF065F46),
        ),
      ),
    );
  }

  /// WhatsApp Action Banner inside the Contact Particulars Card
  Widget _buildWhatsAppActionBanner({
    required String rawMobile,
    required bool isWpChatAccepted,
    required bool isWpChatSentByMe,
    required bool isWpChatReceivedByMe,
    required bool isWpChatCooldown,
  }) {
    if (isWpChatAccepted) {
      return GestureDetector(
        onTap: () => _openWhatsApp(rawMobile),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF25D366), Color(0xFF128C7E)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25D366).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.chat_bubble_2_fill, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Chat on WhatsApp',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isWpChatReceivedByMe) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _respondWhatsAppChat('accept'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF25D366).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Accept WhatsApp Chat',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => _respondWhatsAppChat('decline'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Decline',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (isWpChatSentByMe || isWpChatCooldown) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.clock_fill, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              'WhatsApp Request Sent (Wait 6h)',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _isWpChatLoading ? null : _requestWhatsAppChat,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF25D366), Color(0xFF10B981)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isWpChatLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              const Icon(CupertinoIcons.chat_bubble_2_fill, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              _isWpChatLoading ? 'Sending Request...' : 'Request WhatsApp Chat',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 6. Fixed Bottom Action Bar: Send Connection / WhatsApp Chat (Full Width)
  Widget _buildBottomActionBar({
    required bool isConnected,
    required bool isAccepted,
    required bool isReceived,
    required bool isSent,
    required bool isWpChatAccepted,
    required bool isWpChatSentByMe,
    required bool isWpChatReceivedByMe,
    required bool isWpChatCooldown,
    required String rawMobile,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 6 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFEFE8DE), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: isAccepted
            ? (isWpChatAccepted
                ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _openWhatsApp(rawMobile),
                    icon: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 18),
                    label: Text(
                      'Chat on WhatsApp',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  )
                : (isWpChatReceivedByMe
                    ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => _respondWhatsAppChat('accept'),
                        icon: const Icon(CupertinoIcons.checkmark_alt, size: 18),
                        label: Text(
                          'Accept WhatsApp Chat',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : (isWpChatSentByMe || isWpChatCooldown
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCBD5E1),
                              foregroundColor: const Color(0xFF475569),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: null,
                            icon: const Icon(CupertinoIcons.clock, size: 18),
                            label: Text(
                              'Request Sent (Wait 6h)',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _isWpChatLoading ? null : _requestWhatsAppChat,
                            icon: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 18),
                            label: Text(
                              'Request WhatsApp Chat',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ))))
            : isReceived
                ? Row(
                    children: [
                      // Reject Button
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _respondRoyalInterest('decline'),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0x59E11D48), width: 1.2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x14E11D48),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(CupertinoIcons.xmark_circle_fill, size: 18, color: Color(0xFFBE123C)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Reject',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFBE123C),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Accept Button
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _respondRoyalInterest('accept'),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF15803D), Color(0xFF22C55E)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x5915803D),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 19, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Accept',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : isSent
                    ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCBD5E1),
                          foregroundColor: const Color(0xFF475569),
                          disabledBackgroundColor: const Color(0xFFCBD5E1),
                          disabledForegroundColor: const Color(0xFF475569),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: null,
                        icon: const Icon(CupertinoIcons.clock, size: 18, color: Color(0xFF475569)),
                        label: Text(
                          'Wait for Acceptance',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF750000), // Royal burgundy
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _sendRoyalInterest,
                        icon: const Icon(
                          CupertinoIcons.heart,
                          size: 18,
                        ),
                        label: Text(
                          'Connect Now',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
      ),
    );
  }
}

/// 0. Full-Screen Interactive Photo Viewer with Pinch-Zoom
class FullScreenPhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const FullScreenPhotoViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<FullScreenPhotoViewer> {
  late int _currentIndex;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Interactive PageView
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, i) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                child: Center(
                  child: Image.network(
                    widget.photos[i],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      CupertinoIcons.photo,
                      size: 80,
                      color: Colors.white38,
                    ),
                  ),
                ),
              );
            },
          ),

          // Top Bar with Close button and Page Counter
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 20),
                  ),
                ),

                // Counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.photos.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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
