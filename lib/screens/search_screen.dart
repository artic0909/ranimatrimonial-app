import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../components/rani_alert.dart';
import '../components/rani_skeleton_loader.dart';
import 'profile_detail_screen.dart';

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
  int _totalCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      _applyInitialFilters(widget.initialFilters!);
    }
    _loadSearchOptions();
  }

  void _applyInitialFilters(Map<String, dynamic> f) {
    if (f['gender'] != null) _gender = f['gender'];
    if (f['religion'] != null) _religion = f['religion'];
    if (f['city'] != null) _city = f['city'];
    if (f['keyword'] != null) _keywordController.text = f['keyword'];
  }

  @override
  void dispose() {
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
        setState(() {
          _results = res['profiles'] ?? res['candidates'] ?? [];
          _totalCount = res['total_count'] ?? _results.length;
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

  void _onReligionSelected(String rel) {
    setState(() {
      _religion = rel;
      _community = 'all';
      _availableCommunities = [];
      if (rel != 'all') {
        final found = _religions.firstWhere(
          (r) => r['name'] == rel,
          orElse: () => null,
        );
        if (found != null && found['communities'] != null) {
          _availableCommunities = found['communities'];
        }
      }
    });
  }

  void _onCountrySelected(String countryName) {
    setState(() {
      _country = countryName;
      _state = 'all';
      _city = 'all';
      _availableStates = [];
      _availableCities = [];
      if (countryName != 'all') {
        final found = _countries.firstWhere(
          (c) => c['name'] == countryName,
          orElse: () => null,
        );
        if (found != null && found['states'] != null) {
          _availableStates = found['states'];
        }
      }
    });
  }

  void _onStateSelected(String stateName) {
    setState(() {
      _state = stateName;
      _city = 'all';
      _availableCities = [];
      if (stateName != 'all') {
        final found = _availableStates.firstWhere(
          (s) => s['name'] == stateName,
          orElse: () => null,
        );
        if (found != null && found['cities'] != null) {
          _availableCities = found['cities'];
        }
      }
    });
  }

  Future<void> _toggleShortlist(String profileId, String name, int index) async {
    try {
      final res = await ApiService.instance.toggleShortlist(profileId);
      if (!mounted) return;

      if (res['success'] == true) {
        final isShortlisted = res['shortlisted'] == true;
        setState(() {
          _results[index]['is_shortlisted'] = isShortlisted;
        });
        RaniAlert.success(
          context,
          isShortlisted ? '$name added to Shortlist!' : '$name removed from Shortlist.',
          title: isShortlisted ? 'Shortlisted' : 'Removed',
        );
      } else {
        RaniAlert.error(context, res['message'] ?? 'Action failed.');
      }
    } catch (e) {
      if (mounted) RaniAlert.error(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Search Profiles',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2B0A0D),
          ),
        ),
        actions: [
          // Filter Button with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.slider_horizontal_3, color: Color(0xFF750000), size: 22),
                tooltip: 'Open Advanced Filters',
                onPressed: _openFilterBottomSheet,
              ),
              if (_activeFiltersCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4A034),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_activeFiltersCount',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Reset button
          if (_activeFiltersCount > 0)
            IconButton(
              icon: const Icon(CupertinoIcons.arrow_counterclockwise, color: Color(0xFF750000), size: 20),
              tooltip: 'Reset All',
              onPressed: _resetAllFilters,
            ),
        ],
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

            // 2. Quick Presets Bar (Brides, Grooms, Never Married, Vegetarian, Non-Manglik, Post Graduate, Govt/PSU)
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildQuickPreset(
                    label: 'Brides',
                    icon: CupertinoIcons.person_crop_circle_fill_badge_checkmark,
                    isActive: _gender == 'Female',
                    onTap: () {
                      setState(() => _gender = _gender == 'Female' ? 'all' : 'Female');
                      _performSearch();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickPreset(
                    label: 'Grooms',
                    icon: CupertinoIcons.person_crop_circle,
                    isActive: _gender == 'Male',
                    onTap: () {
                      setState(() => _gender = _gender == 'Male' ? 'all' : 'Male');
                      _performSearch();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickPreset(
                    label: 'Never Married',
                    icon: CupertinoIcons.heart_fill,
                    isActive: _maritalStatus == 'Never Married',
                    onTap: () {
                      setState(() => _maritalStatus = _maritalStatus == 'Never Married' ? 'all' : 'Never Married');
                      _performSearch();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickPreset(
                    label: 'Vegetarian',
                    icon: CupertinoIcons.leaf_arrow_circlepath,
                    isActive: _diet == 'Vegetarian',
                    onTap: () {
                      setState(() => _diet = _diet == 'Vegetarian' ? 'all' : 'Vegetarian');
                      _performSearch();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickPreset(
                    label: 'Non-Manglik',
                    icon: CupertinoIcons.star_circle_fill,
                    isActive: _manglik == 'Non-Manglik',
                    onTap: () {
                      setState(() => _manglik = _manglik == 'Non-Manglik' ? 'all' : 'Non-Manglik');
                      _performSearch();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickPreset(
                    label: 'Post Graduate',
                    icon: CupertinoIcons.book_fill,
                    isActive: _highestQualification == 'Masters',
                    onTap: () {
                      setState(() => _highestQualification = _highestQualification == 'Masters' ? 'all' : 'Masters');
                      _performSearch();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickPreset(
                    label: 'Govt / PSU',
                    icon: CupertinoIcons.building_2_fill,
                    isActive: _workingWith == 'Government / Public Sector',
                    onTap: () {
                      setState(() => _workingWith = _workingWith == 'Government / Public Sector' ? 'all' : 'Government / Public Sector');
                      _performSearch();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 3. Toolbar: Photo & Verified toggles + Total Count + Sort
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Photo Only toggle chip
                  InkWell(
                    onTap: () {
                      setState(() => _hasPhoto = !_hasPhoto);
                      _performSearch();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _hasPhoto ? const Color(0xFF750000) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _hasPhoto ? const Color(0xFF750000) : const Color(0xFFE8DFD5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.camera_fill,
                            size: 13,
                            color: _hasPhoto ? Colors.white : const Color(0xFF555555),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'With Photo',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _hasPhoto ? Colors.white : const Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Verified Only toggle chip
                  InkWell(
                    onTap: () {
                      setState(() => _verifiedOnly = !_verifiedOnly);
                      _performSearch();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _verifiedOnly ? const Color(0xFF1E88E5) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _verifiedOnly ? const Color(0xFF1E88E5) : const Color(0xFFE8DFD5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            size: 13,
                            color: _verifiedOnly ? Colors.white : const Color(0xFF1E88E5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Only',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _verifiedOnly ? Colors.white : const Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

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
                        borderRadius: BorderRadius.circular(20),
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
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'newest', child: Text('Newest First')),
                      const PopupMenuItem(value: 'match_score', child: Text('Best Match Score')),
                      const PopupMenuItem(value: 'age_asc', child: Text('Age: Young to Old')),
                      const PopupMenuItem(value: 'age_desc', child: Text('Age: Old to Young')),
                    ],
                  ),
                ],
              ),
            ),

            // Active count text
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isSearching
                        ? 'Searching candidate profiles...'
                        : '$_totalCount Profiles Found',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF555555),
                    ),
                  ),
                  if (_activeFiltersCount > 0)
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

  Widget _buildQuickPreset({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF750000) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF750000) : const Color(0xFFE8DFD5),
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: const Color(0xFF750000).withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? const Color(0xFFD4A034) : const Color(0xFF666666),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    // Post-Login Skeleton Screen Loader
    if (_isSearching || _isLoadingOptions) {
      return const SingleChildScrollView(
        child: RaniSkeletonGrid(itemCount: 6),
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

    // 2-Column Grid (Row Two) matching Home Screen style
    return RefreshIndicator(
      color: const Color(0xFF750000),
      onRefresh: _performSearch,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _results.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (context, index) {
          final c = _results[index];
          return _buildCandidateCard(c, index);
        },
      ),
    );
  }

  Widget _buildCandidateCard(dynamic c, int index) {
    final profileId = c['candidate_code'] ?? c['profile_id'] ?? c['id']?.toString() ?? 'RM-PROFILE';
    final firstName = c['first_name'] ?? 'Candidate';
    final lastName = c['last_name'] ?? '';
    final displayName = lastName.isNotEmpty ? '$firstName ${lastName[0]}.' : firstName;
    final age = c['age'] ?? '25';
    final profession = c['profession'] ?? c['designation'] ?? 'Professional';
    final city = c['city'] ?? 'City';
    final state = c['state'] ?? '';
    final locationText = state.isNotEmpty ? '$city, $state' : city;
    final photo = c['photo'] ?? c['profile_picture'] ?? '';
    final isVerified = c['verified'] == true || c['is_verified'] == 1 || (c['bluetick'] != null && c['bluetick']['is_accept'] == 1);
    final isShortlisted = c['is_shortlisted'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE8DE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo with verified pill & heart button
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: photo.isNotEmpty
                        ? Image.network(
                            photo,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFF3ECE4),
                              child: const Icon(CupertinoIcons.person_fill, size: 48, color: Color(0xFFBCAAA4)),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFF3ECE4),
                            child: const Icon(CupertinoIcons.person_fill, size: 48, color: Color(0xFFBCAAA4)),
                          ),
                  ),

                  // Verified pill badge (Bottom-Left)
                  if (isVerified)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.checkmark_seal_fill,
                              color: Color(0xFF2E7D32),
                              size: 13,
                            ),
                            const SizedBox(width: 3.5),
                            Text(
                              'Verified profile',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Shortlist Heart Button (Top-Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleShortlist(profileId, displayName, index),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isShortlisted ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                          size: 17,
                          color: isShortlisted ? const Color(0xFFD32F2F) : const Color(0xFF750000),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info details & action button
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Candidate Name & Age
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$age years',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B6B6B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Profession
                  Text(
                    profession,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4A4A4A),
                    ),
                  ),
                  const SizedBox(height: 1),

                  // Location
                  Text(
                    locationText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF7A7A7A),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // View Profile Button
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF750000),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RaniProfileDetailScreen(
                              profileId: profileId,
                              initialProfileData: c,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'View Profile',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 7-SECTION FILTER BOTTOM SHEET MODAL =================
  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    // Handle Bar
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Sheet Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(CupertinoIcons.slider_horizontal_3, color: Color(0xFF750000), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Filter Profiles',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2B0A0D),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _resetAllFilters();
                              });
                              Navigator.pop(ctx);
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

                    const Divider(height: 1, color: Color(0xFFE8DFD5)),

                    // Scrollable Sections
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          const SizedBox(height: 12),

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
                                _onReligionSelected(v ?? 'all');
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          // Community / Caste Dropdown (Cascading!)
                          _buildDropdownField(
                            label: 'Community / Caste',
                            value: _community,
                            items: [
                              {'value': 'all', 'label': 'All Communities'},
                              ..._availableCommunities.map((c) => {'value': c['name'].toString(), 'label': c['name'].toString()}),
                            ],
                            onChanged: (v) => setModalState(() => _community = v ?? 'all'),
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
                            onChanged: (v) => setModalState(() => _onCountrySelected(v ?? 'all')),
                          ),
                          const SizedBox(height: 12),

                          // State Dropdown
                          _buildDropdownField(
                            label: 'State',
                            value: _state,
                            items: [
                              {'value': 'all', 'label': 'All States'},
                              ..._availableStates.map((s) => {'value': s['name'].toString(), 'label': s['name'].toString()}),
                            ],
                            onChanged: (v) => setModalState(() => _onStateSelected(v ?? 'all')),
                          ),
                          const SizedBox(height: 12),

                          // City Dropdown
                          _buildDropdownField(
                            label: 'City',
                            value: _city,
                            items: [
                              {'value': 'all', 'label': 'All Cities'},
                              ..._availableCities.map((ct) => {'value': ct['name'].toString(), 'label': ct['name'].toString()}),
                            ],
                            onChanged: (v) => setModalState(() => _city = v ?? 'all'),
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

                          // SECTION 6: Family Financial Status
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

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                    // Apply Button Sticky Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Color(0xFFE8DFD5))),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF750000),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _performSearch();
                          },
                          child: Text(
                            'Apply Filters',
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
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
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1F1F1F),
            letterSpacing: 0.2,
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
