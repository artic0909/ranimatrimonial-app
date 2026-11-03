import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_skeleton_loader.dart';
import '../../components/rani_top_bar.dart';
import '../../components/rani_sidebar_drawer.dart';
import 'details_screen.dart';

/// Screen: Candidate Search & Dynamic Filter
/// Complete 100% feature-parity with website search.blade.php
/// Features:
/// - Instant search input by Name, Profile ID, City, Profession, Education
/// - Quick filter presets: Brides, Grooms, Never Married, Vegetarian, Non-Manglik, Post Graduate, Govt/PSU
/// - Photo Only & Verified Only quick toggles
/// - Comprehensive 7-section filter bottom sheet with cascading dynamic options (Religion -> Community, Country -> State -> City)
/// - Modern 2-column grid results ("in one row two") with verified badges, shortlist heart, match score %, and theme burgundy buttons
/// - Animated Shimmer Skeleton Loader when searching
class RaniSearchScreen extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;

  const RaniSearchScreen({
    super.key,
    this.initialFilters,
  });

  @override
  State<RaniSearchScreen> createState() => _RaniSearchScreenState();
}

class _RaniSearchScreenState extends State<RaniSearchScreen> {
  bool _isLoadingOptions = true;
  bool _isSearching = false;
  Timer? _debounceTimer;

  // Search input
  final TextEditingController _keywordController = TextEditingController();

  // Filters state matching search.blade.php
  String _gender = 'all'; // 'all', 'Female', 'Male'
  RangeValues _ageRange = const RangeValues(18, 65);
  String _heightMin = 'all';
  String _heightMax = 'all';
  String _maritalStatus = 'all';
  String _profileFor = 'all';

  // Religion & Astro
  String _religion = 'all';
  String _community = 'all';
  final TextEditingController _subCommunityController = TextEditingController();
  String _motherTongue = 'all';
  String _manglik = 'all';
  final TextEditingController _gothraController = TextEditingController();

  // Location
  String _country = 'all';
  String _state = 'all';
  String _city = 'all';
  String _residencyStatus = 'all';
  final TextEditingController _grewUpInController = TextEditingController();

  // Education & Career
  String _highestQualification = 'all';
  String _workingWith = 'all';
  final TextEditingController _professionController = TextEditingController();
  String _annualIncome = 'all';

  // Lifestyle
  String _diet = 'all';
  String _bloodGroup = 'all';
  String _disability = 'all';
  String _hobbies = 'all';

  // Family
  String _familyFinancialStatus = 'all';
  final TextEditingController _fatherProfessionController = TextEditingController();
  final TextEditingController _motherProfessionController = TextEditingController();

  // Toggles & Sort
  bool _hasPhoto = false;
  bool _verifiedOnly = false;
  String _sortBy = 'newest'; // 'newest', 'match_score', 'age_asc', 'age_desc'

  // Master options data from backend
  List<dynamic> _religions = [];
  List<dynamic> _availableCommunities = [];
  List<dynamic> _countries = [];
  List<dynamic> _availableStates = [];
  List<dynamic> _availableCities = [];
  List<dynamic> _maritalStatuses = [];
  List<dynamic> _heights = [];
  List<dynamic> _diets = [];
  List<dynamic> _incomes = [];
  List<dynamic> _workingWiths = [];
  List<dynamic> _allHobbies = [];
  List<String> _motherTongues = [];
  List<String> _bloodGroups = [];
  List<String> _familyStatuses = [];
  List<String> _residencyStatuses = [];
  List<String> _profileFors = [];

  // Search results
  List<dynamic> _results = [];
  final Set<String> _shortlistedIds = {};
  int _totalCount = 0;
  String? _errorMessage;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasAutoOpenedFilter = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      _applyInitialFilters(widget.initialFilters!);
    }
    _loadSearchOptions();
    _loadShortlistedIds();
    ApiService.instance.shortlistedIdsNotifier.addListener(_onGlobalShortlistChanged);

    // Automatically open full screen filter modal on screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasAutoOpenedFilter) {
        _hasAutoOpenedFilter = true;
        _openFullScreenFilterModal();
      }
    });
  }

  void _onGlobalShortlistChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadShortlistedIds() async {
    try {
      final res = await ApiService.instance.getMatches(tab: 'shortlisted', page: 1);
      if (!mounted) return;
      if (res['success'] == true) {
        final rawMatches = res['matches'];
        List<dynamic> list = [];
        if (rawMatches is List) {
          list = rawMatches;
        } else if (rawMatches is Map && rawMatches['data'] is List) {
          list = rawMatches['data'] as List;
        }

        for (final m in list) {
          if (m is Map) {
            final id = (m['candidate_code'] ?? m['profile_id'] ?? m['id'])?.toString();
            final numId = m['numeric_id']?.toString();
            if (id != null && id.isNotEmpty) _shortlistedIds.add(id);
            if (numId != null && numId.isNotEmpty) _shortlistedIds.add(numId);
          }
        }
        if (mounted && _results.isNotEmpty) {
          setState(() {});
        }
      }
    } catch (_) {}
  }

  void _applyInitialFilters(Map<String, dynamic> f) {
    if (f['gender'] != null) _gender = f['gender'];
    if (f['religion'] != null) _religion = f['religion'];
    if (f['city'] != null) _city = f['city'];
    if (f['keyword'] != null) _keywordController.text = f['keyword'];
  }

  @override
  void dispose() {
    ApiService.instance.shortlistedIdsNotifier.removeListener(_onGlobalShortlistChanged);
    _debounceTimer?.cancel();
    _keywordController.dispose();
    _subCommunityController.dispose();
    _gothraController.dispose();
    _grewUpInController.dispose();
    _professionController.dispose();
    _fatherProfessionController.dispose();
    _motherProfessionController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchOptions() async {
    try {
      final res = await ApiService.instance.getSearchOptions();
      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          _religions = res['religions'] ?? [];
          _countries = res['countries'] ?? [];
          _maritalStatuses = res['marital_statuses'] ?? [];
          _heights = res['heights'] ?? [];
          _diets = res['diets'] ?? [];
          _incomes = res['incomes'] ?? [];
          _workingWiths = res['working_withs'] ?? [];
          _allHobbies = res['hobbies'] ?? [];
          _motherTongues = List<String>.from(res['mother_tongues'] ?? []);
          _bloodGroups = List<String>.from(res['blood_groups'] ?? []);
          _familyStatuses = List<String>.from(res['family_financial_statuses'] ?? []);
          _residencyStatuses = List<String>.from(res['residency_statuses'] ?? []);
          _profileFors = List<String>.from(res['profile_fors'] ?? []);

          if (widget.initialFilters == null && res['default_gender'] != null) {
            _gender = res['default_gender'];
          }
          _isLoadingOptions = false;
        });

        _performSearch();
      } else {
        setState(() => _isLoadingOptions = false);
        _performSearch();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOptions = false);
        _performSearch();
      }
    }
  }

  void _onKeywordChanged(String _) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    final payload = <String, dynamic>{
      'keyword': _keywordController.text.trim(),
      'gender': _gender,
      'age_min': _ageRange.start.round(),
      'age_max': _ageRange.end.round(),
      'height_min': _heightMin,
      'height_max': _heightMax,
      'marital_status': _maritalStatus,
      'profile_for': _profileFor,
      'religion': _religion,
      'community': _community,
      'sub_community': _subCommunityController.text.trim(),
      'mother_tongue': _motherTongue,
      'manglik': _manglik,
      'gothra': _gothraController.text.trim(),
      'country': _country,
      'state': _state,
      'city': _city,
      'residency_status': _residencyStatus,
      'grew_up_in': _grewUpInController.text.trim(),
      'highest_qualification': _highestQualification,
      'working_with': _workingWith,
      'profession': _professionController.text.trim(),
      'annual_income': _annualIncome,
      'diet': _diet,
      'blood_group': _bloodGroup,
      'disability': _disability,
      'hobbies_interests': _hobbies,
      'family_financial_status': _familyFinancialStatus,
      'father_profession': _fatherProfessionController.text.trim(),
      'mother_profession': _motherProfessionController.text.trim(),
      'has_photo': _hasPhoto ? 1 : 0,
      'verified_only': _verifiedOnly ? 1 : 0,
      'sort_by': _sortBy,
    };

    try {
      final res = await ApiService.instance.searchProfiles(payload);
      if (!mounted) return;

      if (res['success'] == true) {
        final rawList = (res['profiles'] ?? res['candidates'] ?? []) as List<dynamic>;
        final processed = <Map<String, dynamic>>[];
        for (final item in rawList) {
          final map = Map<String, dynamic>.from(item as Map);
          final pid = (map['candidate_code'] ?? map['profile_id'] ?? map['id'])?.toString() ?? '';
          final numId = map['numeric_id']?.toString() ?? '';
          final isServerShort = map['is_shortlisted'] == true ||
              map['is_shortlisted'] == 1 ||
              map['is_shortlisted'] == '1' ||
              map['is_shortlisted'] == 'true';
          if (isServerShort) {
            if (pid.isNotEmpty) _shortlistedIds.add(pid);
            if (numId.isNotEmpty) _shortlistedIds.add(numId);
          }
          if (_shortlistedIds.contains(pid) || (numId.isNotEmpty && _shortlistedIds.contains(numId))) {
            map['is_shortlisted'] = true;
          }
          processed.add(map);
        }
        setState(() {
          _results = processed;
          _totalCount = res['total_count'] ?? processed.length;
          _isSearching = false;
        });
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'No profiles match your criteria.';
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to connect to search service: $e';
          _isSearching = false;
        });
      }
    }
  }

  void _resetAllFilters() {
    setState(() {
      _keywordController.clear();
      _gender = 'all';
      _ageRange = const RangeValues(18, 65);
      _heightMin = 'all';
      _heightMax = 'all';
      _maritalStatus = 'all';
      _profileFor = 'all';
      _religion = 'all';
      _community = 'all';
      _subCommunityController.clear();
      _motherTongue = 'all';
      _manglik = 'all';
      _gothraController.clear();
      _country = 'all';
      _state = 'all';
      _city = 'all';
      _residencyStatus = 'all';
      _grewUpInController.clear();
      _highestQualification = 'all';
      _workingWith = 'all';
      _professionController.clear();
      _annualIncome = 'all';
      _diet = 'all';
      _bloodGroup = 'all';
      _disability = 'all';
      _hobbies = 'all';
      _familyFinancialStatus = 'all';
      _fatherProfessionController.clear();
      _motherProfessionController.clear();
      _hasPhoto = false;
      _verifiedOnly = false;
      _sortBy = 'newest';
      _availableCommunities = [];
      _availableStates = [];
      _availableCities = [];
    });
    _performSearch();
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_keywordController.text.trim().isNotEmpty) count++;
    if (_gender != 'all') count++;
    if (_ageRange.start.round() > 18 || _ageRange.end.round() < 65) count++;
    if (_maritalStatus != 'all') count++;
    if (_religion != 'all') count++;
    if (_community != 'all') count++;
    if (_motherTongue != 'all') count++;
    if (_manglik != 'all') count++;
    if (_country != 'all') count++;
    if (_state != 'all') count++;
    if (_city != 'all') count++;
    if (_highestQualification != 'all') count++;
    if (_workingWith != 'all') count++;
    if (_annualIncome != 'all') count++;
    if (_diet != 'all') count++;
    if (_bloodGroup != 'all') count++;
    if (_hasPhoto) count++;
    if (_verifiedOnly) count++;
    return count;
  }

  void _applyReligionSelection(String rel) {
    _religion = rel;
    _community = 'all';
    _availableCommunities = [];
    if (rel != 'all') {
      final found = _religions.firstWhere(
        (r) => r is Map && (r['name']?.toString() == rel || r['title']?.toString() == rel),
        orElse: () => null,
      );
      if (found != null && found['communities'] is List) {
        _availableCommunities = found['communities'];
      }
    }
  }

  void _applyCountrySelection(String countryName) {
    _country = countryName;
    _state = 'all';
    _city = 'all';
    _availableStates = [];
    _availableCities = [];
    if (countryName != 'all') {
      final found = _countries.firstWhere(
        (c) => c is Map && (c['name']?.toString() == countryName || c['title']?.toString() == countryName),
        orElse: () => null,
      );
      if (found != null && found['states'] is List) {
        _availableStates = found['states'];
      }
    }
  }

  void _applyStateSelection(String stateName) {
    _state = stateName;
    _city = 'all';
    _availableCities = [];
    if (stateName != 'all') {
      final found = _availableStates.firstWhere(
        (s) => s is Map && (s['name']?.toString() == stateName || s['title']?.toString() == stateName),
        orElse: () => null,
      );
      if (found != null && found['cities'] is List) {
        _availableCities = found['cities'];
      }
    }
  }

  void _syncDetailsShortlistResult(dynamic result) {
    if (result is Map && result['profile_id'] != null && result['is_shortlisted'] != null) {
      final pid = result['profile_id'].toString();
      final isShort = result['is_shortlisted'] == true;
      setState(() {
        if (isShort) {
          _shortlistedIds.add(pid);
        } else {
          _shortlistedIds.remove(pid);
        }
        for (int i = 0; i < _results.length; i++) {
          final item = _results[i];
          final itemId = (item['candidate_code'] ?? item['profile_id'] ?? item['id'])?.toString();
          final numId = item['numeric_id']?.toString();
          if (itemId == pid || numId == pid) {
            final m = Map<String, dynamic>.from(item as Map);
            m['is_shortlisted'] = isShort;
            _results[i] = m;
          }
        }
      });
    }
  }

  Future<void> _toggleShortlist(String profileId, String name, int index, {String? numericId}) async {
    if (index < 0 || index >= _results.length) return;

    final currentItem = _results[index];
    final bool currentStatus = _shortlistedIds.contains(profileId) ||
        (numericId != null && numericId.isNotEmpty && _shortlistedIds.contains(numericId)) ||
        currentItem['is_shortlisted'] == true ||
        currentItem['is_shortlisted'] == 1 ||
        currentItem['is_shortlisted'] == '1';
    final bool nextStatus = !currentStatus;

    // 1. Instant Optimistic UI Update: icon turns active immediately without waiting
    setState(() {
      if (nextStatus) {
        _shortlistedIds.add(profileId);
        if (numericId != null && numericId.isNotEmpty) _shortlistedIds.add(numericId);
      } else {
        _shortlistedIds.remove(profileId);
        if (numericId != null && numericId.isNotEmpty) _shortlistedIds.remove(numericId);
      }
      final updated = Map<String, dynamic>.from(currentItem as Map);
      updated['is_shortlisted'] = nextStatus;
      _results[index] = updated;
    });

    try {
      final res = await ApiService.instance.toggleShortlist(profileId);
      if (!mounted) return;

      if (res['success'] == true) {
        final serverShortlisted = res['shortlisted'] == true || res['shortlisted'] == 1;
        setState(() {
          if (serverShortlisted) {
            _shortlistedIds.add(profileId);
            if (numericId != null && numericId.isNotEmpty) _shortlistedIds.add(numericId);
          } else {
            _shortlistedIds.remove(profileId);
            if (numericId != null && numericId.isNotEmpty) _shortlistedIds.remove(numericId);
          }
          final updated = Map<String, dynamic>.from(_results[index] as Map);
          updated['is_shortlisted'] = serverShortlisted;
          _results[index] = updated;
        });
        RaniAlert.success(
          context,
          serverShortlisted ? '$name added to Shortlist!' : '$name removed from Shortlist.',
          title: serverShortlisted ? 'Shortlisted' : 'Removed',
        );
      } else {
        // Rollback on failure
        setState(() {
          if (currentStatus) {
            _shortlistedIds.add(profileId);
            if (numericId != null && numericId.isNotEmpty) _shortlistedIds.add(numericId);
          } else {
            _shortlistedIds.remove(profileId);
            if (numericId != null && numericId.isNotEmpty) _shortlistedIds.remove(numericId);
          }
          final updated = Map<String, dynamic>.from(_results[index] as Map);
          updated['is_shortlisted'] = currentStatus;
          _results[index] = updated;
        });
        RaniAlert.error(context, res['message'] ?? 'Action failed.');
      }
    } catch (e) {
      if (mounted) {
        // Rollback on network error
        setState(() {
          if (currentStatus) {
            _shortlistedIds.add(profileId);
            if (numericId != null && numericId.isNotEmpty) _shortlistedIds.add(numericId);
          } else {
            _shortlistedIds.remove(profileId);
            if (numericId != null && numericId.isNotEmpty) _shortlistedIds.remove(numericId);
          }
          final updated = Map<String, dynamic>.from(_results[index] as Map);
          updated['is_shortlisted'] = currentStatus;
          _results[index] = updated;
        });
        RaniAlert.error(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const RaniSidebarDrawer(),
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: RaniTopBar(
        title: 'Search Profiles',
        leading: IconButton(
          icon: const Icon(CupertinoIcons.line_horizontal_3, size: 23, color: Color(0xFF1E1E1E)),
          tooltip: 'Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onNotificationPressed: () => RaniTopBar.showNotificationsSheet(context, 3),
        actions: [
          // Filter Button with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.slider_horizontal_3, color: Color(0xFF750000), size: 22),
                tooltip: 'Open Advanced Filters',
                onPressed: _openFullScreenFilterModal,
              ),
              if (_activeFiltersCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5B842),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_activeFiltersCount',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF750000),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF750000),
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: _openFullScreenFilterModal,
        icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 18, color: Color(0xFFE5B842)),
        label: Text(
          _activeFiltersCount > 0 ? 'Filters ($_activeFiltersCount)' : 'Filters',
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8DFD5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.025),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _keywordController,
                  onChanged: _onKeywordChanged,
                  style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF1E1E1E)),
                  decoration: InputDecoration(
                    hintText: 'Search Profile ID, Name, City, Profession...',
                    hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF8E8E8E)),
                    prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF757575), size: 19),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: _keywordController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18, color: Colors.grey),
                            onPressed: () {
                              _keywordController.clear();
                              _performSearch();
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // 2. Active Count, Sort & Clear Toolbar (Directly under search bar)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isSearching
                          ? 'Searching candidate profiles...'
                          : '$_totalCount Profiles Found',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                  ),

                  // Sort Dropdown
                  PopupMenuButton<String>(
                    initialValue: _sortBy,
                    onSelected: (val) {
                      setState(() => _sortBy = val);
                      _performSearch();
                    },
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8DFD5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.arrow_up_arrow_down, size: 12, color: Color(0xFF750000)),
                          const SizedBox(width: 4),
                          Text(
                            _sortLabel(_sortBy),
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'newest', child: Text('Newest First')),
                      PopupMenuItem(value: 'match_score', child: Text('Best Match Score')),
                      PopupMenuItem(value: 'age_asc', child: Text('Age: Young to Old')),
                      PopupMenuItem(value: 'age_desc', child: Text('Age: Old to Young')),
                    ],
                  ),

                  if (_activeFiltersCount > 0) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _resetAllFilters,
                      child: Text(
                        'Clear Filters',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF750000),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 4. Results Grid or Skeleton Loader
            Expanded(
              child: _buildResultsSection(),
            ),
          ],
        ),
      ),
    );
  }

  String _sortLabel(String sort) {
    switch (sort) {
      case 'match_score':
        return 'Best Match';
      case 'age_asc':
        return 'Age: Low-High';
      case 'age_desc':
        return 'Age: High-Low';
      default:
        return 'Newest';
    }
  }

  Widget _buildResultsSection() {
    // Post-Login Skeleton Screen Loader matching List View design
    if (_isSearching || _isLoadingOptions) {
      return const SingleChildScrollView(
        child: RaniSkeletonSearchList(itemCount: 4),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.search, size: 54, color: Color(0xFFBCAAA4)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF4A1010)),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF750000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _resetAllFilters,
                child: const Text('Reset All Filters'),
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.person_crop_circle_badge_exclam, size: 54, color: Color(0xFFBCAAA4)),
              const SizedBox(height: 12),
              Text(
                'No profiles found matching your search filters.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF4A1010)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF750000)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _resetAllFilters,
                child: Text('Clear Filters', style: GoogleFonts.outfit(color: const Color(0xFF750000))),
              ),
            ],
          ),
        ),
      );
    }

    // Full-Width List View per User Request ("need list view")
    return RefreshIndicator(
      color: const Color(0xFF750000),
      onRefresh: _performSearch,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _results.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final c = _results[index];
          return _buildCandidateListCard(c, index);
        },
      ),
    );
  }

  Widget _buildCandidateListCard(dynamic c, int index) {
    final profileId = (c['candidate_code'] ?? c['profile_id'] ?? c['id'])?.toString() ?? 'RM-PROFILE';
    final firstName = c['first_name'] ?? 'Candidate';
    final lastName = c['last_name'] ?? '';
    final displayName = lastName.isNotEmpty ? '$firstName ${lastName[0]}.' : firstName;
    final age = c['age']?.toString() ?? '26';
    final height = c['height']?.toString() ?? "5' 5\"";
    final maritalStatus = c['marital_status']?.toString() ?? 'Never Married';
    final religion = c['religion']?.toString() ?? '';
    final community = c['community']?.toString() ?? '';
    final profession = c['profession'] ?? c['designation'] ?? 'Professional';
    final qualification = c['highest_qualification']?.toString() ?? '';
    final city = c['city'] ?? '';
    final state = c['state'] ?? '';
    final locationText = (city.isNotEmpty && state.isNotEmpty)
        ? '$city, $state'
        : (city.isNotEmpty ? city : state);

    final photo = ApiService.formatImageUrl(c['photo'] ?? c['profile_picture'] ?? '');
    final isVerified = c['verified'] == true || c['is_verified'] == 1 || (c['bluetick'] != null && c['bluetick']['is_accept'] == 1);
    final numericId = c['numeric_id']?.toString() ?? '';
    final isShortlisted = ApiService.instance.isProfileShortlisted(c) ||
        ApiService.instance.isProfileShortlisted(profileId) ||
        _shortlistedIds.contains(profileId) ||
        (numericId.isNotEmpty && _shortlistedIds.contains(numericId)) ||
        c['is_shortlisted'] == true ||
        c['is_shortlisted'] == 1 ||
        c['is_shortlisted'] == '1' ||
        c['is_shortlisted'] == 'true';
    final matchScore = c['match_score'] ?? 85;

    // Religion & Community string
    final relComText = (religion.isNotEmpty && community.isNotEmpty && community != 'all' && community != 'All Communities')
        ? '$religion • $community'
        : (religion.isNotEmpty ? religion : (community.isNotEmpty ? community : ''));

    // Profession & Qualification string
    final careerText = qualification.isNotEmpty
        ? (profession.isNotEmpty ? '$qualification, $profession' : qualification)
        : profession;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE8DE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RaniMatchDetailsScreen(
                  profileId: profileId,
                  initialProfileData: c,
                ),
              ),
            );
            _syncDetailsShortlistResult(result);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Photo (100w x 120h) + Match Score Pill + Verified Seal
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 100,
                            height: 120,
                            color: const Color(0xFFF7F3EC),
                            child: photo.isNotEmpty
                                ? Image.network(
                                    photo,
                                    width: 100,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFFF3ECE4),
                                      child: const Icon(CupertinoIcons.person_fill, size: 40, color: Color(0xFFBCAAA4)),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFFF3ECE4),
                                    child: const Icon(CupertinoIcons.person_fill, size: 40, color: Color(0xFFBCAAA4)),
                                  ),
                          ),
                        ),

                        // Match Score Badge (Top-Left)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF750000), Color(0xFF500000)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.sparkles, size: 9, color: Color(0xFFE5B842)),
                                const SizedBox(width: 3),
                                Text(
                                  '$matchScore%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Verified Badge (Bottom-Right)
                        if (isVerified)
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified,
                                size: 15,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Right: Info Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name, Age & Heart Shortlist
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1E1E1E),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$age yrs',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF757575),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Shortlist Heart Button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _toggleShortlist(profileId, displayName, index, numericId: numericId),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isShortlisted ? const Color(0xFFFFEBEE) : const Color(0xFFFAF7F2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isShortlisted ? const Color(0xFFEF5350) : const Color(0xFFEFE8DE),
                                      ),
                                    ),
                                    child: Icon(
                                      isShortlisted ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                      size: 16,
                                      color: isShortlisted ? const Color(0xFFC62828) : const Color(0xFF757575),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 2),

                          // Profile ID Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF7F2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFEFE8DE)),
                            ),
                            child: Text(
                              profileId,
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF750000),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),

                          const SizedBox(height: 5),

                          // Height • Marital Status
                          Text(
                            '$height • $maritalStatus',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              color: const Color(0xFF555555),
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          // Religion • Community
                          if (relComText.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              relComText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                color: const Color(0xFF555555),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],

                          // Career
                          if (careerText.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              careerText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                color: const Color(0xFF333333),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],

                          // Location
                          if (locationText.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(CupertinoIcons.location, size: 11, color: Color(0xFF750000)),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    locationText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      color: const Color(0xFF666666),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Full-Width "View Profile" CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF750000),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RaniMatchDetailsScreen(
                            profileId: profileId,
                            initialProfileData: c,
                          ),
                        ),
                      );
                      _syncDetailsShortlistResult(result);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Profile',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(CupertinoIcons.chevron_right, size: 13, color: Colors.white),
                      ],
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

  // ================= 7-SECTION FULL SCREEN FILTER MODAL =================
  void _openFullScreenFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final bottomInset = MediaQuery.of(modalCtx).padding.bottom;
            final topPadding = MediaQuery.of(modalCtx).padding.top;
            return Container(
              height: MediaQuery.of(modalCtx).size.height,
              width: double.infinity,
              color: const Color(0xFFFAF7F2),
              child: SafeArea(
                top: true,
                bottom: false,
                child: Column(
                  children: [
                    // Top Full-Screen Modal Header (properly padded below notch / camera / status bar)
                    Container(
                      padding: EdgeInsets.fromLTRB(16, topPadding > 0 ? 8 : 14, 16, 14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFEFE8DE), width: 1.0),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Close (X) circle button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F3EC),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE8DFD5)),
                              ),
                              child: const Icon(CupertinoIcons.xmark, size: 18, color: Color(0xFF1E1E1E)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title and Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(CupertinoIcons.slider_horizontal_3, size: 18, color: Color(0xFF750000)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Search Filters',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E1E1E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Find matching profiles from all database fields',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: const Color(0xFF757575),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Reset All button
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _resetAllFilters();
                            });
                          },
                          child: Text(
                            'Reset All',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF750000),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Sections matching DB Structure
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      children: [
                          // SECTION 1: Looking For & Basics
                          _buildSectionTitle('01', 'Looking For & Basics'),
                          const SizedBox(height: 10),

                          // Looking For (Gender Segmented Control)
                          Text('Looking For', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF444444))),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildSegmentedTab('All', _gender == 'all', () => setModalState(() => _gender = 'all')),
                              const SizedBox(width: 8),
                              _buildSegmentedTab('Brides (Female)', _gender == 'Female', () => setModalState(() => _gender = 'Female')),
                              const SizedBox(width: 8),
                              _buildSegmentedTab('Grooms (Male)', _gender == 'Male', () => setModalState(() => _gender = 'Male')),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Profile Created For Dropdown
                          _buildDropdownField(
                            label: 'Profile Created For',
                            value: _profileFor,
                            items: [
                              {'value': 'all', 'label': 'All Relations'},
                              ..._profileFors.map((p) => {'value': p, 'label': p}),
                            ],
                            onChanged: (v) => setModalState(() => _profileFor = v ?? 'all'),
                          ),
                          const SizedBox(height: 14),

                          // Age Range Slider
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Age Range', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF444444))),
                              Text(
                                '${_ageRange.start.round()} - ${_ageRange.end.round()} Years',
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF750000)),
                              ),
                            ],
                          ),
                          RangeSlider(
                            values: _ageRange,
                            min: 18,
                            max: 65,
                            divisions: 47,
                            activeColor: const Color(0xFF750000),
                            inactiveColor: const Color(0xFFE8DFD5),
                            labels: RangeLabels('${_ageRange.start.round()}', '${_ageRange.end.round()}'),
                            onChanged: (val) => setModalState(() => _ageRange = val),
                          ),
                          const SizedBox(height: 12),

                          // Height Range (Min - Max)
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Min Height',
                                  value: _heightMin,
                                  items: [
                                    {'value': 'all', 'label': "Doesn't Matter"},
                                    ..._heights.map((h) => {
                                      'value': (h is Map ? (h['name'] ?? h['title']) : h).toString(),
                                      'label': (h is Map ? (h['name'] ?? h['title']) : h).toString(),
                                    }),
                                  ],
                                  onChanged: (v) => setModalState(() => _heightMin = v ?? 'all'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Max Height',
                                  value: _heightMax,
                                  items: [
                                    {'value': 'all', 'label': "Doesn't Matter"},
                                    ..._heights.map((h) => {
                                      'value': (h is Map ? (h['name'] ?? h['title']) : h).toString(),
                                      'label': (h is Map ? (h['name'] ?? h['title']) : h).toString(),
                                    }),
                                  ],
                                  onChanged: (v) => setModalState(() => _heightMax = v ?? 'all'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Marital Status Dropdown
                          _buildDropdownField(
                            label: 'Marital Status',
                            value: _maritalStatus,
                            items: [
                              {'value': 'all', 'label': 'All Marital Statuses'},
                              ..._maritalStatuses.map((m) => {
                                'value': (m is Map ? (m['name'] ?? m['title']) : m).toString(),
                                'label': (m is Map ? (m['name'] ?? m['title']) : m).toString(),
                              }),
                              if (_maritalStatuses.isEmpty) ...const [
                                {'value': 'Never Married', 'label': 'Never Married'},
                                {'value': 'Divorced', 'label': 'Divorced'},
                                {'value': 'Widowed', 'label': 'Widowed'},
                                {'value': 'Awaiting Divorce', 'label': 'Awaiting Divorce'},
                                {'value': 'Annulled', 'label': 'Annulled'},
                              ],
                            ],
                            onChanged: (v) => setModalState(() => _maritalStatus = v ?? 'all'),
                          ),

                          const SizedBox(height: 20),

                          // SECTION 2: Religion, Caste & Astro
                          _buildSectionTitle('02', 'Religion, Community & Astro'),
                          const SizedBox(height: 10),

                          // Religion Dropdown
                          _buildDropdownField(
                            label: 'Religion',
                            value: _religion,
                            items: [
                              {'value': 'all', 'label': 'All Religions'},
                              ..._religions.map((r) => {'value': r['name'].toString(), 'label': r['name'].toString()}),
                            ],
                            onChanged: (v) {
                              setModalState(() {
                                _applyReligionSelection(v ?? 'all');
                              });
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 12),

                          // Community / Caste Dropdown (Cascading!)
                          _buildDropdownField(
                            label: 'Community / Caste',
                            value: _community,
                            items: [
                              {'value': 'all', 'label': 'All Communities'},
                              ..._availableCommunities.map((c) => {
                                'value': (c is Map ? (c['name'] ?? c['title']) : c).toString(),
                                'label': (c is Map ? (c['name'] ?? c['title']) : c).toString(),
                              }),
                            ],
                            onChanged: (v) {
                              setModalState(() => _community = v ?? 'all');
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 12),

                          // Sub-Community text field
                          _buildTextInputField(
                            label: 'Sub-Community / Clan',
                            controller: _subCommunityController,
                            hint: 'e.g. Kulin, Saryupariya, Deshastha...',
                          ),
                          const SizedBox(height: 12),

                          // Mother Tongue Dropdown
                          _buildDropdownField(
                            label: 'Mother Tongue',
                            value: _motherTongue,
                            items: [
                              {'value': 'all', 'label': 'All Mother Tongues'},
                              ..._motherTongues.map((m) => {'value': m, 'label': m}),
                            ],
                            onChanged: (v) => setModalState(() => _motherTongue = v ?? 'all'),
                          ),
                          const SizedBox(height: 12),

                          // Manglik Status Dropdown
                          _buildDropdownField(
                            label: 'Manglik Status',
                            value: _manglik,
                            items: const [
                              {'value': 'all', 'label': 'All Manglik Statuses'},
                              {'value': 'Non-Manglik', 'label': 'Non-Manglik'},
                              {'value': 'Manglik', 'label': 'Manglik'},
                              {'value': 'Anshik Manglik', 'label': 'Anshik Manglik'},
                              {'value': "Don't Know", 'label': "Don't Know"},
                            ],
                            onChanged: (v) => setModalState(() => _manglik = v ?? 'all'),
                          ),
                          const SizedBox(height: 12),

                          // Gothra text field
                          _buildTextInputField(
                            label: 'Gothra',
                            controller: _gothraController,
                            hint: 'e.g. Kashyap, Bharadwaj, Sandilya...',
                          ),

                          const SizedBox(height: 20),

                          // SECTION 3: Location & Living
                          _buildSectionTitle('03', 'Location & Living'),
                          const SizedBox(height: 10),

                          // Country Dropdown
                          _buildDropdownField(
                            label: 'Country',
                            value: _country,
                            items: [
                              {'value': 'all', 'label': 'All Countries'},
                              ..._countries.map((c) => {'value': c['name'].toString(), 'label': c['name'].toString()}),
                            ],
                            onChanged: (v) {
                              setModalState(() {
                                _applyCountrySelection(v ?? 'all');
                              });
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 12),

                          // State Dropdown
                          _buildDropdownField(
                            label: 'State',
                            value: _state,
                            items: [
                              {'value': 'all', 'label': 'All States'},
                              ..._availableStates.map((s) => {
                                'value': (s is Map ? (s['name'] ?? s['title']) : s).toString(),
                                'label': (s is Map ? (s['name'] ?? s['title']) : s).toString(),
                              }),
                            ],
                            onChanged: (v) {
                              setModalState(() {
                                _applyStateSelection(v ?? 'all');
                              });
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 12),

                          // City Dropdown
                          _buildDropdownField(
                            label: 'City',
                            value: _city,
                            items: [
                              {'value': 'all', 'label': 'All Cities'},
                              ..._availableCities.map((ct) => {
                                'value': (ct is Map ? (ct['name'] ?? ct['title']) : ct).toString(),
                                'label': (ct is Map ? (ct['name'] ?? ct['title']) : ct).toString(),
                              }),
                            ],
                            onChanged: (v) {
                              setModalState(() => _city = v ?? 'all');
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 12),

                          // Residency Status
                          _buildDropdownField(
                            label: 'Residency Status',
                            value: _residencyStatus,
                            items: [
                              {'value': 'all', 'label': 'All Residency Types'},
                              ..._residencyStatuses.map((r) => {'value': r, 'label': r}),
                            ],
                            onChanged: (v) => setModalState(() => _residencyStatus = v ?? 'all'),
                          ),
                          const SizedBox(height: 12),

                          // Grew Up In text field
                          _buildTextInputField(
                            label: 'Grew Up In (City / Region)',
                            controller: _grewUpInController,
                            hint: 'e.g. Kolkata, Mumbai, Delhi...',
                          ),

                          const SizedBox(height: 20),

                          // SECTION 4: Education & Career
                          _buildSectionTitle('04', 'Education & Career'),
                          const SizedBox(height: 10),

                          // Highest Qualification
                          _buildDropdownField(
                            label: 'Highest Qualification',
                            value: _highestQualification,
                            items: const [
                              {'value': 'all', 'label': 'All Qualifications'},
                              {'value': 'Doctorate', 'label': 'Doctorate / PhD'},
                              {'value': 'Masters', 'label': 'Masters / Post Graduate'},
                              {'value': 'Bachelors', 'label': 'Bachelors / Graduate'},
                              {'value': 'Diploma', 'label': 'Diploma / Vocational'},
                              {'value': 'High School', 'label': 'High School'},
                              {'value': 'MBBS', 'label': 'MBBS / Medical'},
                              {'value': 'B.Tech', 'label': 'B.Tech / Engineering'},
                              {'value': 'MBA', 'label': 'MBA / Management'},
                              {'value': 'CA', 'label': 'CA / CS / Finance'},
                            ],
                            onChanged: (v) => setModalState(() => _highestQualification = v ?? 'all'),
                          ),
                          const SizedBox(height: 12),

                          // Working Sector
                          _buildDropdownField(
                            label: 'Working Sector',
                            value: _workingWith,
                            items: [
                              {'value': 'all', 'label': 'All Sectors'},
                              ..._workingWiths.map((w) => {'value': w['name'].toString(), 'label': w['name'].toString()}),
                            ],
                            onChanged: (v) => setModalState(() => _workingWith = v ?? 'all'),
                          ),
                          const SizedBox(height: 12),

                          // Profession / Role
                          _buildTextInputField(
                            label: 'Profession / Designation',
                            controller: _professionController,
                            hint: 'e.g. Software Engineer, Doctor, CA...',
                          ),
                          const SizedBox(height: 12),

                          // Annual Income
                          _buildDropdownField(
                            label: 'Annual Income',
                            value: _annualIncome,
                            items: [
                              {'value': 'all', 'label': 'All Income Levels'},
                              ..._incomes.map((inc) => {
                                'value': (inc is Map ? (inc['name'] ?? inc['title']) : inc).toString(),
                                'label': (inc is Map ? (inc['name'] ?? inc['title']) : inc).toString(),
                              }),
                              if (_incomes.isEmpty) ...const [
                                {'value': '0-3', 'label': '₹0 - 3 Lakh'},
                                {'value': '3-6', 'label': '₹3 - 6 Lakh'},
                                {'value': '6-10', 'label': '₹6 - 10 Lakh'},
                                {'value': '10-15', 'label': '₹10 - 15 Lakh'},
                                {'value': '15-25', 'label': '₹15 - 25 Lakh'},
                                {'value': '25-50', 'label': '₹25 - 50 Lakh'},
                                {'value': '50', 'label': '₹50 Lakh - 1 Crore'},
                                {'value': '100', 'label': '₹1 Crore & above'},
                              ],
                            ],
                            onChanged: (v) => setModalState(() => _annualIncome = v ?? 'all'),
                          ),

                          const SizedBox(height: 20),

                          // SECTION 5: Lifestyle & Health
                          _buildSectionTitle('05', 'Lifestyle & Health'),
                          const SizedBox(height: 10),

                          // Diet
                          _buildDropdownField(
                            label: 'Diet Preference',
                            value: _diet,
                            items: [
                              {'value': 'all', 'label': 'All Diets'},
                              ..._diets.map((d) => {'value': d['name'].toString(), 'label': d['name'].toString()}),
                            ],
                            onChanged: (v) => setModalState(() => _diet = v ?? 'all'),
                          ),
                          const SizedBox(height: 12),

                          // Blood Group
                          _buildDropdownField(
                            label: 'Blood Group',
                            value: _bloodGroup,
                            items: [
                              {'value': 'all', 'label': 'All Blood Groups'},
                              ..._bloodGroups.map((bg) => {'value': bg, 'label': bg}),
                            ],
                            onChanged: (v) => setModalState(() => _bloodGroup = v ?? 'all'),
                          ),
                          const SizedBox(height: 12),

                          // Disability
                          _buildDropdownField(
                            label: 'Disability / Special Needs',
                            value: _disability,
                            items: const [
                              {'value': 'all', 'label': "Doesn't Matter"},
                              {'value': 'None', 'label': 'None'},
                              {'value': 'Physical Disability', 'label': 'Physical Disability'},
                            ],
                            onChanged: (v) => setModalState(() => _disability = v ?? 'all'),
                          ),
                          const SizedBox(height: 12),

                          // Hobbies & Interests
                          _buildDropdownField(
                            label: 'Hobbies & Interests',
                            value: _hobbies,
                            items: [
                              {'value': 'all', 'label': 'All Hobbies'},
                              ..._allHobbies.map((hb) => {
                                'value': (hb is Map ? (hb['name'] ?? hb['title']) : hb).toString(),
                                'label': (hb is Map ? (hb['name'] ?? hb['title']) : hb).toString(),
                              }),
                            ],
                            onChanged: (v) => setModalState(() => _hobbies = v ?? 'all'),
                          ),

                          const SizedBox(height: 20),

                          // SECTION 6: Family Background
                          _buildSectionTitle('06', 'Family Background'),
                          const SizedBox(height: 10),

                          _buildDropdownField(
                            label: 'Family Financial Status',
                            value: _familyFinancialStatus,
                            items: [
                              {'value': 'all', 'label': 'All Financial Statuses'},
                              ..._familyStatuses.map((fs) => {'value': fs, 'label': fs}),
                            ],
                            onChanged: (v) => setModalState(() => _familyFinancialStatus = v ?? 'all'),
                          ),
                          const SizedBox(height: 12),

                          _buildTextInputField(
                            label: "Father's Profession",
                            controller: _fatherProfessionController,
                            hint: 'e.g. Business, Retired, Govt Service...',
                          ),
                          const SizedBox(height: 12),

                          _buildTextInputField(
                            label: "Mother's Profession",
                            controller: _motherProfessionController,
                            hint: 'e.g. Homemaker, Teacher, Doctor...',
                          ),

                          const SizedBox(height: 20),

                          // SECTION 7: Badges & Toggles
                          _buildSectionTitle('07', 'Badges & Verification'),
                          const SizedBox(height: 10),

                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Photo Available Only', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                            value: _hasPhoto,
                            activeTrackColor: const Color(0xFF750000),
                            onChanged: (val) => setModalState(() => _hasPhoto = val),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Blue Tick Verified Only', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                            value: _verifiedOnly,
                            activeTrackColor: const Color(0xFF1E88E5),
                            onChanged: (val) => setModalState(() => _verifiedOnly = val),
                          ),
                          const SizedBox(height: 12),

                          // Sort By
                          _buildDropdownField(
                            label: 'Sort Results By',
                            value: _sortBy,
                            items: const [
                              {'value': 'newest', 'label': 'Newest Profiles First'},
                              {'value': 'age_asc', 'label': 'Age: Youngest to Oldest'},
                              {'value': 'age_desc', 'label': 'Age: Oldest to Youngest'},
                            ],
                            onChanged: (v) => setModalState(() => _sortBy = v ?? 'newest'),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                    // Apply Button Sticky Footer
                    Container(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset > 0 ? bottomInset + 8 : 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Color(0xFFE8DFD5), width: 1.0)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 10,
                            offset: Offset(0, -3),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF750000),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _performSearch();
                          },
                          icon: const Icon(CupertinoIcons.sparkles, size: 19, color: Color(0xFFE5B842)),
                          label: Text(
                            'Search Matches (${_activeFiltersCount > 0 ? "$_activeFiltersCount Filters" : "All Profiles"})',
                            style: GoogleFonts.outfit(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
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

  Widget _buildTextInputField({
    required String label,
    required TextEditingController controller,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                fontSize: 12.5,
                color: const Color(0xFF94A3B8),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String num, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF750000).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            num,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF750000),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F1F1F),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedTab(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF750000) : const Color(0xFFF4EEE6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF750000) : const Color(0xFFE0D7CC),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF555555),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Ensure value is present in items
    final hasValue = items.any((i) => i['value'] == value);
    final safeValue = hasValue ? value : (items.isNotEmpty ? items.first['value'] : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF444444))),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: safeValue,
              icon: const Icon(CupertinoIcons.chevron_down, size: 14, color: Color(0xFF64748B)),
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E293B), fontWeight: FontWeight.w500),
              dropdownColor: Colors.white,
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item['value'],
                  child: Text(item['label'] ?? item['value'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
