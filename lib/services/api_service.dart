import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  factory ApiService() => instance;

  static const String baseUrl = 'https://ranimatrimonial.com/api';

  static const String _keyToken = 'auth_token';
  static const String _keyCandidate = 'candidate_data';

  String? _token;
  Map<String, dynamic>? _candidate;

  final ValueNotifier<Map<String, dynamic>?> candidateNotifier = ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<double> walletBalanceNotifier = ValueNotifier<double>(0.0);

  String? get token => _token;
  Map<String, dynamic>? get candidate => _candidate;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// Safely format any photo/avatar URL (handles local dev domains, relative storage paths, and absolute URLs)
  static String formatImageUrl(dynamic raw) {
    if (raw == null) return '';
    final urlStr = raw.toString().trim();
    if (urlStr.isEmpty) return '';
    if (urlStr.startsWith('http://') || urlStr.startsWith('https://')) {
      if (urlStr.contains('ranimatrimonial.test') ||
          urlStr.contains('localhost') ||
          urlStr.contains('127.0.0.1')) {
        final serverBase = baseUrl.replaceAll('/api', '');
        final path = urlStr.replaceFirst(RegExp(r'^https?://[^/]+/?'), '');
        return '$serverBase/$path';
      }
      return urlStr;
    }
    final serverBase = baseUrl.replaceAll('/api', '');
    return '$serverBase/storage/${urlStr.replaceFirst(RegExp(r'^/?(storage/)?'), '')}';
  }

  /// Accurate profile completeness percentage calculation (shared across Home & Profile screens)
  static int calculateProfileCompleteness(Map<String, dynamic>? candidate) {
    if (candidate == null) return 40;

    final criticalFields = [
      candidate['first_name'],
      candidate['last_name'],
      candidate['dob'],
      candidate['gender'],
      candidate['religion'],
      candidate['community'],
      candidate['city'],
      candidate['state'],
      candidate['highest_qualification'],
      candidate['profession'],
      candidate['annual_income'],
      candidate['about_yourself'] ?? candidate['about_me'] ?? candidate['about'],
      candidate['profile_picture'] ?? candidate['profile_picture_url'] ?? candidate['photo'],
      candidate['marital_status'],
      candidate['height'],
      candidate['diet'],
    ];

    int filledCount = 0;
    for (final f in criticalFields) {
      if (f == null) continue;
      final str = f.toString().trim();
      if (str.isNotEmpty && str != '-' && str != 'null') {
        filledCount++;
      }
    }

    final pct = ((filledCount / criticalFields.length) * 100).round();
    return pct.clamp(20, 100);
  }

  static double _extractBalance(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    final clean = raw.toString().replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  /// Initialize and load saved session from local SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_keyToken);
      final candidateJson = prefs.getString(_keyCandidate);
      if (candidateJson != null && candidateJson.isNotEmpty) {
        _candidate = jsonDecode(candidateJson) as Map<String, dynamic>;
        candidateNotifier.value = _candidate;
        final rawBal = _candidate?['wallet']?['avl_balance'] ?? _candidate?['avl_balance'];
        if (rawBal != null) {
          walletBalanceNotifier.value = _extractBalance(rawBal);
        }
      }
      debugPrint('[ApiService] Initialized. IsAuthenticated: $isAuthenticated');
    } catch (e) {
      debugPrint('[ApiService] Init error: $e');
    }
  }

  /// Save session to SharedPreferences
  Future<void> saveSession(String token, Map<String, dynamic> candidate) async {
    _token = token;
    _candidate = candidate;
    candidateNotifier.value = Map<String, dynamic>.from(candidate);
    final rawBal = candidate['wallet']?['avl_balance'] ?? candidate['avl_balance'];
    if (rawBal != null) {
      walletBalanceNotifier.value = _extractBalance(rawBal);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyCandidate, jsonEncode(candidate));
    } catch (e) {
      debugPrint('[ApiService] Save session error: $e');
    }
  }

  /// Update cached candidate data
  Future<void> updateCachedCandidate(Map<String, dynamic> candidate) async {
    _candidate = candidate;
    candidateNotifier.value = Map<String, dynamic>.from(candidate);
    final rawBal = candidate['wallet']?['avl_balance'] ?? candidate['avl_balance'];
    if (rawBal != null) {
      walletBalanceNotifier.value = _extractBalance(rawBal);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCandidate, jsonEncode(candidate));
    } catch (e) {
      debugPrint('[ApiService] Update candidate cache error: $e');
    }
  }

  /// Clear session on logout
  Future<void> clearSession() async {
    _token = null;
    _candidate = null;
    candidateNotifier.value = null;
    walletBalanceNotifier.value = 0.0;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyCandidate);
    } catch (e) {
      debugPrint('[ApiService] Clear session error: $e');
    }
  }

  /// Ensure session token and candidate data are loaded from storage
  Future<void> _ensureAuthLoaded() async {
    if (_token == null || _token!.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString(_keyToken);
        final candidateJson = prefs.getString(_keyCandidate);
        if (_candidate == null && candidateJson != null && candidateJson.isNotEmpty) {
          _candidate = jsonDecode(candidateJson) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
  }

  /// Standard Headers
  Map<String, String> get _headers {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (isAuthenticated) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  /// Send WhatsApp OTP for Login
  Future<Map<String, dynamic>> sendOtp(String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('$baseUrl/send-otp');

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'mobile': cleanMobile}),
    );

    return _processResponse(response);
  }

  /// Verify OTP and Login
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('$baseUrl/verify-otp');

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'mobile': cleanMobile,
        'otp': otp,
      }),
    );

    final data = _processResponse(response);
    if (data['success'] == true && data['token'] != null) {
      await saveSession(
        data['token'] as String,
        (data['candidate'] ?? {}) as Map<String, dynamic>,
      );
    }
    return data;
  }

  /// Logout candidate
  Future<Map<String, dynamic>> logout() async {
    try {
      if (isAuthenticated) {
        final uri = Uri.parse('$baseUrl/logout');
        await http.post(uri, headers: _headers);
      }
    } catch (e) {
      debugPrint('[ApiService] Logout remote error: $e');
    } finally {
      await clearSession();
    }
    return {'success': true, 'message': 'Logged out successfully.'};
  }

  // ==========================================
  // REGISTRATION FLOWS
  // ==========================================

  /// Check if user exists by mobile, email, or Aadhar
  Future<Map<String, dynamic>> checkUserExists({
    String? mobile,
    String? email,
    String? aadharNumber,
  }) async {
    final uri = Uri.parse('$baseUrl/check-user-exists');
    final Map<String, dynamic> body = {};

    if (aadharNumber != null && aadharNumber.isNotEmpty) {
      body['aadhar_number'] = aadharNumber.replaceAll(RegExp(r'[^0-9]'), '');
    } else {
      if (mobile != null) {
        body['mobile'] = mobile.replaceAll(RegExp(r'[^0-9]'), '');
      }
      if (email != null) {
        body['email'] = email.trim();
      }
    }

    final response = await http.post(uri, headers: _headers, body: jsonEncode(body));
    return _processResponse(response);
  }

  /// Send WhatsApp OTP for Registration
  Future<Map<String, dynamic>> sendRegistrationOtp(String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('$baseUrl/send-registration-otp');

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'mobile': cleanMobile}),
    );

    return _processResponse(response);
  }

  /// Verify Registration OTP
  Future<Map<String, dynamic>> verifyRegistrationOtp(String mobile, String otp) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('$baseUrl/verify-registration-otp');

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'mobile': cleanMobile,
        'otp': otp,
      }),
    );

    return _processResponse(response);
  }

  /// Send Selfie Link via WhatsApp
  Future<Map<String, dynamic>> sendSelfieLink(String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('$baseUrl/send-selfie-link');

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'mobile': cleanMobile}),
    );

    return _processResponse(response);
  }

  /// Save phone selfie to cache
  Future<Map<String, dynamic>> savePhoneSelfie(String mobile, String selfieData) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('$baseUrl/save-phone-selfie');

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'mobile': cleanMobile,
        'selfie_data': selfieData,
      }),
    );

    return _processResponse(response);
  }

  /// Check selfie verification polling status
  Future<Map<String, dynamic>> checkSelfieStatus(String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('$baseUrl/check-selfie-status?mobile=$cleanMobile');

    final response = await http.get(uri, headers: _headers);
    return _processResponse(response);
  }

  Map<String, dynamic>? _cachedRegistrationOptions;
  Map<String, dynamic>? get cachedRegistrationOptions => _cachedRegistrationOptions;

  /// Fetch Master Dropdown Options for Registration & Profile screens
  Future<Map<String, dynamic>> getRegistrationOptions() async {
    if (_cachedRegistrationOptions != null) {
      return {'success': true, 'data': _cachedRegistrationOptions};
    }
    final uri = Uri.parse('$baseUrl/registration-options');
    final response = await http.get(uri, headers: _headers);
    final data = _processResponse(response);
    if (data['success'] == true && data['data'] != null && data['data'] is Map) {
      _cachedRegistrationOptions = data['data'] as Map<String, dynamic>;
    }
    return data;
  }

  /// Final Registration
  Future<Map<String, dynamic>> registerFinal(
    Map<String, dynamic> fields, {
    File? profilePictureFile,
    File? selfieImageFile,
    String? selfieData,
  }) async {
    final uri = Uri.parse('$baseUrl/register');

    if (profilePictureFile != null || selfieImageFile != null) {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Accept': 'application/json',
      });

      fields.forEach((key, value) {
        if (value != null) {
          if (value is List) {
            request.fields[key] = jsonEncode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      if (profilePictureFile != null && await profilePictureFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_picture', profilePictureFile.path),
        );
      }

      if (selfieImageFile != null && await selfieImageFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('selfie_image', selfieImageFile.path),
        );
      } else if (selfieData != null) {
        request.fields['selfie_data'] = selfieData;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = _processResponse(response);

      if (data['success'] == true && data['token'] != null) {
        await saveSession(
          data['token'] as String,
          (data['candidate'] ?? {}) as Map<String, dynamic>,
        );
      }
      return data;
    } else {
      final Map<String, dynamic> body = Map.from(fields);
      if (selfieData != null) {
        body['selfie_data'] = selfieData;
      }

      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );

      final data = _processResponse(response);
      if (data['success'] == true && data['token'] != null) {
        await saveSession(
          data['token'] as String,
          (data['candidate'] ?? {}) as Map<String, dynamic>,
        );
      }
      return data;
    }
  }

  // ==========================================
  // DASHBOARD & CANDIDATE PROFILE
  // ==========================================

  /// Fetch candidate dashboard metrics, matches, notifications
  Future<Map<String, dynamic>> getDashboard() async {
    await _ensureAuthLoaded();
    try {
      final uri = Uri.parse('$baseUrl/dashboard');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      final data = _processResponse(response);
      if (data['success'] == true && data['data'] != null && data['data']['candidate'] != null) {
        await updateCachedCandidate(data['data']['candidate'] as Map<String, dynamic>);
      }
      return data;
    } catch (e) {
      debugPrint('[ApiService] getDashboard error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Fetch full candidate profile
  Future<Map<String, dynamic>> getMyProfile() async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/my-profile');
    final response = await http.get(uri, headers: _headers);
    final data = _processResponse(response);
    if (data['success'] == true && data['candidate'] != null) {
      await updateCachedCandidate(data['candidate'] as Map<String, dynamic>);
    }
    return data;
  }

  /// Update Profile Section or fields
  Future<Map<String, dynamic>> updateProfile(String? section, Map<String, dynamic> fields) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/update-profile');
    final Map<String, dynamic> body = Map.from(fields);
    if (section != null && section.isNotEmpty) {
      body['section'] = section;
    }

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    final data = _processResponse(response);
    if (data['success'] == true && data['candidate'] != null) {
      await updateCachedCandidate(data['candidate'] as Map<String, dynamic>);
    }
    return data;
  }

  /// Upload Profile Picture
  Future<Map<String, dynamic>> uploadProfilePicture(File file) async {
    final uri = Uri.parse('$baseUrl/upload-profile-picture');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      if (isAuthenticated) 'Authorization': 'Bearer $_token',
    });

    request.files.add(await http.MultipartFile.fromPath('profile_picture', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = _processResponse(response);
    if (data['success'] == true) {
      if (data['candidate'] != null && data['candidate'] is Map<String, dynamic>) {
        await updateCachedCandidate(Map<String, dynamic>.from(data['candidate']));
      } else {
        final newPic = data['profile_picture'] ?? data['profile_picture_url'] ?? data['image_url'] ?? data['url'] ?? data['photo'];
        if (newPic != null && _candidate != null) {
          final cand = Map<String, dynamic>.from(_candidate!);
          cand['profile_picture'] = newPic.toString();
          cand['profile_picture_url'] = newPic.toString();
          await updateCachedCandidate(cand);
        }
      }
    }
    return data;
  }

  // ==========================================
  // GALLERY PHOTOS
  // ==========================================

  /// Get candidate photos
  Future<Map<String, dynamic>> getMyPhotos() async {
    await _ensureAuthLoaded();
    try {
      final uri = Uri.parse('$baseUrl/my-photos');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      debugPrint('[ApiService] getMyPhotos error: $e');
      return {'success': false, 'message': 'Failed to load photos: $e'};
    }
  }

  /// Upload gallery photos
  Future<Map<String, dynamic>> uploadGalleryPhotos(List<File> files) async {
    await _ensureAuthLoaded();
    try {
      final uri = Uri.parse('$baseUrl/upload-gallery-photos');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Accept': 'application/json',
        if (isAuthenticated) 'Authorization': 'Bearer $_token',
      });

      for (final file in files) {
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath('photos[]', file.path));
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      debugPrint('[ApiService] uploadGalleryPhotos error: $e');
      return {'success': false, 'message': 'Failed to upload photos: $e'};
    }
  }

  /// Set gallery photo as main profile photo
  Future<Map<String, dynamic>> setProfilePhoto(dynamic photoId) async {
    await _ensureAuthLoaded();
    try {
      final uri = Uri.parse('$baseUrl/set-profile-photo');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({'photo_id': photoId}),
      ).timeout(const Duration(seconds: 10));
      final res = _processResponse(response);
      if (res['success'] == true) {
        if (res['candidate'] != null && res['candidate'] is Map<String, dynamic>) {
          await updateCachedCandidate(Map<String, dynamic>.from(res['candidate']));
        } else {
          final newPic = res['profile_picture'] ?? res['profile_picture_url'] ?? res['image_url'] ?? res['url'] ?? res['photo'];
          if (newPic != null && _candidate != null) {
            final cand = Map<String, dynamic>.from(_candidate!);
            cand['profile_picture'] = newPic.toString();
            cand['profile_picture_url'] = newPic.toString();
            await updateCachedCandidate(cand);
          }
        }
      }
      return res;
    } catch (e) {
      debugPrint('[ApiService] setProfilePhoto error: $e');
      return {'success': false, 'message': 'Failed to set profile photo: $e'};
    }
  }

  /// Delete photo from gallery
  Future<Map<String, dynamic>> deletePhoto(dynamic photoId) async {
    await _ensureAuthLoaded();
    try {
      final uri = Uri.parse('$baseUrl/delete-photo');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({'photo_id': photoId}),
      ).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      debugPrint('[ApiService] deletePhoto error: $e');
      return {'success': false, 'message': 'Failed to delete photo: $e'};
    }
  }

  /// Update Photo & Album privacy settings
  Future<Map<String, dynamic>> updatePhotoSettings({
    required String photoPrivacy,
    required String albumPrivacy,
  }) async {
    await _ensureAuthLoaded();
    try {
      final uri = Uri.parse('$baseUrl/update-photo-settings');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'photo_privacy': photoPrivacy,
          'album_privacy': albumPrivacy,
        }),
      ).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      debugPrint('[ApiService] updatePhotoSettings error: $e');
      return {'success': false, 'message': 'Failed to update photo settings: $e'};
    }
  }

  // ==========================================
  // BLUE TICK VERIFICATION
  // ==========================================

  /// Get Blue Tick Verification details
  Future<Map<String, dynamic>> getBlueTickVerification() async {
    final uri = Uri.parse('$baseUrl/bluetick-verification');
    final response = await http.get(uri, headers: _headers);
    return _processResponse(response);
  }

  /// Alias for getBlueTickVerification
  Future<Map<String, dynamic>> showBlueTickVerification() => getBlueTickVerification();

  /// Validate Aadhaar number
  Future<Map<String, dynamic>> validateAadhar(String aadharNumber) async {
    final uri = Uri.parse('$baseUrl/validate-aadhar');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'aadhar_number': aadharNumber}),
    );
    return _processResponse(response);
  }

  /// Submit Blue Tick Aadhaar documents
  Future<Map<String, dynamic>> submitBlueTickVerification({
    required String aadharNumber,
    required File frontFile,
    required File backFile,
  }) async {
    final uri = Uri.parse('$baseUrl/submit-bluetick-verification');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      if (isAuthenticated) 'Authorization': 'Bearer $_token',
    });

    request.fields['aadhar_number'] = aadharNumber;
    request.files.add(await http.MultipartFile.fromPath('aadhar_photo_front', frontFile.path));
    request.files.add(await http.MultipartFile.fromPath('aadhar_photo_back', backFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response);
  }

  /// Mark notification read
  Future<Map<String, dynamic>> markNotificationRead(dynamic notificationId) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/notifications/$notificationId/read');
    final response = await http.post(uri, headers: _headers);
    return _processResponse(response);
  }

  /// Clear all notifications
  Future<Map<String, dynamic>> clearAllNotifications() async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/notifications/clear-all');
    final response = await http.post(uri, headers: _headers);
    return _processResponse(response);
  }

  /// Register Device FCM Token with backend for background OS push notifications
  Future<Map<String, dynamic>> saveFcmToken(String fcmToken) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/save-fcm-token');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'fcm_token': fcmToken}),
    );
    return _processResponse(response);
  }

  // ==========================================
  // MATCHES & CONNECTIONS
  // ==========================================

  /// Fetch candidate matches by tab ('all', 'new', 'shortlisted', 'connected', etc.)
  Future<Map<String, dynamic>> getMatches({String tab = 'all', int page = 1}) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/matches?tab=$tab&page=$page');
    final response = await http.get(uri, headers: _headers);
    return _processResponse(response);
  }

  /// Get candidate profile details by token or ID
  Future<Map<String, dynamic>> getProfileDetails(dynamic id) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/matches/profile/$id');
    final response = await http.get(uri, headers: _headers);
    return _processResponse(response);
  }

  /// Send Interest / Connection Request
  Future<Map<String, dynamic>> sendInterest(String profileId) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/matches/send-interest');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'profile_id': profileId}),
    );
    return _processResponse(response);
  }

  /// Respond to an Interest (accept / decline)
  Future<Map<String, dynamic>> respondInterest(String profileId, String action) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/matches/respond-interest');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'profile_id': profileId,
        'action': action,
      }),
    );
    return _processResponse(response);
  }

  /// Toggle candidate shortlist
  Future<Map<String, dynamic>> toggleShortlist(String profileId) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/matches/toggle-shortlist');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'profile_id': profileId}),
    );
    return _processResponse(response);
  }

  /// Request WhatsApp Chat unlock
  Future<Map<String, dynamic>> requestWhatsAppChat(String profileId) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/matches/request-whatsapp-chat');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'profile_id': profileId}),
    );
    return _processResponse(response);
  }

  /// Respond to WhatsApp Chat unlock request (accept / decline)
  Future<Map<String, dynamic>> respondWhatsAppChat(String profileId, String action) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/matches/respond-whatsapp-chat');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'profile_id': profileId,
        'action': action,
      }),
    );
    return _processResponse(response);
  }

  // ==========================================
  // INBOX
  // ==========================================

  /// Fetch Inbox connection requests ('received', 'accepted', 'declined', 'sent')
  Future<Map<String, dynamic>> getInbox({String tab = 'received'}) async {
    await _ensureAuthLoaded();
    try {
      final uri = Uri.parse('$baseUrl/inbox?tab=$tab');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      debugPrint('[ApiService] getInbox error: $e');
      return {'success': false, 'message': 'Connection error: $e', 'requests': [], 'counts': {}};
    }
  }

  // ==========================================
  // SEARCH & FILTERS
  // ==========================================

  /// Get search filter master options
  Future<Map<String, dynamic>> getSearchOptions() async {
    final uri = Uri.parse('$baseUrl/search/options');
    final response = await http.get(uri, headers: _headers);
    return _processResponse(response);
  }

  /// Search candidate profiles dynamically
  Future<Map<String, dynamic>> searchProfiles(Map<String, dynamic> filters) async {
    final uri = Uri.parse('$baseUrl/search/filter');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(filters),
    );
    return _processResponse(response);
  }

  // ==========================================
  // ROYAL WALLET
  // ==========================================

  /// Fetch wallet balance, summary and recharge plans
  Future<Map<String, dynamic>> getWallet() async {
    await _ensureAuthLoaded();
    try {
      final uri = Uri.parse('$baseUrl/wallet');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      final res = _processResponse(response);
      if (res['success'] == true && res['wallet'] != null) {
        final bal = _extractBalance(res['wallet']['avl_balance']);
        walletBalanceNotifier.value = bal;
      }
      return res;
    } catch (e) {
      debugPrint('[ApiService] getWallet error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'wallet': {'avl_balance': 0.0, 'total_credit': 0.0, 'total_debit': 0.0}
      };
    }
  }

  /// Fetch wallet transactions
  Future<Map<String, dynamic>> getWalletTransactions({String? type, String? search, int page = 1}) async {
    await _ensureAuthLoaded();
    try {
      final params = <String, String>{'page': page.toString()};
      if (type != null && type.isNotEmpty && type != 'all') {
        params['type'] = type;
      }
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }
      final uri = Uri.parse('$baseUrl/wallet/transactions').replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      debugPrint('[ApiService] getWalletTransactions error: $e');
      return {'success': false, 'message': 'Connection error: $e', 'transactions': {'data': []}};
    }
  }

  /// Add Money / Direct credit recharge
  Future<Map<String, dynamic>> addMoney({
    required double amount,
    String? paymentMethod,
    String? customNote,
  }) async {
    final uri = Uri.parse('$baseUrl/wallet/add-money');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'amount': amount,
        'payment_method': paymentMethod ?? 'UPI',
        'custom_note': customNote,
      }),
    );
    return _processResponse(response);
  }

  /// Spend Money / Direct debit
  Future<Map<String, dynamic>> spendMoney({
    required double amount,
    required String purpose,
    String? referenceId,
  }) async {
    final uri = Uri.parse('$baseUrl/wallet/spend-money');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'amount': amount,
        'purpose': purpose,
        'reference_id': referenceId,
      }),
    );
    return _processResponse(response);
  }

  /// Create Razorpay Order
  Future<Map<String, dynamic>> createRazorpayOrder(double amount) async {
    final uri = Uri.parse('$baseUrl/wallet/razorpay/create-order');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'amount': amount}),
    );
    return _processResponse(response);
  }

  /// Verify Razorpay Payment Signature
  Future<Map<String, dynamic>> verifyRazorpayPayment(Map<String, dynamic> paymentData) async {
    final uri = Uri.parse('$baseUrl/wallet/razorpay/verify-payment');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(paymentData),
    );
    return _processResponse(response);
  }

  // ==========================================
  // HELP, SUPPORT & STORIES
  // ==========================================

  /// Get Help Center FAQs and contact information
  Future<Map<String, dynamic>> getHelpCenter() async {
    final uri = Uri.parse('$baseUrl/help-center');
    final response = await http.get(uri, headers: _headers);
    return _processResponse(response);
  }

  /// Submit Public Contact / Help Query
  Future<Map<String, dynamic>> submitHelpQuery(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/help-center/submit');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(data),
    );
    return _processResponse(response);
  }

  /// Get Candidate Support Tickets
  Future<Map<String, dynamic>> getSupportTickets({int page = 1}) async {
    final uri = Uri.parse('$baseUrl/support/tickets?page=$page');
    final response = await http.get(uri, headers: _headers);
    return _processResponse(response);
  }

  /// Raise a new Support Ticket
  Future<Map<String, dynamic>> createSupportTicket({
    required String priority,
    required String subject,
    required String message,
    List<File>? screenshots,
  }) async {
    final uri = Uri.parse('$baseUrl/support/tickets/create');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      if (isAuthenticated) 'Authorization': 'Bearer $_token',
    });

    request.fields['priority'] = priority;
    request.fields['subject'] = subject;
    request.fields['message'] = message;

    if (screenshots != null && screenshots.isNotEmpty) {
      for (final file in screenshots) {
        request.files.add(await http.MultipartFile.fromPath('screenshots[]', file.path));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response);
  }

  /// Get Success Stories
  Future<Map<String, dynamic>> getSuccessStories({int page = 1}) async {
    final uri = Uri.parse('$baseUrl/success-stories?page=$page');
    final response = await http.get(uri, headers: _headers);
    return _processResponse(response);
  }

  // ==========================================
  // HELPER: PROCESS HTTP RESPONSE
  // ==========================================

  Map<String, dynamic> _processResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (!decoded.containsKey('success')) {
            decoded['success'] = true;
          }
          return decoded;
        } else {
          final result = Map<String, dynamic>.from(decoded);
          result['success'] = false;
          result['status_code'] = response.statusCode;
          result['message'] = decoded['message'] ?? 'An error occurred (${response.statusCode})';
          return result;
        }
      }
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'data': decoded,
      };
    } catch (e) {
      return {
        'success': false,
        'status_code': response.statusCode,
        'message': response.statusCode == 200
            ? 'Success'
            : 'Server communication error: ${response.statusCode}',
      };
    }
  }
}
