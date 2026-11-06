import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

enum ProfileSection {
  about,
  basics,
  religious,
  astro,
  educationCareer,
  location,
  family,
  contact,
}

/// Modal Bottom Sheet for editing specific profile sections individually
/// Aligned 100% with DB master models & website profile modals (dependent dropdowns & choosable items)
class RaniSectionEditModal extends StatefulWidget {
  final ProfileSection section;
  final Map<String, dynamic> candidate;
  final Future<bool> Function(String sectionKey, Map<String, dynamic> data) onSave;

  const RaniSectionEditModal({
    super.key,
    required this.section,
    required this.candidate,
    required this.onSave,
  });

  static Future<bool?> show({
    required BuildContext context,
    required ProfileSection section,
    required Map<String, dynamic> candidate,
    required Future<bool> Function(String sectionKey, Map<String, dynamic> data) onSave,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RaniSectionEditModal(
        section: section,
        candidate: candidate,
        onSave: onSave,
      ),
    );
  }

  @override
  State<RaniSectionEditModal> createState() => _RaniSectionEditModalState();
}

class _RaniSectionEditModalState extends State<RaniSectionEditModal> {
  bool _isSaving = false;

  // ==========================================
  // Master Lists (Seeded with standard defaults & updated from DB via API)
  // ==========================================
  List<String> _countryOptions = ['India', 'Bangladesh', 'United States', 'United Kingdom', 'Canada', 'Australia', 'United Arab Emirates'];
  Map<String, List<String>> _countryToStates = {
    'India': [
      'West Bengal',
      'Maharashtra',
      'Delhi',
      'Karnataka',
      'Tamil Nadu',
      'Uttar Pradesh',
      'Gujarat',
      'Telangana',
      'Kerala',
      'Rajasthan',
      'Punjab',
      'Haryana',
      'Bihar',
      'Odisha',
      'Assam',
      'Madhya Pradesh',
      'Jharkhand',
      'Andhra Pradesh',
    ],
  };

  Map<String, Map<String, List<String>>> _countryStateToCities = {
    'India': {
      'West Bengal': [
        'Kolkata',
        'Howrah',
        'Siliguri',
        'Durgapur',
        'Asansol',
        'Bardhaman',
        'Kharagpur',
        'Malda',
        'Berhampore',
        'Habra',
      ],
      'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik'],
      'Delhi': ['New Delhi', 'North Delhi', 'South Delhi', 'East Delhi', 'West Delhi'],
      'Karnataka': ['Bengaluru', 'Mysuru', 'Hubballi', 'Mangaluru', 'Belagavi'],
    },
  };

  List<String> _religionOptions = [
    'Hindu',
    'Muslim',
    'Christian',
    'Sikh',
    'Jain',
    'Buddhist',
    'Parsi',
    'Jewish',
    'Other',
  ];

  Map<String, List<String>> _religionToCommunities = {
    'Hindu': ['Brahmin', 'Kayastha', 'Baishya', 'Kshatriya', 'Sunri', 'Mahisya', 'Sadgope', 'Agarwal', 'Marwari', 'Baniya', 'Khatri', 'Other'],
    'Muslim': ['Sunni', 'Shia', 'Ansari', 'Qureshi', 'Sayyid', 'Shaikh', 'Pathan', 'Other'],
    'Christian': ['Roman Catholic', 'Protestant', 'Orthodox', 'Born Again', 'Evangelical', 'Other'],
    'Sikh': ['Jat', 'Khatri', 'Ramgarhia', 'Arora', 'Other'],
    'Jain': ['Digambar', 'Shwetambar', 'Other'],
    'Buddhist': ['Neo-Buddhist', 'Theravada', 'Other'],
    'Other': ['Other'],
  };

  List<String> _qualificationOptions = [
    'B.Tech / B.E. (Engineering)',
    'B-Tech',
    'B.Sc. (Bachelor of Science)',
    'B.Com. (Bachelor of Commerce)',
    'B.A. (Bachelor of Arts)',
    'BBA / BMS (Management)',
    'BCA / B.Sc. IT',
    'MBBS / BDS (Medical)',
    'MD / MS (Medical)',
    'MBA / PGDM (Management)',
    'M.Tech / M.E. (Engineering)',
    'M.Sc. (Master of Science)',
    'M.Com. (Master of Commerce)',
    'M.A. (Master of Arts)',
    'MCA / M.Sc. IT',
    'CA / CS / ICWA',
    'LLB / LLM (Law)',
    'Diploma / Polytechnic',
    'High School (10th / 12th)',
    'Ph.D. / Doctorate',
    'Other Professional Degree',
  ];

  List<String> _workingSectorOptions = [
    'Private Company',
    'Government / PSU',
    'Business / Self-Employed',
    'Defense / Civil Services',
    'Not Working',
  ];

  List<String> _incomeOptions = [
    'No Income',
    'Under 1 Lakh',
    '1 - 2 Lakhs',
    '2 - 3 Lakhs',
    '3 - 4 Lakhs',
    '4 - 5 Lakhs',
    '5 - 7.5 Lakhs',
    '7.5 - 10 Lakhs',
    '10 - 15 Lakhs',
    '15 - 20 Lakhs',
    '20 - 30 Lakhs',
    '30 - 50 Lakhs',
    '50 - 75 Lakhs',
    '75 Lakhs - 1 Crore',
    '1 Crore & Above',
  ];

  List<String> _maritalStatusOptions = [
    'Never Married',
    'Divorced',
    'Widowed',
    'Awaiting Divorce',
    'Annulled',
  ];

  List<String> _heightOptions = [
    "4' 8\"", "4' 9\"", "4' 10\"", "4' 11\"", "5' 0\"", "5' 1\"", "5' 2\"", "5' 3\"",
    "5' 4\"", "5' 5\"", "5' 6\"", "5' 7\"", "5' 8\"", "5' 9\"", "5' 10\"", "5' 11\"",
    "6' 0\"", "6' 1\"", "6' 2\"", "6' 3\"", "6' 4\""
  ];

  List<String> _dietOptions = [
    'Vegetarian',
    'Non-Vegetarian',
    'Eggetarian',
    'Jain',
    'Vegan',
  ];

  static const List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  static const List<String> _motherTongues = [
    'Bengali',
    'Hindi',
    'English',
    'Urdu',
    'Odia',
    'Assamese',
    'Telugu',
    'Tamil',
    'Marathi',
    'Gujarati',
    'Punjabi',
    'Malayalam',
    'Kannada',
  ];

  static const List<String> _manglikOptions = [
    'Non-Manglik',
    'Manglik',
    'Angshik Manglik',
    'Don\'t Know',
  ];

  static const List<String> _residencyTypes = [
    'Citizen',
    'Permanent Resident',
    'Work Permit',
    'Student Visa',
  ];

  static const List<String> _financialStatuses = [
    'Middle Class',
    'Upper Middle Class',
    'Affluent',
    'High Class',
  ];

  static const List<String> _contactDisplayOptions = [
    'Visible to all Premium Members',
    'Visible only after I accept connection',
    'Hide my contact details from all',
  ];

  // Master Hobbies list
  List<String> _allHobbies = [
    'Reading Books',
    'Traveling & Exploring',
    'Cooking & Culinary Arts',
    'Music & Playing Instruments',
    'Singing',
    'Photography',
    'Dancing',
    'Painting & Sketching',
    'Gardening & Plants',
    'Fitness, Gym & Workouts',
    'Yoga & Meditation',
    'Movies & OTT Series',
    'Writing & Blogging',
    'Playing Sports (Cricket, Football, Badminton)',
    'Trekking & Outdoor Adventures',
    'Video Gaming & Esports',
    'Volunteering & Social Service',
    'Pet Care & Animals',
    'Theater & Performing Arts',
    'Cycling & Running',
    'Board Games & Puzzles',
    'DIY & Crafting',
  ];

  final Set<String> _selectedHobbies = {};
  final TextEditingController _customHobbyController = TextEditingController();

  // Selected State Values
  // 1. About
  late final TextEditingController _aboutController;

  // 2. Basics
  String? _maritalStatus;
  String? _height;
  String? _diet;
  String? _bloodGroup;
  late final TextEditingController _healthInfoController;
  late final TextEditingController _grewUpInController;
  late final TextEditingController _disabilityController;

  // 3. Religious
  String? _religion;
  String? _community;
  late final TextEditingController _subCommunityController;
  String? _motherTongue;
  late final TextEditingController _gothraController;

  // 4. Astro
  String? _manglik;
  late final TextEditingController _timeOfBirthController;
  late final TextEditingController _cityOfBirthController;

  // 5. Education & Career
  String? _qualification;
  late final TextEditingController _collegeController;
  String? _workingWith;
  late final TextEditingController _professionController;
  late final TextEditingController _designationController;
  late final TextEditingController _companyController;
  String? _annualIncome;

  // 6. Location
  String? _country;
  String? _state;
  String? _city;
  late final TextEditingController _cityTextController;
  String? _residencyStatus;
  late final TextEditingController _pincodeController;
  late final TextEditingController _policeStController;
  late final TextEditingController _fullAddressController;

  // 7. Family
  late final TextEditingController _fatherProfessionController;
  late final TextEditingController _motherProfessionController;
  int _brothersCount = 0;
  int _sistersCount = 0;
  late final TextEditingController _familyLocationController;
  String? _familyFinancialStatus;

  // 8. Contact
  String? _contactDisplayOption;

  @override
  void initState() {
    super.initState();
    final c = widget.candidate;

    // 1. About
    _aboutController = TextEditingController(text: c['about_yourself']?.toString() ?? '');

    // Parse pre-selected hobbies from database candidate
    dynamic rawHobbies = c['hobbies_interests'];
    if (rawHobbies is List) {
      for (var h in rawHobbies) {
        if (h != null && h.toString().trim().isNotEmpty) {
          _selectedHobbies.add(h.toString().trim());
        }
      }
    } else if (rawHobbies is String && rawHobbies.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawHobbies);
        if (decoded is List) {
          for (var h in decoded) {
            if (h != null && h.toString().trim().isNotEmpty) {
              _selectedHobbies.add(h.toString().trim());
            }
          }
        } else {
          _selectedHobbies.addAll(
            rawHobbies.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
          );
        }
      } catch (_) {
        _selectedHobbies.addAll(
          rawHobbies.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
        );
      }
    }

    // Ensure candidate's hobbies are included in _allHobbies
    for (final h in _selectedHobbies) {
      if (!_allHobbies.any((item) => item.toLowerCase() == h.toLowerCase())) {
        _allHobbies.insert(0, h);
      }
    }

    // 2. Basics
    _maritalStatus = _findMatch(_maritalStatusOptions, c['marital_status']);
    _height = _findMatch(_heightOptions, c['height']);
    _diet = _findMatch(_dietOptions, c['diet']);
    _bloodGroup = _findMatch(_bloodGroups, c['blood_group']);
    _healthInfoController = TextEditingController(text: c['health_info']?.toString() ?? '');
    _grewUpInController = TextEditingController(text: c['grew_up_in']?.toString() ?? '');
    _disabilityController = TextEditingController(text: c['disability']?.toString() ?? 'None');

    // 3. Religious
    _religion = _findMatch(_religionOptions, c['religion']);
    final initialComms = _availableCommunities;
    _community = _findMatch(initialComms, c['community']) ?? c['community']?.toString().trim();
    if (_community != null && _community!.isNotEmpty && !initialComms.contains(_community)) {
      if (_religion != null) {
        _religionToCommunities[_religion!] ??= [];
        _religionToCommunities[_religion!]!.insert(0, _community!);
      }
    }
    _subCommunityController = TextEditingController(text: c['sub_community']?.toString() ?? '');
    _motherTongue = _findMatch(_motherTongues, c['mother_tongue']) ?? c['mother_tongue']?.toString().trim();
    _gothraController = TextEditingController(text: c['gothra']?.toString() ?? '');

    // 4. Astro
    _manglik = _findMatch(_manglikOptions, c['manglik']);
    _timeOfBirthController = TextEditingController(text: c['time_of_birth']?.toString() ?? '');
    _cityOfBirthController = TextEditingController(text: c['city_of_birth']?.toString() ?? '');

    // 5. Education & Career
    _qualification = _findMatch(_qualificationOptions, c['highest_qualification']) ?? c['highest_qualification']?.toString().trim();
    if (_qualification != null && _qualification!.isNotEmpty && !_qualificationOptions.contains(_qualification)) {
      _qualificationOptions.insert(0, _qualification!);
    }
    _collegeController = TextEditingController(text: c['college_name']?.toString() ?? '');
    _workingWith = _findMatch(_workingSectorOptions, c['working_with']);
    _professionController = TextEditingController(text: c['profession']?.toString() ?? '');
    _designationController = TextEditingController(text: c['designation']?.toString() ?? '');
    _companyController = TextEditingController(text: c['company_name']?.toString() ?? '');
    final rawIncome = c['annual_income']?.toString().trim();
    _annualIncome = _findIncomeMatch(_incomeOptions, rawIncome) ??
        (rawIncome != null && rawIncome.isNotEmpty && rawIncome != '-' ? rawIncome : null);
    if (_annualIncome != null && !_incomeOptions.contains(_annualIncome)) {
      _incomeOptions.insert(0, _annualIncome!);
    }

    // 6. Location (Country -> State -> City dependent hierarchy)
    _country = _findMatch(_countryOptions, c['country']) ?? c['country']?.toString().trim() ?? 'India';
    if (_country != null && !_countryOptions.contains(_country)) {
      _countryOptions.insert(0, _country!);
    }

    final initialStates = _availableStates;
    _state = _findMatch(initialStates, c['state']) ?? c['state']?.toString().trim();
    if (_state != null && _state!.isNotEmpty && !initialStates.contains(_state)) {
      if (_country != null) {
        _countryToStates[_country!] ??= [];
        _countryToStates[_country!]!.insert(0, _state!);
      }
    }

    final initialCities = _availableCities;
    _city = _findMatch(initialCities, c['city']) ?? c['city']?.toString().trim();
    if (_city != null && _city!.isNotEmpty && !initialCities.contains(_city)) {
      if (_country != null && _state != null) {
        _countryStateToCities[_country!] ??= {};
        _countryStateToCities[_country!]![_state!] ??= [];
        _countryStateToCities[_country!]![_state!]!.insert(0, _city!);
      }
    }
    _cityTextController = TextEditingController(text: _city ?? '');
    _cityTextController.addListener(() {
      _city = _cityTextController.text.trim();
    });

    _residencyStatus = _findMatch(_residencyTypes, c['residency_status']) ?? 'Citizen';
    _pincodeController = TextEditingController(text: c['pincode']?.toString() ?? c['zip_code']?.toString() ?? '');
    _policeStController = TextEditingController(text: c['police_st']?.toString() ?? '');
    _fullAddressController = TextEditingController(text: c['full_address']?.toString() ?? '');

    // 7. Family
    _fatherProfessionController = TextEditingController(text: c['father_profession']?.toString() ?? '');
    _motherProfessionController = TextEditingController(text: c['mother_profession']?.toString() ?? '');
    _brothersCount = int.tryParse(c['brothers_count']?.toString() ?? '0') ?? 0;
    _sistersCount = int.tryParse(c['sisters_count']?.toString() ?? '0') ?? 0;
    _familyLocationController = TextEditingController(text: c['family_location']?.toString() ?? '');
    _familyFinancialStatus = _findMatch(_financialStatuses, c['family_financial_status']);

    // 8. Contact
    _contactDisplayOption = _findMatch(_contactDisplayOptions, c['contact_display_option']) ?? _contactDisplayOptions[0];

    // Load dynamic DB Master data from API
    _loadMasterOptionsFromDb();
  }

  // Dependent Options Getters
  List<String> get _availableStates {
    if (_country == null) return const [];
    return _countryToStates[_country] ?? const [];
  }

  List<String> get _availableCities {
    if (_country == null || _state == null) return const [];
    return _countryStateToCities[_country]?[_state] ?? const [];
  }

  List<String> get _availableCommunities {
    if (_religion == null) return const [];
    return _religionToCommunities[_religion] ?? const [];
  }

  String? _findMatch(List<String> list, dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim();
    if (str.isEmpty || str == '-') return null;
    try {
      return list.firstWhere(
        (item) => item.toLowerCase() == str.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  String? _findIncomeMatch(List<String> list, dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim();
    if (str.isEmpty || str == '-') return null;

    // 1. Exact case-insensitive match
    for (final item in list) {
      if (item.toLowerCase() == str.toLowerCase()) {
        return item;
      }
    }

    // 2. Normalized match (strip ₹, rs., inr, plural 's', extra spaces)
    String normalize(String s) {
      return s
          .toLowerCase()
          .replaceAll('₹', '')
          .replaceAll('rs.', '')
          .replaceAll('rs', '')
          .replaceAll('inr', '')
          .replaceAll('lakhs', 'lakh')
          .replaceAll('crores', 'crore')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    final normVal = normalize(str);
    for (final item in list) {
      if (normalize(item) == normVal) {
        return item;
      }
    }

    // 3. Number extraction match (e.g., "20 - 30" in "₹ 20 - 30 Lakh" and "20 - 30 Lakhs")
    final numbersInVal = RegExp(r'\d+(\.\d+)?')
        .allMatches(str)
        .map((m) => m.group(0))
        .toList();
    if (numbersInVal.isNotEmpty) {
      for (final item in list) {
        final numbersInItem = RegExp(r'\d+(\.\d+)?')
            .allMatches(item)
            .map((m) => m.group(0))
            .toList();
        if (numbersInVal.length == numbersInItem.length &&
            numbersInVal.join(',') == numbersInItem.join(',')) {
          final valHasCrore = str.toLowerCase().contains('crore');
          final itemHasCrore = item.toLowerCase().contains('crore');
          if (valHasCrore == itemHasCrore) {
            return item;
          }
        }
      }
    }

    return null;
  }

  @override
  void dispose() {
    _aboutController.dispose();
    _customHobbyController.dispose();
    _healthInfoController.dispose();
    _grewUpInController.dispose();
    _disabilityController.dispose();
    _subCommunityController.dispose();
    _gothraController.dispose();
    _timeOfBirthController.dispose();
    _cityOfBirthController.dispose();
    _collegeController.dispose();
    _professionController.dispose();
    _designationController.dispose();
    _companyController.dispose();
    _cityTextController.dispose();
    _pincodeController.dispose();
    _policeStController.dispose();
    _fullAddressController.dispose();
    _fatherProfessionController.dispose();
    _motherProfessionController.dispose();
    _familyLocationController.dispose();
    super.dispose();
  }

  Future<void> _loadMasterOptionsFromDb() async {
    try {
      final res = await ApiService.instance.getRegistrationOptions();
      if (!mounted) return;
      if (res['success'] == true && res['data'] != null && res['data'] is Map) {
        final data = res['data'] as Map<String, dynamic>;

        // 1. Countries -> States -> Cities
        if (data['countries'] is List) {
          final List<String> loadedCountries = [];
          final Map<String, List<String>> loadedStates = {};
          final Map<String, Map<String, List<String>>> loadedCities = {};

          for (var cItem in data['countries']) {
            final cName = cItem['name']?.toString().trim() ?? '';
            if (cName.isNotEmpty) {
              loadedCountries.add(cName);
              final List<String> statesList = [];
              final Map<String, List<String>> stateCitiesMap = {};

              if (cItem['states'] is List) {
                for (var sItem in cItem['states']) {
                  final sName = sItem['name']?.toString().trim() ?? '';
                  if (sName.isNotEmpty) {
                    statesList.add(sName);
                    final List<String> citiesList = [];
                    if (sItem['cities'] is List) {
                      for (var ctItem in sItem['cities']) {
                        final ctName = ctItem['name']?.toString().trim() ?? '';
                        if (ctName.isNotEmpty) citiesList.add(ctName);
                      }
                    }
                    stateCitiesMap[sName] = citiesList;
                  }
                }
              }
              loadedStates[cName] = statesList;
              loadedCities[cName] = stateCitiesMap;
            }
          }

          if (loadedCountries.isNotEmpty) {
            _countryOptions = loadedCountries;
            _countryToStates = loadedStates;
            _countryStateToCities = loadedCities;
          }
        }

        // 2. Religions -> Communities
        if (data['religions'] is List) {
          final List<String> loadedReligions = [];
          final Map<String, List<String>> loadedCommunities = {};

          for (var rItem in data['religions']) {
            final rName = rItem['name']?.toString().trim() ?? '';
            if (rName.isNotEmpty) {
              loadedReligions.add(rName);
              final List<String> comms = [];
              if (rItem['communities'] is List) {
                for (var comm in rItem['communities']) {
                  final commName = comm['name']?.toString().trim() ?? '';
                  if (commName.isNotEmpty) comms.add(commName);
                }
              }
              loadedCommunities[rName] = comms;
            }
          }
          if (loadedReligions.isNotEmpty) {
            _religionOptions = loadedReligions;
            _religionToCommunities = loadedCommunities;
          }
        }

        // 3. Qualifications
        if (data['qualifications'] is List) {
          final qList = <String>[];
          for (var item in data['qualifications']) {
            final name = item is Map ? item['name']?.toString().trim() : item?.toString().trim();
            if (name != null && name.isNotEmpty) qList.add(name);
          }
          if (qList.isNotEmpty) {
            _qualificationOptions = qList;
          }
        }

        // 4. Working Sectors
        if (data['working_withs'] is List) {
          final wList = <String>[];
          for (var item in data['working_withs']) {
            final name = item is Map ? item['name']?.toString().trim() : item?.toString().trim();
            if (name != null && name.isNotEmpty) wList.add(name);
          }
          if (wList.isNotEmpty) {
            _workingSectorOptions = wList;
          }
        }

        // 5. Incomes
        if (data['incomes'] is List) {
          final iList = <String>[];
          for (var item in data['incomes']) {
            final name = item is Map ? item['name']?.toString().trim() : item?.toString().trim();
            if (name != null && name.isNotEmpty) iList.add(name);
          }
          if (iList.isNotEmpty) {
            _incomeOptions = iList;
            if (_annualIncome != null && _annualIncome!.isNotEmpty) {
              final matched = _findIncomeMatch(_incomeOptions, _annualIncome);
              if (matched != null) {
                _annualIncome = matched;
              } else if (!_incomeOptions.contains(_annualIncome)) {
                _incomeOptions.insert(0, _annualIncome!);
              }
            }
          }
        }

        // 6. Marital Statuses
        if (data['marital_statuses'] is List) {
          final mList = <String>[];
          for (var item in data['marital_statuses']) {
            final name = item is Map ? item['name']?.toString().trim() : item?.toString().trim();
            if (name != null && name.isNotEmpty) mList.add(name);
          }
          if (mList.isNotEmpty) {
            _maritalStatusOptions = mList;
          }
        }

        // 7. Diets
        if (data['diets'] is List) {
          final dList = <String>[];
          for (var item in data['diets']) {
            final name = item is Map ? item['name']?.toString().trim() : item?.toString().trim();
            if (name != null && name.isNotEmpty) dList.add(name);
          }
          if (dList.isNotEmpty) {
            _dietOptions = dList;
          }
        }

        // 8. Heights
        if (data['heights'] is List) {
          final hList = <String>[];
          for (var item in data['heights']) {
            final name = item is Map ? item['name']?.toString().trim() : item?.toString().trim();
            if (name != null && name.isNotEmpty) hList.add(name);
          }
          if (hList.isNotEmpty) {
            _heightOptions = hList;
          }
        }

        // 9. Hobbies
        if (data['hobbies'] is List) {
          final dbList = <String>[];
          for (var item in data['hobbies']) {
            final name = item is Map ? item['name']?.toString().trim() : item?.toString().trim();
            if (name != null && name.isNotEmpty) dbList.add(name);
          }
          if (dbList.isNotEmpty) {
            final merged = <String>{...dbList, ..._selectedHobbies};
            _allHobbies = merged.toList();
          }
        }

        // Ensure candidate values exist in lists so they remain pre-selected
        _reSyncCandidateSelections();
        setState(() {});
      }
    } catch (_) {}
  }

  void _reSyncCandidateSelections() {
    // 1. Location
    if (_country != null && !_countryOptions.contains(_country)) {
      _countryOptions.insert(0, _country!);
    }
    final availableStates = _availableStates;
    if (_state != null && !availableStates.contains(_state)) {
      if (_country != null) {
        _countryToStates[_country!] ??= [];
        _countryToStates[_country!]!.insert(0, _state!);
      }
    }
    final availableCities = _availableCities;
    if (_city != null && !availableCities.contains(_city)) {
      if (_country != null && _state != null) {
        _countryStateToCities[_country!] ??= {};
        _countryStateToCities[_country!]![_state!] ??= [];
        _countryStateToCities[_country!]![_state!]!.insert(0, _city!);
      }
    }

    // 2. Religious
    if (_religion != null && !_religionOptions.contains(_religion)) {
      _religionOptions.insert(0, _religion!);
    }
    final availableComms = _availableCommunities;
    if (_community != null && !availableComms.contains(_community)) {
      if (_religion != null) {
        _religionToCommunities[_religion!] ??= [];
        _religionToCommunities[_religion!]!.insert(0, _community!);
      }
    }

    // 3. Qualifications
    if (_qualification != null && !_qualificationOptions.contains(_qualification)) {
      _qualificationOptions.insert(0, _qualification!);
    }
  }

  void _addCustomHobby() {
    final text = _customHobbyController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (!_allHobbies.any((h) => h.toLowerCase() == text.toLowerCase())) {
        _allHobbies.add(text);
      }
      _selectedHobbies.add(text);
      _customHobbyController.clear();
    });
  }

  String get _sectionTitle {
    switch (widget.section) {
      case ProfileSection.about:
        return 'Edit Personality & About';
      case ProfileSection.basics:
        return 'Edit Basics & Lifestyle';
      case ProfileSection.religious:
        return 'Edit Religious Background';
      case ProfileSection.astro:
        return 'Edit Astro Details';
      case ProfileSection.educationCareer:
        return 'Edit Education & Career';
      case ProfileSection.location:
        return 'Edit Location Details';
      case ProfileSection.family:
        return 'Edit Family Details';
      case ProfileSection.contact:
        return 'Edit Contact Details';
    }
  }

  IconData get _sectionIcon {
    switch (widget.section) {
      case ProfileSection.about:
        return CupertinoIcons.person_crop_circle;
      case ProfileSection.basics:
        return CupertinoIcons.heart_circle;
      case ProfileSection.religious:
        return CupertinoIcons.book_circle;
      case ProfileSection.astro:
        return CupertinoIcons.sparkles;
      case ProfileSection.educationCareer:
        return CupertinoIcons.briefcase;
      case ProfileSection.location:
        return CupertinoIcons.location_circle;
      case ProfileSection.family:
        return CupertinoIcons.person_3_fill;
      case ProfileSection.contact:
        return CupertinoIcons.phone_circle;
    }
  }

  String get _sectionKey {
    switch (widget.section) {
      case ProfileSection.about:
        return 'about';
      case ProfileSection.basics:
        return 'basic';
      case ProfileSection.religious:
        return 'religious';
      case ProfileSection.astro:
        return 'astro';
      case ProfileSection.educationCareer:
        return 'education_career';
      case ProfileSection.location:
        return 'location';
      case ProfileSection.family:
        return 'family';
      case ProfileSection.contact:
        return 'contact';
    }
  }

  Map<String, dynamic> _collectData() {
    switch (widget.section) {
      case ProfileSection.about:
        return {
          'about_yourself': _aboutController.text.trim(),
          'hobbies_interests': _selectedHobbies.toList(),
        };

      case ProfileSection.basics:
        return {
          if (_maritalStatus != null) 'marital_status': _maritalStatus,
          if (_height != null) 'height': _height,
          if (_diet != null) 'diet': _diet,
          if (_bloodGroup != null) 'blood_group': _bloodGroup,
          'health_info': _healthInfoController.text.trim(),
          'grew_up_in': _grewUpInController.text.trim(),
          'disability': _disabilityController.text.trim(),
        };

      case ProfileSection.religious:
        return {
          if (_religion != null) 'religion': _religion,
          if (_community != null) 'community': _community,
          'sub_community': _subCommunityController.text.trim(),
          if (_motherTongue != null) 'mother_tongue': _motherTongue,
          'gothra': _gothraController.text.trim(),
        };

      case ProfileSection.astro:
        return {
          if (_manglik != null) 'manglik': _manglik,
          'time_of_birth': _timeOfBirthController.text.trim(),
          'city_of_birth': _cityOfBirthController.text.trim(),
        };

      case ProfileSection.educationCareer:
        return {
          if (_qualification != null) 'highest_qualification': _qualification,
          'college_name': _collegeController.text.trim(),
          if (_workingWith != null) 'working_with': _workingWith,
          'profession': _professionController.text.trim(),
          'designation': _designationController.text.trim(),
          'company_name': _companyController.text.trim(),
          if (_annualIncome != null) 'annual_income': _annualIncome,
        };

      case ProfileSection.location:
        return {
          if (_country != null) 'country': _country,
          if (_state != null) 'state': _state,
          if (_city != null) 'city': _city,
          if (_residencyStatus != null) 'residency_status': _residencyStatus,
          'pincode': _pincodeController.text.trim(),
          'police_st': _policeStController.text.trim(),
          'full_address': _fullAddressController.text.trim(),
        };

      case ProfileSection.family:
        return {
          'father_profession': _fatherProfessionController.text.trim(),
          'mother_profession': _motherProfessionController.text.trim(),
          'brothers_count': _brothersCount,
          'sisters_count': _sistersCount,
          'family_location': _familyLocationController.text.trim(),
          if (_familyFinancialStatus != null) 'family_financial_status': _familyFinancialStatus,
        };

      case ProfileSection.contact:
        return {
          if (_contactDisplayOption != null) 'contact_display_option': _contactDisplayOption,
          'full_address': _fullAddressController.text.trim(),
        };
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final data = _collectData();
    final success = await widget.onSave(_sectionKey, data);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6CBC3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF750000).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_sectionIcon, size: 20, color: const Color(0xFF750000)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _sectionTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF8E8E93)),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEFE8DE)),

              // Scrollable Form Fields
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionForm(),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF750000),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 1.5,
                          ),
                          onPressed: _isSaving ? null : _handleSave,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'Save Changes',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionForm() {
    switch (widget.section) {
      case ProfileSection.about:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('About Yourself / Bio'),
            _buildTextField(
              controller: _aboutController,
              hint: 'Write a few words about your background, lifestyle, and values...',
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 20),

            // Header for Hobbies & Interests with selected count pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.sparkles, size: 16, color: Color(0xFF750000)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Hobbies & Interests',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E1E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF750000).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF750000).withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    '${_selectedHobbies.length} Selected',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF750000),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Select activities and passions from database to help matches connect with you:',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF6E6E6E),
              ),
            ),
            const SizedBox(height: 12),

            // Choosable Hobbies Chips Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEFE8DE)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allHobbies.map((hobby) {
                  final isSelected = _selectedHobbies.contains(hobby);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedHobbies.remove(hobby);
                        } else {
                          _selectedHobbies.add(hobby);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 64,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF750000) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFE5B842) : const Color(0xFFD6CBC3),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF750000).withValues(alpha: 0.22),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check_rounded, size: 14, color: Color(0xFFE5B842)),
                            const SizedBox(width: 5),
                          ] else ...[
                            const Icon(Icons.add_rounded, size: 14, color: Color(0xFF8E8E93)),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              hobby,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFF2C2C2C),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Add Custom Hobby Input Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF7F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEFE8DE)),
                    ),
                    child: TextField(
                      controller: _customHobbyController,
                      style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E1E1E)),
                      decoration: InputDecoration(
                        hintText: 'Add another hobby or interest...',
                        hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF9E9E9E)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) => _addCustomHobby(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF750000),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _addCustomHobby,
                  child: Text(
                    '+ Add',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        );

      case ProfileSection.basics:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Marital Status'),
            _buildDropdownField(
              value: _maritalStatus,
              items: _maritalStatusOptions,
              hint: 'Select marital status',
              onChanged: (val) => setState(() => _maritalStatus = val),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Height'),
            _buildDropdownField(
              value: _height,
              items: _heightOptions,
              hint: 'Select height',
              onChanged: (val) => setState(() => _height = val),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Diet'),
            _buildDropdownField(
              value: _diet,
              items: _dietOptions,
              hint: 'Select diet',
              onChanged: (val) => setState(() => _diet = val),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Blood Group'),
            _buildDropdownField(
              value: _bloodGroup,
              items: _bloodGroups,
              hint: 'Select blood group',
              onChanged: (val) => setState(() => _bloodGroup = val),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Health Information'),
            _buildTextField(
              controller: _healthInfoController,
              hint: 'e.g. Normal, Fit & Active',
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Grew Up In (City / State)'),
            _buildTextField(
              controller: _grewUpInController,
              hint: 'e.g. Kolkata, West Bengal',
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Disability / Special Conditions'),
            _buildTextField(
              controller: _disabilityController,
              hint: 'e.g. None',
            ),
          ],
        );

      case ProfileSection.religious:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Religion'),
            _buildDropdownField(
              value: _religion,
              items: _religionOptions,
              hint: 'Select religion',
              onChanged: (val) {
                setState(() {
                  _religion = val;
                  _community = null; // Reset community when religion changes
                });
              },
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Community (Caste)'),
            _buildDropdownField(
              value: _community,
              items: _availableCommunities,
              hint: _religion == null ? 'Select religion first' : 'Select community',
              onChanged: _religion == null ? null : (val) => setState(() => _community = val),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Sub-Community'),
            _buildTextField(
              controller: _subCommunityController,
              hint: 'e.g. Kulin, Rarhi, etc.',
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Mother Tongue'),
            _buildDropdownField(
              value: _motherTongue,
              items: _motherTongues,
              hint: 'Select mother tongue',
              onChanged: (val) => setState(() => _motherTongue = val),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Gothra'),
            _buildTextField(
              controller: _gothraController,
              hint: 'e.g. Sandilya, Kashyap, etc.',
            ),
          ],
        );

      case ProfileSection.astro:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Manglik Status'),
            _buildDropdownField(
              value: _manglik,
              items: _manglikOptions,
              hint: 'Select manglik status',
              onChanged: (val) => setState(() => _manglik = val),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Time of Birth'),
            _buildTextField(
              controller: _timeOfBirthController,
              hint: 'e.g. 10:30 AM',
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('City of Birth'),
            _buildTextField(
              controller: _cityOfBirthController,
              hint: 'e.g. Kolkata, WB',
            ),
          ],
        );

      case ProfileSection.educationCareer:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Highest Qualification'),
            _buildDropdownField(
              value: _qualification,
              items: _qualificationOptions,
              hint: 'Select qualification',
              onChanged: (val) => setState(() => _qualification = val),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('College / University'),
            _buildTextField(
              controller: _collegeController,
              hint: 'e.g. Calcutta University, IIT Kharagpur',
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Working Sector'),
            _buildDropdownField(
              value: _workingWith,
              items: _workingSectorOptions,
              hint: 'Select working sector',
              onChanged: (val) => setState(() => _workingWith = val),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Profession / Job Role'),
            _buildTextField(
              controller: _professionController,
              hint: 'e.g. Software Engineer, Doctor, Banking',
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Designation / Role'),
            _buildTextField(
              controller: _designationController,
              hint: 'e.g. Senior Lead, Assistant Manager',
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Company Name'),
            _buildTextField(
              controller: _companyController,
              hint: 'e.g. Google, TCS, Govt of WB',
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Annual Income'),
            _buildDropdownField(
              value: _annualIncome,
              items: _incomeOptions,
              hint: 'Select annual income',
              onChanged: (val) => setState(() => _annualIncome = val),
            ),
          ],
        );

      case ProfileSection.location:
        final currentStates = _availableStates;
        final currentCities = _availableCities;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Country'),
            _buildDropdownField(
              value: _country,
              items: _countryOptions,
              hint: 'Select country',
              onChanged: (val) {
                setState(() {
                  _country = val;
                  _state = null; // Reset state when country changes
                  _city = null;  // Reset city when country changes
                  _cityTextController.clear();
                });
              },
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('State'),
            _buildDropdownField(
              value: _state,
              items: currentStates,
              hint: _country == null ? 'Select country first' : 'Select state',
              onChanged: _country == null ? null : (val) {
                setState(() {
                  _state = val;
                  _city = null; // Reset city when state changes
                  _cityTextController.clear();
                });
              },
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('City'),
            if (currentCities.isNotEmpty)
              _buildDropdownField(
                value: _city,
                items: currentCities,
                hint: _state == null ? 'Select state first' : 'Select city',
                onChanged: _state == null ? null : (val) {
                  setState(() {
                    _city = val;
                    if (val != null) _cityTextController.text = val;
                  });
                },
              )
            else
              // Fallback to text input if no cities list in DB for this state yet
              _buildTextField(
                controller: _cityTextController,
                hint: _state == null ? 'Select state first' : 'Enter city name',
              ),
            const SizedBox(height: 14),
            _buildFieldLabel('Residency Status'),
            _buildDropdownField(
              value: _residencyStatus,
              items: _residencyTypes,
              hint: 'Select residency status',
              onChanged: (val) => setState(() => _residencyStatus = val),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Pincode / Zip Code'),
            _buildTextField(
              controller: _pincodeController,
              hint: 'e.g. 700001',
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Police Station'),
            _buildTextField(
              controller: _policeStController,
              hint: 'e.g. Park Street Police Station',
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Full Residential Address'),
            _buildTextField(
              controller: _fullAddressController,
              hint: 'House / Street / Area...',
              maxLines: 2,
            ),
          ],
        );

      case ProfileSection.family:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel("Father's Profession"),
            _buildTextField(
              controller: _fatherProfessionController,
              hint: 'e.g. Retired Govt Employee, Businessman',
            ),
            const SizedBox(height: 14),
            _buildFieldLabel("Mother's Profession"),
            _buildTextField(
              controller: _motherProfessionController,
              hint: 'e.g. Homemaker, Teacher, Doctor',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Brothers Count'),
                      _buildCounterField(
                        value: _brothersCount,
                        onChanged: (v) => setState(() => _brothersCount = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Sisters Count'),
                      _buildCounterField(
                        value: _sistersCount,
                        onChanged: (v) => setState(() => _sistersCount = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Family Location'),
            _buildTextField(
              controller: _familyLocationController,
              hint: 'e.g. Kolkata, West Bengal',
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Financial Status'),
            _buildDropdownField(
              value: _familyFinancialStatus,
              items: _financialStatuses,
              hint: 'Select financial status',
              onChanged: (val) => setState(() => _familyFinancialStatus = val),
            ),
          ],
        );

      case ProfileSection.contact:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Contact Privacy Display Option'),
            _buildDropdownField(
              value: _contactDisplayOption,
              items: _contactDisplayOptions,
              hint: 'Select privacy option',
              onChanged: (val) => setState(() => _contactDisplayOption = val),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Full Residential Address'),
            _buildTextField(
              controller: _fullAddressController,
              hint: 'House / Street / Area...',
              maxLines: 2,
            ),
          ],
        );
    }
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3A3A3A),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int minLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFE8DE)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: minLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        buildCounter: maxLength != null ? (_, {required currentLength, required isFocused, maxLength}) => null : null,
        style: GoogleFonts.outfit(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E1E1E),
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintText: hint,
          hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF9E9E9E)),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF750000), width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?>? onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: onChanged == null ? const Color(0xFFF5F0E8) : const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFE8DE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          isExpanded: true,
          hint: Text(
            hint,
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF9E9E9E)),
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(
            CupertinoIcons.chevron_down,
            size: 16,
            color: onChanged == null ? Colors.grey : const Color(0xFF750000),
          ),
          items: items.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(
                opt,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E1E1E),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCounterField({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFE8DE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.minus_circle, color: Color(0xFF750000), size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
          ),
          Text(
            '$value',
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle, color: Color(0xFF750000), size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: value < 10 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
