import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_matrimonial_loader.dart';

/// Screen: Candidate Profile Edit Screen
/// Aligned 100% with DB master models & website profile edit structure
/// (Dependent dropdowns for Country->State->City, Religion->Community, DB Qualifications, Incomes, etc. Weight field removed)
class RaniProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic>? initialCandidate;

  const RaniProfileEditScreen({
    super.key,
    this.initialCandidate,
  });

  @override
  State<RaniProfileEditScreen> createState() => _RaniProfileEditScreenState();
}

class _RaniProfileEditScreenState extends State<RaniProfileEditScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // ==========================================
  // Master Lists (Seeded defaults & updated via ApiService.getRegistrationOptions)
  // ==========================================
  List<String> _countryOptions = ['India', 'Bangladesh', 'United States', 'United Kingdom', 'Canada', 'Australia', 'United Arab Emirates'];
  Map<String, List<String>> _countryToStates = {
    'India': [
      'West Bengal', 'Maharashtra', 'Delhi', 'Karnataka', 'Tamil Nadu',
      'Uttar Pradesh', 'Gujarat', 'Telangana', 'Kerala', 'Rajasthan',
      'Punjab', 'Haryana', 'Bihar', 'Odisha', 'Assam', 'Madhya Pradesh',
      'Jharkhand', 'Andhra Pradesh',
    ],
  };

  Map<String, Map<String, List<String>>> _countryStateToCities = {
    'India': {
      'West Bengal': [
        'Kolkata', 'Howrah', 'Siliguri', 'Durgapur', 'Asansol',
        'Bardhaman', 'Kharagpur', 'Malda', 'Berhampore', 'Habra',
      ],
      'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik'],
      'Delhi': ['New Delhi', 'North Delhi', 'South Delhi', 'East Delhi', 'West Delhi'],
      'Karnataka': ['Bengaluru', 'Mysuru', 'Hubballi', 'Mangaluru', 'Belagavi'],
    },
  };

  List<String> _religionOptions = [
    'Hindu', 'Muslim', 'Christian', 'Sikh', 'Jain', 'Buddhist', 'Parsi', 'Jewish', 'Other',
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

  List<String> _dietOptions = ['Vegetarian', 'Non-Vegetarian', 'Eggetarian', 'Jain', 'Vegan'];
  final List<String> _genders = ['Male', 'Female'];
  final List<String> _motherTongues = ['Bengali', 'Hindi', 'English', 'Urdu', 'Odia', 'Assamese', 'Telugu', 'Tamil', 'Marathi', 'Gujarati', 'Punjabi', 'Malayalam', 'Kannada'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _manglikOptions = ['No', 'Yes', 'Partial / Anshik Manglik', 'Don\'t Know'];
  final List<String> _financialStatuses = ['Middle Class', 'Upper Middle Class', 'Rich / Affluent'];
  final List<String> _familyTypes = ['Nuclear Family', 'Joint Family'];
  final List<String> _residencyTypes = ['Citizen', 'Permanent Resident', 'Work Visa', 'Student Visa', 'Temporary'];

  // Form Controllers & State Values
  // 1. Basic Details
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String _gender = 'Female';
  String? _maritalStatus;
  String? _height;

  // 2. Religious & Cultural Background
  String? _religion;
  String? _community;
  final TextEditingController _subCommunityController = TextEditingController();
  String? _motherTongue;
  final TextEditingController _gothraController = TextEditingController();

  // 3. About Myself
  final TextEditingController _aboutMeController = TextEditingController();

  // 4. Education & Career
  String? _highestQualification;
  final TextEditingController _collegeNameController = TextEditingController();
  String? _workingWith;
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  String? _annualIncome;

  // 5. Location Details (Country -> State -> City dependent dropdowns)
  String? _country;
  String? _state;
  String? _city;
  final TextEditingController _cityTextController = TextEditingController();
  String? _residencyStatus;
  final TextEditingController _fullAddressController = TextEditingController();
  final TextEditingController _policeStController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  // 6. Family Details
  final TextEditingController _fatherProfessionController = TextEditingController();
  final TextEditingController _motherProfessionController = TextEditingController();
  final TextEditingController _familyLocationController = TextEditingController();
  int _brothersCount = 0;
  int _sistersCount = 0;
  String? _familyFinancialStatus;
  String? _familyType;

  // 7. Horoscope & Astro Details
  String? _manglik;
  final TextEditingController _timeOfBirthController = TextEditingController();
  final TextEditingController _cityOfBirthController = TextEditingController();

  // 8. Lifestyle & Health (No Weight field)
  String? _diet;
  String? _bloodGroup;
  final TextEditingController _healthInfoController = TextEditingController();
  final TextEditingController _grewUpInController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _cityTextController.addListener(() {
      _city = _cityTextController.text.trim();
    });
    _initData();
  }

  Future<void> _initData() async {
    final candidate = widget.initialCandidate ?? ApiService.instance.candidate;
    if (candidate != null) {
      _populateFromMap(candidate);
      setState(() => _isLoading = false);
    }

    await _loadMasterOptionsFromDb();

    try {
      final res = await ApiService.instance.getMyProfile();
      if (mounted && res['success'] == true && res['candidate'] != null) {
        _populateFromMap(res['candidate'] as Map<String, dynamic>);
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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

        // 7. Heights
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

        // 8. Diets
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

        // Resync candidate's existing data into options
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
    if (_highestQualification != null && !_qualificationOptions.contains(_highestQualification)) {
      _qualificationOptions.insert(0, _highestQualification!);
    }
  }

  String? _findMatch(List<String> items, dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty || str == '-' || str == 'null') return null;
    final exact = items.firstWhere(
      (it) => it.toLowerCase() == str.toLowerCase(),
      orElse: () => '',
    );
    if (exact.isNotEmpty) return exact;
    return str;
  }

  String? _findIncomeMatch(List<String> list, dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim();
    if (str.isEmpty || str == '-' || str == 'null') return null;

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

  void _populateFromMap(Map<String, dynamic> c) {
    _firstNameController.text = c['first_name']?.toString() ?? '';
    _lastNameController.text = c['last_name']?.toString() ?? '';
    _dobController.text = c['dob']?.toString() ?? '';

    final g = c['gender']?.toString();
    if (g != null && _genders.any((x) => x.toLowerCase() == g.toLowerCase())) {
      _gender = _genders.firstWhere((x) => x.toLowerCase() == g.toLowerCase());
    }

    _maritalStatus = _findMatch(_maritalStatusOptions, c['marital_status']);
    _religion = _findMatch(_religionOptions, c['religion']);

    final initialComms = _availableCommunities;
    _community = _findMatch(initialComms, c['community']) ?? c['community']?.toString().trim();
    if (_community != null && _community!.isNotEmpty && !initialComms.contains(_community)) {
      if (_religion != null) {
        _religionToCommunities[_religion!] ??= [];
        _religionToCommunities[_religion!]!.insert(0, _community!);
      }
    }

    _subCommunityController.text = c['sub_community']?.toString() ?? '';
    _motherTongue = _findMatch(_motherTongues, c['mother_tongue']);
    _height = _findMatch(_heightOptions, c['height']);
    _aboutMeController.text = c['about_yourself']?.toString() ?? '';

    // Education & Career
    _highestQualification = _findMatch(_qualificationOptions, c['highest_qualification']) ?? c['highest_qualification']?.toString().trim();
    if (_highestQualification != null && _highestQualification!.isNotEmpty && !_qualificationOptions.contains(_highestQualification)) {
      _qualificationOptions.insert(0, _highestQualification!);
    }
    _collegeNameController.text = c['college_name']?.toString() ?? '';
    _workingWith = _findMatch(_workingSectorOptions, c['working_with']);
    _professionController.text = c['profession']?.toString() ?? '';
    _designationController.text = c['designation']?.toString() ?? '';
    _companyNameController.text = c['company_name']?.toString() ?? '';
    final rawIncome = c['annual_income']?.toString().trim();
    _annualIncome = _findIncomeMatch(_incomeOptions, rawIncome) ??
        (rawIncome != null && rawIncome.isNotEmpty && rawIncome != '-' ? rawIncome : null);
    if (_annualIncome != null && !_incomeOptions.contains(_annualIncome)) {
      _incomeOptions.insert(0, _annualIncome!);
    }

    // Family
    _fatherProfessionController.text = c['father_profession']?.toString() ?? '';
    _motherProfessionController.text = c['mother_profession']?.toString() ?? '';
    _familyLocationController.text = c['family_location']?.toString() ?? '';
    _brothersCount = int.tryParse(c['brothers_count']?.toString() ?? '0') ?? 0;
    _sistersCount = int.tryParse(c['sisters_count']?.toString() ?? '0') ?? 0;
    _familyFinancialStatus = _findMatch(_financialStatuses, c['family_financial_status']);
    _familyType = _findMatch(_familyTypes, c['family_type']);

    // Astro
    _manglik = _findMatch(_manglikOptions, c['manglik']);
    _gothraController.text = c['gothra']?.toString() ?? '';
    _timeOfBirthController.text = c['time_of_birth']?.toString() ?? '';
    _cityOfBirthController.text = c['city_of_birth']?.toString() ?? '';

    // Lifestyle & Health (No Weight field)
    _diet = _findMatch(_dietOptions, c['diet']);
    _bloodGroup = _findMatch(_bloodGroups, c['blood_group']);
    _healthInfoController.text = c['health_info']?.toString() ?? '';
    _grewUpInController.text = c['grew_up_in']?.toString() ?? '';

    // Location
    _country = _findMatch(_countryOptions, c['country']) ?? 'India';
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
    _cityTextController.text = _city ?? '';

    _fullAddressController.text = c['full_address']?.toString() ?? '';
    _policeStController.text = c['police_st']?.toString() ?? '';
    _pincodeController.text = c['pincode']?.toString() ?? c['zip_code']?.toString() ?? '';
    _residencyStatus = _findMatch(_residencyTypes, c['residency_status']) ?? 'Citizen';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _subCommunityController.dispose();
    _aboutMeController.dispose();
    _fatherProfessionController.dispose();
    _motherProfessionController.dispose();
    _familyLocationController.dispose();
    _gothraController.dispose();
    _timeOfBirthController.dispose();
    _cityOfBirthController.dispose();
    _healthInfoController.dispose();
    _grewUpInController.dispose();
    _collegeNameController.dispose();
    _professionController.dispose();
    _designationController.dispose();
    _companyNameController.dispose();
    _cityTextController.dispose();
    _fullAddressController.dispose();
    _policeStController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final fn = _firstNameController.text.trim();
    if (fn.isEmpty) {
      RaniAlert.warning(context, 'Please enter your first name.');
      return;
    }

    setState(() => _isSaving = true);
    RaniMatrimonialLoader.show(context, message: 'Saving profile updates...');

    final sectionsToUpdate = <String, Map<String, dynamic>>{
      'basic': {
        'first_name': fn,
        'last_name': _lastNameController.text.trim(),
        'dob': _dobController.text.trim(),
        'gender': _gender,
        if (_maritalStatus != null) 'marital_status': _maritalStatus,
        if (_height != null) 'height': _height,
        if (_diet != null) 'diet': _diet,
        if (_bloodGroup != null) 'blood_group': _bloodGroup,
        'health_info': _healthInfoController.text.trim(),
        'grew_up_in': _grewUpInController.text.trim(),
      },
      'religious': {
        if (_religion != null) 'religion': _religion,
        if (_community != null) 'community': _community,
        'sub_community': _subCommunityController.text.trim(),
        if (_motherTongue != null) 'mother_tongue': _motherTongue,
        'gothra': _gothraController.text.trim(),
      },
      'about': {
        'about_yourself': _aboutMeController.text.trim(),
      },
      'education_career': {
        if (_highestQualification != null) 'highest_qualification': _highestQualification,
        'college_name': _collegeNameController.text.trim(),
        if (_workingWith != null) 'working_with': _workingWith,
        'profession': _professionController.text.trim(),
        'designation': _designationController.text.trim(),
        'company_name': _companyNameController.text.trim(),
        if (_annualIncome != null) 'annual_income': _annualIncome,
      },
      'location': {
        if (_country != null) 'country': _country,
        if (_state != null) 'state': _state,
        if (_city != null) 'city': _city,
        'full_address': _fullAddressController.text.trim(),
        'police_st': _policeStController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        if (_residencyStatus != null) 'residency_status': _residencyStatus,
      },
      'family': {
        'father_profession': _fatherProfessionController.text.trim(),
        'mother_profession': _motherProfessionController.text.trim(),
        'family_location': _familyLocationController.text.trim(),
        'brothers_count': _brothersCount,
        'sisters_count': _sistersCount,
        if (_familyFinancialStatus != null) 'family_financial_status': _familyFinancialStatus,
        if (_familyType != null) 'family_type': _familyType,
      },
      'astro': {
        if (_manglik != null) 'manglik': _manglik,
        'time_of_birth': _timeOfBirthController.text.trim(),
        'city_of_birth': _cityOfBirthController.text.trim(),
      },
    };

    try {
      bool anySuccess = false;
      String? firstError;

      final results = await Future.wait(
        sectionsToUpdate.entries.map((e) => ApiService.instance.updateProfile(e.key, e.value)),
      );

      for (final res in results) {
        if (res['success'] == true) {
          anySuccess = true;
        } else if (firstError == null && res['message'] != null) {
          firstError = res['message'].toString();
        }
      }

      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      setState(() => _isSaving = false);

      if (mounted) {
        if (anySuccess) {
          RaniAlert.success(context, 'Profile updated successfully!');
          Navigator.pop(context, true);
        } else {
          RaniAlert.error(context, firstError ?? 'Failed to update profile.');
        }
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      setState(() => _isSaving = false);
      RaniAlert.error(context, 'Error updating profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStates = _availableStates;
    final currentCities = _availableCities;
    final currentCommunities = _availableCommunities;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF750000)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              'Save',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF750000),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF750000)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                // 1. Basic Information
                _buildCardSection(
                  title: 'Basic Information',
                  icon: CupertinoIcons.person_crop_circle_fill,
                  children: [
                    _buildTextField(label: 'First Name', controller: _firstNameController, isRequired: true),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Last Name', controller: _lastNameController),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Date of Birth (YYYY-MM-DD)',
                      controller: _dobController,
                      hint: '1998-05-15',
                      keyboardType: TextInputType.datetime,
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Gender',
                      value: _gender,
                      items: _genders,
                      onChanged: (v) => setState(() => _gender = v ?? 'Female'),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Marital Status',
                      value: _maritalStatus,
                      items: _maritalStatusOptions,
                      hint: 'Select marital status',
                      onChanged: (v) => setState(() => _maritalStatus = v),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Height',
                      value: _height,
                      items: _heightOptions,
                      hint: 'Select height',
                      onChanged: (v) => setState(() => _height = v),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Religious & Cultural Background (Dependent Dropdown)
                _buildCardSection(
                  title: 'Religious & Cultural Background',
                  icon: CupertinoIcons.book_fill,
                  children: [
                    _buildDropdown(
                      label: 'Religion',
                      value: _religion,
                      items: _religionOptions,
                      hint: 'Select religion',
                      onChanged: (v) {
                        setState(() {
                          _religion = v;
                          _community = null; // Reset community when religion changes
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Community (Caste)',
                      value: _community,
                      items: currentCommunities,
                      hint: _religion == null ? 'Select religion first' : 'Select community',
                      onChanged: _religion == null ? null : (v) => setState(() => _community = v),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Sub-Community',
                      controller: _subCommunityController,
                      hint: 'e.g. Kulin, Rarhi, etc.',
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Mother Tongue',
                      value: _motherTongue,
                      items: _motherTongues,
                      hint: 'Select mother tongue',
                      onChanged: (v) => setState(() => _motherTongue = v),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Gothra', controller: _gothraController, hint: 'e.g. Sandilya, Kashyap, etc.'),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. About Myself
                _buildCardSection(
                  title: 'About Myself',
                  icon: CupertinoIcons.doc_text_fill,
                  children: [
                    _buildTextField(
                      label: 'Express yourself in a few words',
                      controller: _aboutMeController,
                      maxLines: 4,
                      hint: 'Describe your personality, passions, family background and partner expectations...',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 4. Education & Career (Dropdowns from DB)
                _buildCardSection(
                  title: 'Education & Career',
                  icon: CupertinoIcons.briefcase_fill,
                  children: [
                    _buildDropdown(
                      label: 'Highest Qualification',
                      value: _highestQualification,
                      items: _qualificationOptions,
                      hint: 'Select qualification',
                      onChanged: (v) => setState(() => _highestQualification = v),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'College / Institute Name', controller: _collegeNameController),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Working Sector',
                      value: _workingWith,
                      items: _workingSectorOptions,
                      hint: 'Select working sector',
                      onChanged: (v) => setState(() => _workingWith = v),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Profession', controller: _professionController, hint: 'Software Engineer, Doctor, etc.'),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Designation / Role', controller: _designationController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Company Name', controller: _companyNameController),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Annual Income',
                      value: _annualIncome,
                      items: _incomeOptions,
                      hint: 'Select annual income',
                      onChanged: (v) => setState(() => _annualIncome = v),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 5. Location & Address (Dependent Dropdowns: Country -> State -> City)
                _buildCardSection(
                  title: 'Location & Address',
                  icon: CupertinoIcons.location_solid,
                  children: [
                    _buildDropdown(
                      label: 'Country',
                      value: _country,
                      items: _countryOptions,
                      hint: 'Select country',
                      onChanged: (v) {
                        setState(() {
                          _country = v;
                          _state = null;
                          _city = null;
                          _cityTextController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'State',
                      value: _state,
                      items: currentStates,
                      hint: _country == null ? 'Select country first' : 'Select state',
                      onChanged: _country == null
                          ? null
                          : (v) {
                              setState(() {
                                _state = v;
                                _city = null;
                                _cityTextController.clear();
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    if (currentCities.isNotEmpty)
                      _buildDropdown(
                        label: 'City',
                        value: _city,
                        items: currentCities,
                        hint: _state == null ? 'Select state first' : 'Select city',
                        onChanged: _state == null
                            ? null
                            : (v) {
                                setState(() {
                                  _city = v;
                                  if (v != null) _cityTextController.text = v;
                                });
                              },
                      )
                    else
                      _buildTextField(
                        label: 'City',
                        controller: _cityTextController,
                        hint: _state == null ? 'Select state first' : 'Enter city name',
                      ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Residency Status',
                      value: _residencyStatus,
                      items: _residencyTypes,
                      hint: 'Select residency status',
                      onChanged: (v) => setState(() => _residencyStatus = v),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Pincode / Zip Code', controller: _pincodeController, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Police Station', controller: _policeStController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Full Residential Address', controller: _fullAddressController, maxLines: 2),
                  ],
                ),

                const SizedBox(height: 16),

                // 6. Family Background
                _buildCardSection(
                  title: 'Family Background',
                  icon: CupertinoIcons.person_3_fill,
                  children: [
                    _buildTextField(label: 'Father\'s Profession', controller: _fatherProfessionController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Mother\'s Profession', controller: _motherProfessionController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Family Location / City', controller: _familyLocationController),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberCounter(
                            label: 'Brothers',
                            value: _brothersCount,
                            onChanged: (v) => setState(() => _brothersCount = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberCounter(
                            label: 'Sisters',
                            value: _sistersCount,
                            onChanged: (v) => setState(() => _sistersCount = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Financial Status',
                      value: _familyFinancialStatus,
                      items: _financialStatuses,
                      hint: 'Select financial status',
                      onChanged: (v) => setState(() => _familyFinancialStatus = v),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Family Type',
                      value: _familyType,
                      items: _familyTypes,
                      hint: 'Select family type',
                      onChanged: (v) => setState(() => _familyType = v),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 7. Horoscope & Astro Details
                _buildCardSection(
                  title: 'Horoscope & Astro Details',
                  icon: CupertinoIcons.sparkles,
                  children: [
                    _buildDropdown(
                      label: 'Manglik Status',
                      value: _manglik,
                      items: _manglikOptions,
                      hint: 'Select manglik status',
                      onChanged: (v) => setState(() => _manglik = v),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Time of Birth', controller: _timeOfBirthController, hint: '10:30 AM'),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'City of Birth', controller: _cityOfBirthController),
                  ],
                ),

                const SizedBox(height: 16),

                // 8. Lifestyle & Health (Weight removed per DB structure)
                _buildCardSection(
                  title: 'Lifestyle & Health',
                  icon: CupertinoIcons.heart_fill,
                  children: [
                    _buildDropdown(
                      label: 'Diet Preference',
                      value: _diet,
                      items: _dietOptions,
                      hint: 'Select diet',
                      onChanged: (v) => setState(() => _diet = v),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Blood Group',
                      value: _bloodGroup,
                      items: _bloodGroups,
                      hint: 'Select blood group',
                      onChanged: (v) => setState(() => _bloodGroup = v),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Health Info',
                      controller: _healthInfoController,
                      hint: 'Normal / Any health conditions',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Grew Up In', controller: _grewUpInController, hint: 'Kolkata, Mumbai, etc.'),
                  ],
                ),

                const SizedBox(height: 24),

                // Bottom Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF750000),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSaving ? null : _saveProfile,
                    child: Text(
                      'Save All Changes',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF750000)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A4A4A),
              ),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF1E1E1E)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: Colors.grey.shade400),
            filled: true,
            fillColor: const Color(0xFFFAF7F2),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE8DFD5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE8DFD5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF750000), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    String hint = 'Select',
    required ValueChanged<String?>? onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: onChanged == null ? const Color(0xFFF5F0E8) : const Color(0xFFFAF7F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8DFD5)),
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
              style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF1E1E1E)),
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberCounter({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8DFD5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: value > 0 ? () => onChanged(value - 1) : null,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: value > 0 ? const Color(0xFF750000).withValues(alpha: 0.1) : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.remove, size: 14, color: value > 0 ? const Color(0xFF750000) : Colors.grey),
                ),
              ),
              Text(
                '$value',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              InkWell(
                onTap: () => onChanged(value + 1),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF750000).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 14, color: Color(0xFF750000)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
