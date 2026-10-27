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

  String? get token => _token;
  Map<String, dynamic>? get candidate => _candidate;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// Initialize and load saved session from local SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_keyToken);
      final candidateJson = prefs.getString(_keyCandidate);
      if (candidateJson != null && candidateJson.isNotEmpty) {
        _candidate = jsonDecode(candidateJson) as Map<String, dynamic>;
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
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyCandidate);
    } catch (e) {
      debugPrint('[ApiService] Clear session error: $e');
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

  /// Fetch Master Dropdown Options for Registration & Profile screens
  Future<Map<String, dynamic>> getRegistrationOptions() async {
    final uri = Uri.parse('$baseUrl/registration-options');
    final response = await http.get(uri, headers: _headers);
    return _processResponse(response);
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
    final uri = Uri.parse('$baseUrl/dashboard');
    final response = await http.get(uri, headers: _headers);
    final data = _processResponse(response);
    if (data['success'] == true && data['data'] != null && data['data']['candidate'] != null) {
      await updateCachedCandidate(data['data']['candidate'] as Map<String, dynamic>);
    }
    return data;
  }

  /// Fetch full candidate profile
  Future<Map<String, dynamic>> getMyProfile() async {
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
    if (data['success'] == true && data['candidate'] != null) {
      await updateCachedCandidate(data['candidate'] as Map<String, dynamic>);
    }
    return data;
  }

  // ==========================================
  // GALLERY PHOTOS
  // ==========================================

  /// Get candidate photos
  Future<Map<String, dynamic>> getMyPhotos() async {
    final uri = Uri.parse('$baseUrl/my-photos');
    final response = await http.get(uri, headers: _headers);
    return _processResponse(response);
  }

  /// Upload gallery photos
  Future<Map<String, dynamic>> uploadGalleryPhotos(List<File> files) async {
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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response);
  }

  /// Set gallery photo as main profile photo
  Future<Map<String, dynamic>> setProfilePhoto(int photoId) async {
    final uri = Uri.parse('$baseUrl/set-profile-photo');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'photo_id': photoId}),
    );
    return _processResponse(response);
  }

  /// Delete photo from gallery
  Future<Map<String, dynamic>> deletePhoto(int photoId) async {
    final uri = Uri.parse('$baseUrl/delete-photo');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'photo_id': photoId}),
    );
    return _processResponse(response);
  }

  /// Update Photo & Album privacy settings
  Future<Map<String, dynamic>> updatePhotoSettings({
    required String photoPrivacy,
    required String albumPrivacy,
  }) async {
    final uri = Uri.parse('$baseUrl/update-photo-settings');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'photo_privacy': photoPrivacy,
        'album_privacy': albumPrivacy,
      }),
    );
    return _processResponse(response);
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
  Future<Map<String, dynamic>> markNotificationRead(int notificationId) async {
    final uri = Uri.parse('$baseUrl/notifications/$notificationId/read');
    final response = await http.post(uri, headers: _headers);
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
          return {
            'success': false,
            'status_code': response.statusCode,
            'message': decoded['message'] ?? 'An error occurred (${response.statusCode})',
            'errors': decoded['errors'],
          };
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
