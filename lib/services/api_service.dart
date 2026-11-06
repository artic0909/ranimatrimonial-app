import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'security_service.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  factory ApiService() => instance;

  static const String baseUrl = 'https://ranimatrimonial.com/api';

  static const String _keyToken = 'auth_token';
  static const String _keyCandidate = 'candidate_data';

  // Persistent shared HTTP client for Keep-Alive & HTTP connection pooling
  final http.Client _client = http.Client();
  DateTime? _lastPreloadTime;
  Map<String, dynamic>? _cachedSearchOptions;
  Map<String, dynamic>? _cachedRegistrationOptions;

  String? _token;
  Map<String, dynamic>? _candidate;

  final ValueNotifier<Map<String, dynamic>?> candidateNotifier = ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<double> walletBalanceNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<Set<String>> shortlistedIdsNotifier = ValueNotifier<Set<String>>({});
  final ValueNotifier<Set<String>> sentRequestIdsNotifier = ValueNotifier<Set<String>>({});
  final ValueNotifier<Set<String>> receivedRequestIdsNotifier = ValueNotifier<Set<String>>({});
  final ValueNotifier<Set<String>> acceptedRequestIdsNotifier = ValueNotifier<Set<String>>({});
  final ValueNotifier<Map<String, int>> sidebarCountsNotifier = ValueNotifier<Map<String, int>>({
    'matches': 0,
    'accepted': 0,
    'received': 0,
    'sent': 0,
    'shortlisted': 0,
  });

  /// Update dynamic sidebar badges cleanly across screens
  void updateSidebarCounts({
    int? matches,
    int? accepted,
    int? received,
    int? sent,
    int? shortlisted,
  }) {
    final map = Map<String, int>.from(sidebarCountsNotifier.value);
    if (matches != null) map['matches'] = matches;
    if (accepted != null) map['accepted'] = accepted;
    if (received != null) map['received'] = received;
    if (sent != null) map['sent'] = sent;
    if (shortlisted != null) map['shortlisted'] = shortlisted;
    sidebarCountsNotifier.value = map;
  }

  String? get token => _token;
  Map<String, dynamic>? get candidate => _candidate;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// Check if a candidate or ID is shortlisted in the global reactive registry
  bool isProfileShortlisted(dynamic candidateOrId) {
    if (candidateOrId == null) return false;
    final set = shortlistedIdsNotifier.value;
    if (candidateOrId is String) {
      return set.contains(candidateOrId);
    }
    if (candidateOrId is Map) {
      final pid = (candidateOrId['candidate_code'] ?? candidateOrId['profile_id'] ?? candidateOrId['id'])?.toString();
      final numId = candidateOrId['numeric_id']?.toString();
      if (pid != null && set.contains(pid)) return true;
      if (numId != null && set.contains(numId)) return true;
      return candidateOrId['is_shortlisted'] == true ||
          candidateOrId['is_shortlisted'] == 1 ||
          candidateOrId['is_shortlisted'] == '1';
    }
    return set.contains(candidateOrId.toString());
  }

  /// Mark or unmark a profile in the global shortlisted registry
  void markProfileShortlisted(String id, bool shortlisted, {String? secondaryId}) {
    final current = Set<String>.from(shortlistedIdsNotifier.value);
    if (shortlisted) {
      current.add(id);
      if (secondaryId != null && secondaryId.isNotEmpty) current.add(secondaryId);
    } else {
      current.remove(id);
      if (secondaryId != null && secondaryId.isNotEmpty) current.remove(secondaryId);
    }
    shortlistedIdsNotifier.value = current;
  }

  static String normalizeCandidateId(dynamic raw) {
    if (raw == null) return '';
    var str = raw.toString().trim().toUpperCase();
    while (str.startsWith('RMRM')) {
      str = str.substring(2);
    }
    return str;
  }

  /// Generate all candidate ID variations (e.g., 'RM00024', '24', 'RM24') to guarantee exact matching
  static Set<String> candidateIdVariants(dynamic candidateOrId) {
    final set = <String>{};
    if (candidateOrId == null) return set;

    void addVariants(String? s) {
      if (s == null || s.trim().isEmpty) return;
      final trimmed = s.trim();
      set.add(trimmed);
      final norm = normalizeCandidateId(trimmed);
      if (norm.isNotEmpty) set.add(norm);
      final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty) {
        final val = int.tryParse(digits);
        if (val != null) {
          set.add(val.toString());
          set.add('RM${val.toString().padLeft(5, '0')}');
          set.add('RM$val');
        }
      }
    }

    if (candidateOrId is Map) {
      final pid = (candidateOrId['candidate_code'] ??
              candidateOrId['profile_id'] ??
              candidateOrId['id'])
          ?.toString();
      final numId = (candidateOrId['numeric_id'] ?? candidateOrId['db_id'])?.toString();
      addVariants(pid);
      addVariants(numId);
    } else {
      addVariants(candidateOrId.toString());
    }

    return set;
  }

  /// Check if a candidate or ID has a sent connection request
  bool isRequestSent(dynamic candidateOrId) {
    if (candidateOrId == null) return false;
    final set = sentRequestIdsNotifier.value;
    final variants = candidateIdVariants(candidateOrId);
    for (final v in variants) {
      if (set.contains(v)) return true;
    }
    if (candidateOrId is Map) {
      return candidateOrId['request_type'] == 'sent' ||
          candidateOrId['is_interest_sent'] == true ||
          candidateOrId['is_connected'] == true;
    }
    return false;
  }

  /// Check if a candidate or ID has a received connection request
  bool isRequestReceived(dynamic candidateOrId) {
    if (candidateOrId == null) return false;
    final set = receivedRequestIdsNotifier.value;
    final variants = candidateIdVariants(candidateOrId);
    for (final v in variants) {
      if (set.contains(v)) return true;
    }
    if (candidateOrId is Map) {
      return candidateOrId['request_type'] == 'received' ||
          candidateOrId['is_interest_received'] == true;
    }
    return false;
  }

  /// Check if a candidate or ID is an accepted connection
  bool isRequestAccepted(dynamic candidateOrId) {
    if (candidateOrId == null) return false;
    final set = acceptedRequestIdsNotifier.value;
    final variants = candidateIdVariants(candidateOrId);
    for (final v in variants) {
      if (set.contains(v)) return true;
    }
    if (candidateOrId is Map) {
      return candidateOrId['request_type'] == 'accepted' ||
          candidateOrId['is_accepted'] == true;
    }
    return false;
  }

  /// Register connection status in the global reactive registry
  void registerConnectionStatus({
    required String profileId,
    String? numericId,
    required String status,
  }) {
    final sentSet = Set<String>.from(sentRequestIdsNotifier.value);
    final recvSet = Set<String>.from(receivedRequestIdsNotifier.value);
    final accSet = Set<String>.from(acceptedRequestIdsNotifier.value);

    final ids = candidateIdVariants(profileId);
    if (numericId != null && numericId.isNotEmpty) {
      ids.addAll(candidateIdVariants(numericId));
    }

    // Clear previous occurrences across sets
    sentSet.removeAll(ids);
    recvSet.removeAll(ids);
    accSet.removeAll(ids);

    final normStatus = status.toLowerCase();
    if (normStatus == 'sent') {
      sentSet.addAll(ids);
    } else if (normStatus == 'received') {
      recvSet.addAll(ids);
    } else if (normStatus == 'accepted') {
      accSet.addAll(ids);
    }

    sentRequestIdsNotifier.value = sentSet;
    receivedRequestIdsNotifier.value = recvSet;
    acceptedRequestIdsNotifier.value = accSet;
  }

  bool _isPreloadingConnections = false;

  /// Preload received, sent, and accepted connection requests across all modules (throttled to avoid redundant calls)
  Future<void> preloadAllConnections({bool force = false}) async {
    if (_isPreloadingConnections) return;
    final now = DateTime.now();
    if (!force && _lastPreloadTime != null && now.difference(_lastPreloadTime!).inSeconds < 45) {
      return;
    }
    _isPreloadingConnections = true;
    _lastPreloadTime = now;
    try {
      await Future.wait([
        getInbox(tab: 'received'),
        getInbox(tab: 'sent'),
        getInbox(tab: 'accepted'),
      ]).catchError((e) {
        debugPrint('[ApiService] preloadAllConnections inbox error: $e');
        return <Map<String, dynamic>>[];
      });

      try {
        final matchRes = await getMatches(tab: 'my_matches', page: 1);
        if (matchRes['success'] == true) {
          final rawMatches = matchRes['matches'];
          List<dynamic> list = [];
          if (rawMatches is List) {
            list = rawMatches;
          } else if (rawMatches is Map && rawMatches['data'] is List) {
            list = rawMatches['data'] as List;
          }
          for (final m in list) {
            if (m is Map) {
              final pid = (m['candidate_code'] ?? m['profile_id'] ?? m['id'])?.toString();
              final numId = m['numeric_id']?.toString() ?? m['db_id']?.toString();
              final reqType = (m['request_type'] ?? '').toString().toLowerCase();
              if (pid != null && pid.isNotEmpty && reqType.isNotEmpty && reqType != 'none') {
                registerConnectionStatus(profileId: pid, numericId: numId, status: reqType);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[ApiService] preloadAllConnections my_matches error: $e');
      }
    } finally {
      _isPreloadingConnections = false;
    }
  }

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
    if (urlStr.startsWith('data:image')) {
      return urlStr;
    }
    final serverBase = baseUrl.replaceAll('/api', '');
    final cleanPath = urlStr.replaceFirst(RegExp(r'^/+'), '');
    if (cleanPath.startsWith('img/') ||
        cleanPath.startsWith('assets/') ||
        cleanPath.startsWith('static/') ||
        cleanPath == 'logo.png') {
      return '$serverBase/$cleanPath';
    }
    if (cleanPath.startsWith('storage/')) {
      return '$serverBase/$cleanPath';
    }
    return '$serverBase/storage/$cleanPath';
  }

  /// Comprehensive profile completeness calculation matching backend
  static int calculateProfileCompleteness(Map<String, dynamic>? candidate) {
    if (candidate == null) return 30;

    bool isFilled(dynamic val, [int minLen = 1]) {
      if (val == null) return false;
      final s = val.toString().trim();
      return s.isNotEmpty && s != '-' && s != 'null' && s.length >= minLen;
    }

    int score = 0;

    // 1. Basic & Identity (25%)
    if (isFilled(candidate['first_name']) && isFilled(candidate['last_name'])) score += 6;
    if (isFilled(candidate['gender']) && isFilled(candidate['dob'])) score += 6;
    if (isFilled(candidate['marital_status'])) score += 4;
    if (isFilled(candidate['height'])) score += 4;
    final photo = candidate['profile_picture'] ?? candidate['profile_picture_url'] ?? candidate['photo'];
    if (isFilled(photo)) score += 5;

    // 2. Religious & Cultural (10%)
    if (isFilled(candidate['religion'])) score += 4;
    if (isFilled(candidate['community'])) score += 3;
    if (isFilled(candidate['mother_tongue']) || isFilled(candidate['gothra'])) score += 3;

    // 3. Location & Contact (10%)
    if (isFilled(candidate['city']) && isFilled(candidate['state'])) score += 5;
    if (isFilled(candidate['pincode']) || isFilled(candidate['full_address'])) score += 5;

    // 4. Education & Career (15%)
    if (isFilled(candidate['highest_qualification'])) score += 5;
    if (isFilled(candidate['profession']) && isFilled(candidate['annual_income'])) score += 5;
    if (isFilled(candidate['working_with']) || isFilled(candidate['company_name']) || isFilled(candidate['college_name'])) score += 5;

    // 5. Family Details (15%)
    if (isFilled(candidate['father_profession'])) score += 4;
    if (isFilled(candidate['mother_profession'])) score += 4;
    if (isFilled(candidate['family_type'])) score += 4;
    if (isFilled(candidate['family_location']) || isFilled(candidate['family_financial_status'])) score += 3;

    // 6. Astro / Horoscope (10%)
    if (isFilled(candidate['manglik'])) score += 4;
    if (isFilled(candidate['time_of_birth']) || isFilled(candidate['city_of_birth'])) score += 6;

    // 7. About & Lifestyle (15%)
    final about = candidate['about_yourself'] ?? candidate['about_me'] ?? candidate['about'];
    if (isFilled(about, 20)) score += 7;
    if (isFilled(candidate['diet'])) score += 3;
    if (isFilled(candidate['blood_group'])) score += 2;
    final hobbies = candidate['hobbies_interests'];
    if (hobbies is List ? hobbies.isNotEmpty : isFilled(hobbies)) score += 3;

    return score.clamp(20, 100);
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
    // Enable screenshot & screen capture protection upon login
    SecurityService.enableSecureScreen();
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
    // Disable screenshot protection upon logout
    SecurityService.disableSecureScreen();
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

  /// Unified safe GET request with persistent client, timeout, and robust exception handling
  Future<Map<String, dynamic>> _safeGet(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      final response = await _client.get(uri, headers: headers ?? _headers).timeout(timeout);
      return _processResponse(response);
    } on SocketException catch (_) {
      return {
        'success': false,
        'message': 'Unable to connect to server. Please check your internet connection.',
      };
    } on TimeoutException catch (_) {
      return {
        'success': false,
        'message': 'Connection timed out. Please try again.',
      };
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Unified safe POST request with persistent client, timeout, and robust exception handling
  Future<Map<String, dynamic>> _safePost(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final response = await _client.post(
        uri,
        headers: headers ?? _headers,
        body: body,
      ).timeout(timeout);
      return _processResponse(response);
    } on SocketException catch (_) {
      return {
        'success': false,
        'message': 'Unable to connect to server. Please check your internet connection.',
      };
    } on TimeoutException catch (_) {
      return {
        'success': false,
        'message': 'Connection timed out. Please try again.',
      };
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  /// Send WhatsApp OTP for Login
  Future<Map<String, dynamic>> sendOtp(String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('$baseUrl/send-otp');
    return _safePost(uri, body: jsonEncode({'mobile': cleanMobile}));
  }

  /// Verify OTP and Login
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('$baseUrl/verify-otp');
    final data = await _safePost(
      uri,
      body: jsonEncode({
        'mobile': cleanMobile,
        'otp': otp,
      }),
    );
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
        await _safePost(uri);
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

    return _safePost(uri, body: jsonEncode(body));
  }

  /// Send WhatsApp OTP for Registration
  Future<Map<String, dynamic>> sendRegistrationOtp(String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('$baseUrl/send-registration-otp');
    return _safePost(uri, body: jsonEncode({'mobile': cleanMobile}));
  }

  /// Verify Registration OTP
  Future<Map<String, dynamic>> verifyRegistrationOtp(String mobile, String otp) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('$baseUrl/verify-registration-otp');
    return _safePost(uri, body: jsonEncode({
      'mobile': cleanMobile,
      'otp': otp,
    }));
  }

  /// Send Selfie Link via WhatsApp
  Future<Map<String, dynamic>> sendSelfieLink(String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('$baseUrl/send-selfie-link');
    return _safePost(uri, body: jsonEncode({'mobile': cleanMobile}));
  }

  /// Save phone selfie to cache
  Future<Map<String, dynamic>> savePhoneSelfie(String mobile, String selfieData) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('$baseUrl/save-phone-selfie');
    return _safePost(uri, body: jsonEncode({
      'mobile': cleanMobile,
      'selfie_data': selfieData,
    }));
  }

  /// Check selfie verification polling status
  Future<Map<String, dynamic>> checkSelfieStatus(String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('$baseUrl/check-selfie-status?mobile=$cleanMobile');
    return _safeGet(uri);
  }

  /// Fetch Master Dropdown Options for Registration & Profile screens (cached in memory)
  Future<Map<String, dynamic>> getRegistrationOptions() async {
    if (_cachedRegistrationOptions != null) {
      return {'success': true, 'data': _cachedRegistrationOptions};
    }
    final uri = Uri.parse('$baseUrl/registration-options');
    final data = await _safeGet(uri);
    if (data['success'] == true && data['data'] != null && data['data'] is Map) {
      _cachedRegistrationOptions = data['data'] as Map<String, dynamic>;
    }
    return data;
  }

  /// Verify Ground Partner (GP) referral code in real-time
  Future<Map<String, dynamic>> verifyGpCode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) {
      return {
        'success': false,
        'valid': false,
        'message': 'Please enter a GP code.',
      };
    }
    final uri = Uri.parse('$baseUrl/verify-gp-code').replace(
      queryParameters: {'code': cleanCode},
    );
    return _safeGet(uri);
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
      final data = await _safeGet(uri, timeout: const Duration(seconds: 10));
      if (data['success'] == true && data['data'] != null) {
        final d = data['data'];
        if (d['candidate'] != null) {
          await updateCachedCandidate(d['candidate'] as Map<String, dynamic>);
        }
        if (d['wallet'] != null && d['wallet']['avl_balance'] != null) {
          final bal = double.tryParse(d['wallet']['avl_balance'].toString()) ?? 0.0;
          walletBalanceNotifier.value = bal;
        }
        if (d['metrics'] != null) {
          final m = d['metrics'];
          final matches = int.tryParse(m['total_matches_count']?.toString() ?? m['new_matches_count']?.toString() ?? '0') ?? 0;
          final accepted = int.tryParse(m['accepted_invitations_count']?.toString() ?? '0') ?? 0;
          final received = int.tryParse(m['pending_invitations_count']?.toString() ?? '0') ?? 0;
          final sent = int.tryParse(m['sent_invitations_count']?.toString() ?? '0') ?? 0;
          final shortlisted = int.tryParse(m['shortlisted_count']?.toString() ?? '0') ?? 0;

          sidebarCountsNotifier.value = {
            'matches': matches,
            'accepted': accepted,
            'received': received,
            'sent': sent,
            'shortlisted': shortlisted,
          };
        }
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
    final data = await _safeGet(uri);
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

    final data = await _safePost(uri, body: jsonEncode(body));
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
    final uri = Uri.parse('$baseUrl/my-photos');
    return _safeGet(uri, timeout: const Duration(seconds: 10));
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
    final uri = Uri.parse('$baseUrl/set-profile-photo');
    final res = await _safePost(uri, body: jsonEncode({'photo_id': photoId}));
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
  }

  /// Delete photo from gallery
  Future<Map<String, dynamic>> deletePhoto(dynamic photoId) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/delete-photo');
    return _safePost(uri, body: jsonEncode({'photo_id': photoId}));
  }

  /// Update Photo & Album privacy settings
  Future<Map<String, dynamic>> updatePhotoSettings({
    required String photoPrivacy,
    required String albumPrivacy,
  }) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/update-photo-settings');
    return _safePost(
      uri,
      body: jsonEncode({
        'photo_privacy': photoPrivacy,
        'album_privacy': albumPrivacy,
      }),
    );
  }

  // ==========================================
  // BLUE TICK VERIFICATION
  // ==========================================

  /// Get Blue Tick Verification details
  Future<Map<String, dynamic>> getBlueTickVerification() async {
    final uri = Uri.parse('$baseUrl/bluetick-verification');
    return _safeGet(uri);
  }

  /// Alias for getBlueTickVerification
  Future<Map<String, dynamic>> showBlueTickVerification() => getBlueTickVerification();

  /// Validate Aadhaar number
  Future<Map<String, dynamic>> validateAadhar(String aadharNumber) async {
    final uri = Uri.parse('$baseUrl/validate-aadhar');
    return _safePost(uri, body: jsonEncode({'aadhar_number': aadharNumber}));
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
    return _safePost(uri);
  }

  /// Clear all notifications
  Future<Map<String, dynamic>> clearAllNotifications() async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/notifications/clear-all');
    return _safePost(uri);
  }

  /// Register Device FCM Token with backend for background OS push notifications
  Future<Map<String, dynamic>> saveFcmToken(String fcmToken) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/save-fcm-token');
    return _safePost(uri, body: jsonEncode({'fcm_token': fcmToken}));
  }

  // ==========================================
  // MATCHES & CONNECTIONS
  // ==========================================

  /// Fetch candidate matches by tab ('all', 'new', 'shortlisted', 'connected', etc.)
  Future<Map<String, dynamic>> getMatches({String tab = 'all', int page = 1}) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/matches?tab=$tab&page=$page');
    final data = await _safeGet(uri);
    if (data['success'] == true) {
      final rawMatches = data['matches'];
      List<dynamic> list = [];
      if (rawMatches is List) {
        list = rawMatches;
      } else if (rawMatches is Map && rawMatches['data'] is List) {
        list = rawMatches['data'] as List;
      }
      final set = Set<String>.from(shortlistedIdsNotifier.value);
      for (final m in list) {
        if (m is Map) {
          final pid = (m['candidate_code'] ?? m['profile_id'] ?? m['id'])?.toString();
          final numId = m['numeric_id']?.toString();
          final isShort = tab == 'shortlisted' ||
              m['is_shortlisted'] == true ||
              m['is_shortlisted'] == 1 ||
              m['is_shortlisted'] == '1';
          if (isShort) {
            if (pid != null && pid.isNotEmpty) set.add(pid);
            if (numId != null && numId.isNotEmpty) set.add(numId);
          }
          if (pid != null && pid.isNotEmpty) {
            final reqType = (m['request_type'] ?? '').toString();
            if (reqType == 'sent' || m['is_interest_sent'] == true || tab == 'my_matches') {
              registerConnectionStatus(profileId: pid, numericId: numId, status: 'sent');
            } else if (reqType == 'received' || m['is_interest_received'] == true) {
              registerConnectionStatus(profileId: pid, numericId: numId, status: 'received');
            } else if (reqType == 'accepted' || m['is_accepted'] == true || tab == 'accepted') {
              registerConnectionStatus(profileId: pid, numericId: numId, status: 'accepted');
            }
          }
        }
      }
      shortlistedIdsNotifier.value = set;

      if (data['counts'] is Map) {
        final c = data['counts'] as Map;
        final mCount = int.tryParse(c['new']?.toString() ?? c['todays']?.toString() ?? c['my_matches']?.toString() ?? c['all']?.toString() ?? '');
        final sCount = int.tryParse(c['shortlisted']?.toString() ?? '');
        final aCount = int.tryParse(c['accepted']?.toString() ?? '');
        updateSidebarCounts(
          matches: mCount,
          shortlisted: sCount,
          accepted: aCount,
        );
      }
    }
    return data;
  }

  /// Get candidate profile details by token or ID
  Future<Map<String, dynamic>> getProfileDetails(dynamic id) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/matches/profile/$id');
    final data = await _safeGet(uri);
    if (data['success'] == true) {
      final p = data['profile'] ?? data['candidate'] ?? {};
      final pid = (p['candidate_code'] ?? p['profile_id'] ?? p['id'] ?? id)?.toString() ?? id.toString();
      final numId = p['id']?.toString() ?? (id is int || int.tryParse(id.toString()) != null ? id.toString() : null);
      final status = data['status'] ?? {};
      if (status['is_accepted'] == true) {
        registerConnectionStatus(profileId: pid, numericId: numId, status: 'accepted');
      } else if (status['is_sent_by_me'] == true) {
        registerConnectionStatus(profileId: pid, numericId: numId, status: 'sent');
      } else if (status['is_received_by_me'] == true) {
        registerConnectionStatus(profileId: pid, numericId: numId, status: 'received');
      }
    }
    return data;
  }

  /// Send Interest / Connection Request
  Future<Map<String, dynamic>> sendInterest(String profileId) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/matches/send-interest');
    final data = await _safePost(uri, body: jsonEncode({'profile_id': profileId}));
    if (data['success'] == true) {
      registerConnectionStatus(profileId: profileId, status: 'sent');
    }
    return data;
  }

  /// Respond to an Interest (accept / decline)
  Future<Map<String, dynamic>> respondInterest(String profileId, String action) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/matches/respond-interest');
    final data = await _safePost(
      uri,
      body: jsonEncode({
        'profile_id': profileId,
        'action': action,
      }),
    );
    if (data['success'] == true) {
      registerConnectionStatus(
        profileId: profileId,
        status: action == 'accept' ? 'accepted' : 'declined',
      );
    }
    return data;
  }

  /// Toggle candidate shortlist
  Future<Map<String, dynamic>> toggleShortlist(String profileId, {String? secondaryId}) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/matches/toggle-shortlist');
    final data = await _safePost(uri, body: jsonEncode({'profile_id': profileId}));
    if (data['success'] == true) {
      final isShort = data['shortlisted'] == true || data['shortlisted'] == 1;
      markProfileShortlisted(profileId, isShort, secondaryId: secondaryId);
    }
    return data;
  }

  /// Request WhatsApp Chat unlock
  Future<Map<String, dynamic>> requestWhatsAppChat(String profileId) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/matches/request-whatsapp-chat');
    return _safePost(uri, body: jsonEncode({'profile_id': profileId}));
  }

  /// Respond to WhatsApp Chat unlock request (accept / decline)
  Future<Map<String, dynamic>> respondWhatsAppChat(String profileId, String action) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/matches/respond-whatsapp-chat');
    return _safePost(
      uri,
      body: jsonEncode({
        'profile_id': profileId,
        'action': action,
      }),
    );
  }

  // ==========================================
  // INBOX
  // ==========================================

  /// Fetch Inbox connection requests ('received', 'accepted', 'declined', 'sent')
  Future<Map<String, dynamic>> getInbox({String tab = 'received'}) async {
    await _ensureAuthLoaded();
    try {
      final uri = Uri.parse('$baseUrl/inbox?tab=$tab');
      final data = await _safeGet(uri, timeout: const Duration(seconds: 10));
      if (data['success'] == true && data['counts'] is Map) {
        final c = data['counts'] as Map;
        final rec = int.tryParse(c['received']?.toString() ?? c['pending']?.toString() ?? '0') ?? 0;
        final sent = int.tryParse(c['sent']?.toString() ?? '0') ?? 0;
        final acc = int.tryParse(c['accepted']?.toString() ?? '0') ?? 0;
        updateSidebarCounts(received: rec, sent: sent, accepted: acc);
      }
      if (data['success'] == true) {
        final list = (data['requests'] ?? data['data'] ?? []) as List<dynamic>;
        for (final item in list) {
          if (item is Map) {
            final p = item['candidate'] ?? item['profile'] ?? item;
            final pid = (p['candidate_code'] ?? p['profile_id'] ?? p['id'] ?? item['id'])?.toString();
            final numId = p['numeric_id']?.toString() ?? p['db_id']?.toString() ?? item['db_id']?.toString();
            if (pid != null && pid.isNotEmpty) {
              final itemStatus = (item['status'] ?? tab).toString().toLowerCase();
              final effectiveStatus = itemStatus == 'pending' ? (tab == 'sent' ? 'sent' : 'received') : itemStatus;
              registerConnectionStatus(profileId: pid, numericId: numId, status: effectiveStatus);
            }
          }
        }
      }
      return data;
    } catch (e) {
      debugPrint('[ApiService] getInbox error: $e');
      return {'success': false, 'message': 'Connection error: $e', 'requests': [], 'counts': {}};
    }
  }

  // ==========================================
  // SEARCH & FILTERS
  // ==========================================

  /// Get search filter master options (cached in memory)
  Future<Map<String, dynamic>> getSearchOptions({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedSearchOptions != null) {
      return _cachedSearchOptions!;
    }
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/search/options');
    final res = await _safeGet(uri);
    if (res['success'] == true) {
      _cachedSearchOptions = res;
    }
    return res;
  }

  /// Search candidate profiles dynamically
  Future<Map<String, dynamic>> searchProfiles(Map<String, dynamic> filters) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/search/filter');
    return _safePost(uri, body: jsonEncode(filters));
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

  /// Download official PDF Tax Invoice for a wallet transaction
  Future<Map<String, dynamic>> downloadTransactionInvoice(dynamic transactionId, {String? invoiceNo}) async {
    await _ensureAuthLoaded();
    try {
      final uri = Uri.parse('$baseUrl/wallet/transaction/$transactionId/invoice');
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 25));

      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        final cleanNo = invoiceNo?.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '') ?? transactionId.toString();
        final fileName = 'Invoice-$cleanNo.pdf';

        File? savedFile;
        String locationDesc = 'Downloads';

        // 1. Try public Android Downloads folder (/storage/emulated/0/Download)
        if (Platform.isAndroid) {
          try {
            final publicDownloadDir = Directory('/storage/emulated/0/Download');
            if (await publicDownloadDir.exists()) {
              final pubFile = File('${publicDownloadDir.path}/$fileName');
              await pubFile.writeAsBytes(res.bodyBytes, flush: true);
              savedFile = pubFile;
              locationDesc = 'Downloads folder';
            }
          } catch (e) {
            debugPrint('[ApiService] Public Downloads folder write fallback: $e');
          }
        }

        // 2. Try getDownloadsDirectory()
        if (savedFile == null) {
          try {
            final downloadsDir = await getDownloadsDirectory();
            if (downloadsDir != null) {
              final dFile = File('${downloadsDir.path}/$fileName');
              await dFile.writeAsBytes(res.bodyBytes, flush: true);
              savedFile = dFile;
              locationDesc = 'Downloads folder';
            }
          } catch (_) {}
        }

        // 3. Fallback to getApplicationDocumentsDirectory()
        if (savedFile == null) {
          final docDir = await getApplicationDocumentsDirectory();
          final docFile = File('${docDir.path}/$fileName');
          await docFile.writeAsBytes(res.bodyBytes, flush: true);
          savedFile = docFile;
          locationDesc = 'App Documents';
        }

        return {
          'success': true,
          'file': savedFile,
          'filePath': savedFile.path,
          'fileName': fileName,
          'location': locationDesc,
          'message': 'Invoice downloaded successfully to $locationDesc',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to download invoice (Server returned ${res.statusCode}).',
        };
      }
    } catch (e) {
      debugPrint('[ApiService] downloadTransactionInvoice error: $e');
      return {
        'success': false,
        'message': 'Network error downloading invoice: $e',
      };
    }
  }

  /// Get direct web invoice download/preview URL with auth token
  String getInvoiceWebUrl(dynamic transactionId) {
    final t = _token ?? '';
    return '$baseUrl/wallet/transaction/$transactionId/download-invoice?token=$t&view=1';
  }

  /// Add Money / Direct credit recharge
  Future<Map<String, dynamic>> addMoney({
    required double amount,
    String? paymentMethod,
    String? customNote,
  }) async {
    final uri = Uri.parse('$baseUrl/wallet/add-money');
    return _safePost(
      uri,
      body: jsonEncode({
        'amount': amount,
        'payment_method': paymentMethod ?? 'UPI',
        'custom_note': customNote,
      }),
    );
  }

  /// Spend Money / Direct debit
  Future<Map<String, dynamic>> spendMoney({
    required double amount,
    required String purpose,
    String? referenceId,
  }) async {
    final uri = Uri.parse('$baseUrl/wallet/spend-money');
    return _safePost(
      uri,
      body: jsonEncode({
        'amount': amount,
        'purpose': purpose,
        'reference_id': referenceId,
      }),
    );
  }

  /// Create Razorpay Order
  Future<Map<String, dynamic>> createRazorpayOrder(double amount) async {
    final uri = Uri.parse('$baseUrl/wallet/razorpay/create-order');
    return _safePost(uri, body: jsonEncode({'amount': amount}));
  }

  /// Verify Razorpay Payment Signature
  Future<Map<String, dynamic>> verifyRazorpayPayment(Map<String, dynamic> paymentData) async {
    final uri = Uri.parse('$baseUrl/wallet/razorpay/verify-payment');
    return _safePost(uri, body: jsonEncode(paymentData));
  }

  // ==========================================
  // HELP, SUPPORT & STORIES
  // ==========================================

  /// Get Help Center FAQs and contact information
  Future<Map<String, dynamic>> getHelpCenter() async {
    final uri = Uri.parse('$baseUrl/help-center');
    return _safeGet(uri);
  }

  /// Submit Public Contact / Help Query
  Future<Map<String, dynamic>> submitHelpQuery(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/help-center/submit');
    return _safePost(uri, body: jsonEncode(data));
  }

  /// Get Candidate Support Tickets
  Future<Map<String, dynamic>> getSupportTickets({int page = 1}) async {
    final uri = Uri.parse('$baseUrl/support/tickets?page=$page');
    return _safeGet(uri);
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
    return _safeGet(uri);
  }

  /// Get candidate's account deletion request status
  Future<Map<String, dynamic>> getDeleteAccountRequest() async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/account/delete-request');
    return _safeGet(uri);
  }

  /// Submit candidate's account deletion request
  Future<Map<String, dynamic>> submitDeleteAccountRequest(String reason) async {
    await _ensureAuthLoaded();
    final uri = Uri.parse('$baseUrl/account/delete-request');
    return _safePost(
      uri,
      body: jsonEncode({'reason': reason}),
    );
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
