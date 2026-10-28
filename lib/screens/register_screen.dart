import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'main_navigation_screen.dart';
import '../services/api_service.dart';
import '../components/rani_alert.dart';
import '../components/rani_matrimonial_loader.dart';

/// Screen: Complete 14-Step Registration Screen for Rani Matrimonial
/// Pixel-perfect matching with all 14 design screenshots:
/// - Step 1: This Profile is for (Pills selection)
/// - Step 2: Select Gender (Groom & Bride photo cards with radio check)
/// - Step 3: Personal Details (First Name, Middle Name, Last Name, Aadhar Number)
/// - Step 4: Date of Birth (DD / MM / YYYY boxes with auto-focus)
/// - Step 5: Religion & Community (Religion, Community, Sub Community)
/// - Step 6: Contact Information (Email ID, Mobile Number with +91 badge)
/// - Step 7: Location (Country, State, City, Police Station, Pincode, Full Address)
/// - Step 8: Physical & Diet (Marital Status, Height, Diet - Milestone 8)
/// - Step 9: Education (Highest Qualification, College Name, College Address)
/// - Step 10: Income Details (Annual Income)
/// - Step 11: Career Details (Working Sector, Profession, Designation, Company, Address)
/// - Step 12: Express Yourself (Bio text area, Hobbies & Interests - Milestone 12)
/// - Step 13: Verify Mobile Number (WhatsApp OTP verification with 4-digit boxes)
/// - Step 14: Profile Picture (Upload Picture, Live Selfie, Link Phone, Referral Code, Complete Registration - Milestone 14)
class RaniRegisterScreen extends StatefulWidget {
  const RaniRegisterScreen({super.key});

  @override
  State<RaniRegisterScreen> createState() => _RaniRegisterScreenState();
}

class _RaniRegisterScreenState extends State<RaniRegisterScreen> {
  int _currentStep = 1;
  final int _totalSteps = 14;

  // Step 1: Profile For
  String _profileFor = 'Myself';

  // Step 2: Gender
  String? _selectedGender; // 'Groom' or 'Bride'

  // Step 3: Personal Details
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();

  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _middleNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _aadharFocus = FocusNode();

  // Step 4: DOB
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  final FocusNode _dayFocus = FocusNode();
  final FocusNode _monthFocus = FocusNode();
  final FocusNode _yearFocus = FocusNode();

  // Step 5: Religion & Community
  String? _selectedReligion;
  String? _selectedCommunity;
  final TextEditingController _subCommunityController = TextEditingController();
  final FocusNode _subCommunityFocus = FocusNode();

  // Step 6: Contact Information
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _mobileFocus = FocusNode();

  // Step 7: Location
  String? _selectedCountry = 'India';
  String? _selectedState = 'West Bengal';
  String? _selectedCity;
  final TextEditingController _countryController = TextEditingController(text: 'India');
  final TextEditingController _stateController = TextEditingController(text: 'West Bengal');
  final TextEditingController _policeStationController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _fullAddressController = TextEditingController();

  final FocusNode _countryFocus = FocusNode();
  final FocusNode _stateFocus = FocusNode();
  final FocusNode _policeStationFocus = FocusNode();
  final FocusNode _pincodeFocus = FocusNode();
  final FocusNode _fullAddressFocus = FocusNode();

  // Step 8: Physical & Diet
  String? _selectedMaritalStatus;
  String? _selectedHeight;
  String? _selectedDiet;

  // Step 9: Education
  String? _selectedQualification;
  final TextEditingController _collegeNameController = TextEditingController();
  final TextEditingController _collegeAddressController = TextEditingController();

  final FocusNode _collegeNameFocus = FocusNode();
  final FocusNode _collegeAddressFocus = FocusNode();

  // Step 10: Income Details
  String? _selectedIncome;

  // Step 11: Career Details
  String? _selectedWorkingSector;
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyAddressController = TextEditingController();

  final FocusNode _professionFocus = FocusNode();
  final FocusNode _designationFocus = FocusNode();
  final FocusNode _companyNameFocus = FocusNode();
  final FocusNode _companyAddressFocus = FocusNode();

  // Step 12: Express Yourself
  final TextEditingController _aboutMeController = TextEditingController();
  final FocusNode _aboutMeFocus = FocusNode();
  final Set<String> _selectedHobbies = {
    'Traveling & Exploring',
    'Music & Playing Instruments',
    'Singing',
    'Movies & OTT Series',
  };

  // Step 13: OTP Verification
  final TextEditingController _otp1Controller = TextEditingController();
  final TextEditingController _otp2Controller = TextEditingController();
  final TextEditingController _otp3Controller = TextEditingController();
  final TextEditingController _otp4Controller = TextEditingController();

  final FocusNode _otp1Focus = FocusNode();
  final FocusNode _otp2Focus = FocusNode();
  final FocusNode _otp3Focus = FocusNode();
  final FocusNode _otp4Focus = FocusNode();

  Timer? _countdownTimer;
  int _resendSeconds = 22;
  bool _isSubmitting = false;

  // Step 14: Profile Picture, Selfie & Referral
  File? _profilePictureFile;
  File? _selfieFile;
  String? _selfieData;
  Timer? _selfiePollTimer;
  final TextEditingController _referralCodeController = TextEditingController();
  final FocusNode _referralCodeFocus = FocusNode();

  // Dropdown Lists
  final List<String> _profileForOptions = const [
    'Myself',
    'My Son',
    'My Daughter',
    'My Brother',
    'My Sister',
    'My Friend',
  ];

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
    'Hindu': [
      'Brahmin', 'Kshatriya', 'Rajput', 'Maratha', 'Agarwal', 'Kayastha', 'Baidya',
      'Khatri', 'Arora', 'Yadav', 'Gujjar', 'Lingayat', 'Reddy', 'Nair', 'Ezhava',
      'Bania', 'Jat', 'Patel', 'Patel - Leva', 'Patel - Kadva', 'Thevar', 'Mudaliar',
      'Sindhi', 'Maheshwari', 'Kamma', 'Kapu', 'Vokkaliga', 'Nadar', 'SC', 'ST', 'Other',
    ],
    'Muslim': [
      'Sunni', 'Shia', 'Hanafi', 'Shafi', 'Maliki', 'Hanbali', 'Dawoodi Bohra',
      'Ismaili', 'Sufi', 'Ansari', 'Qureshi', 'Sheikh', 'Syed', 'Pathan', 'Mughal', 'Other',
    ],
    'Christian': [
      'Roman Catholic', 'Protestant', 'Latin Catholic', 'Syrian Catholic',
      'Pentecostal', 'Baptist', 'Mar Thoma', 'Orthodox', 'Anglican', 'Methodist', 'Other',
    ],
    'Sikh': [
      'Jat', 'Khatri', 'Arora', 'Ramgarhia', 'Ahluwalia', 'Saini', 'Kamboj', 'Mazhabi', 'Bhatia', 'Other',
    ],
    'Jain': [
      'Digambar', 'Shwetambar', 'Agarwal', 'Oswal', 'Khandelwal', 'Porwal', 'Other',
    ],
    'Buddhist': [
      'Theravada', 'Mahayana', 'Navayana / Neo-Buddhist', 'Tibetan', 'Other',
    ],
    'Parsi': [
      'Irani', 'Parsi', 'Other',
    ],
    'Jewish': [
      'Bene Israel', 'Baghdadi', 'Cochin', 'Other',
    ],
    'Other': [
      'Other',
    ],
  };

  List<String> get _currentCommunityOptions {
    if (_selectedReligion == null) return const [];
    return _religionToCommunities[_selectedReligion] ?? const ['Other'];
  }

  // Location Hierarchy from DB
  List<String> _countryOptions = const [
    'India',
    'United States',
    'United Kingdom',
    'Canada',
    'United Arab Emirates',
    'Australia',
  ];

  Map<String, List<String>> _countryToStates = {
    'India': const [
      'West Bengal',
      'Maharashtra',
      'Delhi',
      'Karnataka',
      'Tamil Nadu',
      'Uttar Pradesh',
      'Gujarat',
      'Rajasthan',
      'Kerala',
      'Punjab',
      'Haryana',
      'Madhya Pradesh',
      'Bihar',
      'Odisha',
      'Assam',
      'Jharkhand',
      'Uttarakhand',
      'Goa',
      'Himachal Pradesh',
      'Jammu and Kashmir',
      'Chandigarh',
      'Telangana',
      'Andhra Pradesh',
    ],
  };

  Map<String, Map<String, List<String>>> _countryStateToCities = {
    'India': {
      'West Bengal': const [
        'Kolkata',
        'Howrah',
        'Siliguri',
        'Durgapur',
        'Asansol',
        'Bardhaman',
        'Kharagpur',
      ],
    },
  };

  List<String> get _currentStateOptions {
    if (_selectedCountry == null) return const [];
    return _countryToStates[_selectedCountry] ?? const [];
  }

  List<String> get _currentCityOptions {
    if (_selectedCountry == null || _selectedState == null) return const [];
    return _countryStateToCities[_selectedCountry]?[_selectedState] ?? const [];
  }

  List<String> _maritalStatusOptions = const [
    'Never Married',
    'Divorced',
    'Widowed',
    'Awaiting Divorce',
    'Annulled',
  ];

  List<String> _heightOptions = const [
    r"""4' 0" (121 cm)""", 
    r"""4' 1" (124 cm)""", 
    r"""4' 2" (127 cm)""", 
    r"""4' 3" (129 cm)""", 
    r"""4' 4" (132 cm)""", 
    r"""4' 5" (134 cm)""", 
    r"""4' 6" (137 cm)""", 
    r"""4' 7" (139 cm)""", 
    r"""4' 8" (142 cm)""", 
    r"""4' 9" (144 cm)""", 
    r"""4' 10" (147 cm)""", 
    r"""4' 11" (149 cm)""", 
    r"""5' 0" (152 cm)""", 
    r"""5' 1" (154 cm)""", 
    r"""5' 2" (157 cm)""", 
    r"""5' 3" (160 cm)""", 
    r"""5' 4" (162 cm)""", 
    r"""5' 5" (165 cm)""", 
    r"""5' 6" (167 cm)""", 
    r"""5' 7" (170 cm)""", 
    r"""5' 8" (172 cm)""", 
    r"""5' 9" (175 cm)""", 
    r"""5' 10" (177 cm)""", 
    r"""5' 11" (180 cm)""", 
    r"""6' 0" (182 cm)""", 
    r"""6' 1" (185 cm)""", 
    r"""6' 2" (187 cm)""", 
    r"""6' 3" (190 cm)""", 
    r"""6' 4" (193 cm)""", 
    r"""6' 5" (195 cm)""", 
    r"""6' 6" (198 cm)""", 
    r"""6' 7" (200 cm)""", 
    r"""6' 8" (203 cm)""", 
    r"""6' 9" (205 cm)""", 
    r"""6' 10" (208 cm)""", 
    r"""6' 11" (210 cm)""", 
    r"""7' 0" (213 cm)""", 
  ];

  List<String> _dietOptions = const [
    'Vegetarian',
    'Non-Vegetarian',
    'Eggetarian',
    'Vegan',
    'Jain',
  ];

  List<String> _qualificationOptions = const [
    'B.A. (Bachelor of Arts)',
    'B.Com. (Bachelor of Commerce)',
    'B.Pharm / M.Pharm',
    'B.Sc. (Bachelor of Science)',
    'B.Tech / B.E. (Engineering)',
    'BBA / BMS (Management)',
    'BCA / B.Sc. IT',
    'CA / CS / ICWA',
    'Diploma / Polytechnic',
    'High School (10th / 12th)',
    'LLB / LLM (Law)',
    'M.A. (Master of Arts)',
    'M.Com. (Master of Commerce)',
    'M.Sc. (Master of Science)',
    'M.Tech / M.E. (Engineering)',
    'MBA / PGDM (Management)',
    'MBBS / BDS (Medical)',
    'MCA / M.Sc. IT',
    'MD / MS (Medical)',
    'Other Professional Degree',
    'Ph.D. / Doctorate',
  ];

  List<String> _incomeOptions = const [
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

  List<String> _workingSectorOptions = const [
    'Private Company',
    'Government / Public Sector',
    'Defense / Civil Services',
    'Business / Self Employed',
    'Non Working',
  ];

  List<String> _allHobbies = const [
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

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_refreshState);
    _middleNameController.addListener(_refreshState);
    _lastNameController.addListener(_refreshState);
    _aadharController.addListener(_refreshState);
    _dayController.addListener(_refreshState);
    _monthController.addListener(_refreshState);
    _yearController.addListener(_refreshState);
    _subCommunityController.addListener(_refreshState);
    _emailController.addListener(_refreshState);
    _mobileController.addListener(_refreshState);
    _countryController.addListener(_refreshState);
    _stateController.addListener(_refreshState);
    _policeStationController.addListener(_refreshState);
    _pincodeController.addListener(_refreshState);
    _fullAddressController.addListener(_refreshState);
    _collegeNameController.addListener(_refreshState);
    _collegeAddressController.addListener(_refreshState);
    _professionController.addListener(_refreshState);
    _designationController.addListener(_refreshState);
    _companyNameController.addListener(_refreshState);
    _aboutMeController.addListener(_refreshState);
    _otp1Controller.addListener(_refreshState);
    _otp2Controller.addListener(_refreshState);
    _otp3Controller.addListener(_refreshState);
    _otp4Controller.addListener(_refreshState);
    _referralCodeController.addListener(_refreshState);

    _firstNameFocus.addListener(_refreshState);
    _middleNameFocus.addListener(_refreshState);
    _lastNameFocus.addListener(_refreshState);
    _aadharFocus.addListener(_refreshState);
    _dayFocus.addListener(_refreshState);
    _monthFocus.addListener(_refreshState);
    _yearFocus.addListener(_refreshState);
    _subCommunityFocus.addListener(_refreshState);
    _emailFocus.addListener(_refreshState);
    _mobileFocus.addListener(_refreshState);
    _countryFocus.addListener(_refreshState);
    _stateFocus.addListener(_refreshState);
    _policeStationFocus.addListener(_refreshState);
    _pincodeFocus.addListener(_refreshState);
    _fullAddressFocus.addListener(_refreshState);
    _collegeNameFocus.addListener(_refreshState);
    _collegeAddressFocus.addListener(_refreshState);
    _professionFocus.addListener(_refreshState);
    _designationFocus.addListener(_refreshState);
    _companyNameFocus.addListener(_refreshState);
    _companyAddressFocus.addListener(_refreshState);
    _aboutMeFocus.addListener(_refreshState);
    _otp1Focus.addListener(_refreshState);
    _otp2Focus.addListener(_refreshState);
    _otp3Focus.addListener(_refreshState);
    _otp4Focus.addListener(_refreshState);
    _referralCodeFocus.addListener(_refreshState);

    _fetchMasterDataFromDb();
  }

  Future<void> _fetchMasterDataFromDb() async {
    try {
      final res = await ApiService.instance.getRegistrationOptions();
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        if (data['religions'] != null && data['religions'] is List) {
          final List<String> loadedReligions = [];
          final Map<String, List<String>> loadedMap = {};

          for (var r in data['religions']) {
            final String rName = r['name']?.toString().trim() ?? '';
            if (rName.isNotEmpty) {
              loadedReligions.add(rName);
              final List<String> comms = [];
              if (r['communities'] != null && r['communities'] is List) {
                for (var c in r['communities']) {
                  final String cName = c['name']?.toString().trim() ?? '';
                  if (cName.isNotEmpty) {
                    comms.add(cName);
                  }
                }
              }
              if (!comms.contains('Other')) comms.add('Other');
              loadedMap[rName] = comms;
            }
          }

          if (mounted && loadedReligions.isNotEmpty) {
            setState(() {
              _religionOptions = loadedReligions;
              _religionToCommunities = loadedMap;
            });
          }
        }

        if (data['countries'] != null && data['countries'] is List) {
          final List<String> loadedCountries = [];
          final Map<String, List<String>> countryStatesMap = {};
          final Map<String, Map<String, List<String>>> countryStateCitiesMap = {};

          for (var c in data['countries']) {
            final String cName = c['name']?.toString().trim() ?? '';
            if (cName.isNotEmpty) {
              loadedCountries.add(cName);
              final List<String> statesList = [];
              final Map<String, List<String>> stateCitiesMap = {};

              if (c['states'] != null && c['states'] is List) {
                for (var s in c['states']) {
                  final String sName = s['name']?.toString().trim() ?? '';
                  if (sName.isNotEmpty) {
                    statesList.add(sName);
                    final List<String> citiesList = [];

                    if (s['cities'] != null && s['cities'] is List) {
                      for (var city in s['cities']) {
                        final String cityName = city['name']?.toString().trim() ?? '';
                        if (cityName.isNotEmpty) {
                          citiesList.add(cityName);
                        }
                      }
                    }
                    stateCitiesMap[sName] = citiesList;
                  }
                }
              }
              countryStatesMap[cName] = statesList;
              countryStateCitiesMap[cName] = stateCitiesMap;
            }
          }

          if (mounted && loadedCountries.isNotEmpty) {
            setState(() {
              _countryOptions = loadedCountries;
              _countryToStates = countryStatesMap;
              _countryStateToCities = countryStateCitiesMap;

              if (_selectedCountry == null || !_countryOptions.contains(_selectedCountry)) {
                _selectedCountry = _countryOptions.contains('India') ? 'India' : _countryOptions.first;
              }
              _countryController.text = _selectedCountry ?? '';

              final availableStates = _countryToStates[_selectedCountry] ?? [];
              if (_selectedState == null || !availableStates.contains(_selectedState)) {
                _selectedState = availableStates.contains('West Bengal')
                    ? 'West Bengal'
                    : (availableStates.isNotEmpty ? availableStates.first : null);
              }
              _stateController.text = _selectedState ?? '';

              final availableCities = _countryStateToCities[_selectedCountry]?[_selectedState] ?? [];
              if (_selectedCity == null || !availableCities.contains(_selectedCity)) {
                _selectedCity = availableCities.contains('Kolkata')
                    ? 'Kolkata'
                    : (availableCities.isNotEmpty ? availableCities.first : null);
              }
            });
          }
        }

        // Marital Statuses from DB
        if (data['marital_statuses'] != null && data['marital_statuses'] is List) {
          final List<String> loaded = [];
          for (var item in data['marital_statuses']) {
            final name = item['name']?.toString().trim() ?? '';
            if (name.isNotEmpty) loaded.add(name);
          }
          if (mounted && loaded.isNotEmpty) {
            setState(() => _maritalStatusOptions = loaded);
          }
        }

        // Heights from DB
        if (data['heights'] != null && data['heights'] is List) {
          final List<String> loaded = [];
          for (var item in data['heights']) {
            final name = item['name']?.toString().trim() ?? '';
            if (name.isNotEmpty) loaded.add(name);
          }
          if (mounted && loaded.isNotEmpty) {
            setState(() => _heightOptions = loaded);
          }
        }

        // Diets from DB
        if (data['diets'] != null && data['diets'] is List) {
          final List<String> loaded = [];
          for (var item in data['diets']) {
            final name = item['name']?.toString().trim() ?? '';
            if (name.isNotEmpty) loaded.add(name);
          }
          if (mounted && loaded.isNotEmpty) {
            setState(() => _dietOptions = loaded);
          }
        }

        // Qualifications from DB
        if (data['qualifications'] != null && data['qualifications'] is List) {
          final List<String> loaded = [];
          for (var item in data['qualifications']) {
            final name = item['name']?.toString().trim() ?? '';
            if (name.isNotEmpty) loaded.add(name);
          }
          if (mounted && loaded.isNotEmpty) {
            setState(() => _qualificationOptions = loaded);
          }
        }

        // Incomes from DB
        if (data['incomes'] != null && data['incomes'] is List) {
          final List<String> loaded = [];
          for (var item in data['incomes']) {
            final name = item['name']?.toString().trim() ?? '';
            if (name.isNotEmpty) loaded.add(name);
          }
          if (mounted && loaded.isNotEmpty) {
            setState(() => _incomeOptions = loaded);
          }
        }

        // Working With / Working Sector from DB
        if (data['working_withs'] != null && data['working_withs'] is List) {
          final List<String> loaded = [];
          for (var item in data['working_withs']) {
            final name = item['name']?.toString().trim() ?? '';
            if (name.isNotEmpty) loaded.add(name);
          }
          if (mounted && loaded.isNotEmpty) {
            setState(() => _workingSectorOptions = loaded);
          }
        }

        // Hobbies from DB
        if (data['hobbies'] != null && data['hobbies'] is List) {
          final List<String> loaded = [];
          for (var item in data['hobbies']) {
            final name = item['name']?.toString().trim() ?? '';
            if (name.isNotEmpty) loaded.add(name);
          }
          if (mounted && loaded.isNotEmpty) {
            setState(() => _allHobbies = loaded);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching master options from DB: $e');
    }
  }

  void _refreshState() {
    setState(() {});
  }

  Future<void> _startOtpTimer({bool sendOtp = true}) async {
    _countdownTimer?.cancel();
    _resendSeconds = 22;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        timer.cancel();
      }
    });

    if (sendOtp) {
      final mobile = _mobileController.text.trim();
      if (mobile.length == 10) {
        try {
          final res = await ApiService.instance.sendRegistrationOtp(mobile);
          if (mounted) {
            if (res['success'] == true) {
              RaniAlert.success(
                context,
                res['message'] ?? 'Verification code sent to +91 $mobile',
                title: 'OTP Resent',
              );
            } else {
              RaniAlert.error(
                context,
                res['message'] ?? 'Failed to send OTP code.',
                title: 'OTP Error',
              );
            }
          }
        } catch (e) {
          debugPrint('Error sending reg OTP: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();

    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _aadharController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _subCommunityController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _policeStationController.dispose();
    _pincodeController.dispose();
    _fullAddressController.dispose();
    _collegeNameController.dispose();
    _collegeAddressController.dispose();
    _professionController.dispose();
    _designationController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _aboutMeController.dispose();
    _otp1Controller.dispose();
    _otp2Controller.dispose();
    _otp3Controller.dispose();
    _otp4Controller.dispose();
    _referralCodeController.dispose();

    _firstNameFocus.dispose();
    _middleNameFocus.dispose();
    _lastNameFocus.dispose();
    _aadharFocus.dispose();
    _dayFocus.dispose();
    _monthFocus.dispose();
    _yearFocus.dispose();
    _subCommunityFocus.dispose();
    _emailFocus.dispose();
    _mobileFocus.dispose();
    _countryFocus.dispose();
    _stateFocus.dispose();
    _policeStationFocus.dispose();
    _pincodeFocus.dispose();
    _fullAddressFocus.dispose();
    _collegeNameFocus.dispose();
    _collegeAddressFocus.dispose();
    _professionFocus.dispose();
    _designationFocus.dispose();
    _companyNameFocus.dispose();
    _companyAddressFocus.dispose();
    _aboutMeFocus.dispose();
    _otp1Focus.dispose();
    _otp2Focus.dispose();
    _otp3Focus.dispose();
    _otp4Focus.dispose();
    _referralCodeFocus.dispose();
    _selfiePollTimer?.cancel();

    super.dispose();
  }

  /// Validation logic for each step
  bool get _isCurrentStepValid {
    switch (_currentStep) {
      case 1:
        return _profileFor.trim().isNotEmpty;
      case 2:
        return _selectedGender != null;
      case 3:
        final aadhar = _aadharController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
        return _firstNameController.text.trim().isNotEmpty &&
            _lastNameController.text.trim().isNotEmpty &&
            aadhar.length == 12;
      case 4:
        return _dayController.text.trim().isNotEmpty &&
            _monthController.text.trim().isNotEmpty &&
            _yearController.text.trim().length == 4;
      case 5:
        return _selectedReligion != null && _selectedCommunity != null;
      case 6:
        return _emailController.text.contains('@') &&
            _mobileController.text.trim().replaceAll(RegExp(r'[^0-9]'), '').length == 10;
      case 7:
        final hasCountry = (_selectedCountry != null && _selectedCountry!.isNotEmpty) ||
            _countryController.text.trim().isNotEmpty;
        final hasState = (_selectedState != null && _selectedState!.isNotEmpty) ||
            _stateController.text.trim().isNotEmpty;
        final hasCity = _selectedCity != null && _selectedCity!.isNotEmpty;
        return hasCountry &&
            hasState &&
            hasCity &&
            _fullAddressController.text.trim().isNotEmpty;
      case 8:
        return _selectedMaritalStatus != null &&
            _selectedHeight != null &&
            _selectedDiet != null;
      case 9:
        return _selectedQualification != null;
      case 10:
        return _selectedIncome != null;
      case 11:
        return _selectedWorkingSector != null &&
            _professionController.text.trim().isNotEmpty &&
            _designationController.text.trim().isNotEmpty;
      case 12:
        return _aboutMeController.text.trim().isNotEmpty;
      case 13:
        return _otp1Controller.text.isNotEmpty &&
            _otp2Controller.text.isNotEmpty &&
            _otp3Controller.text.isNotEmpty &&
            _otp4Controller.text.isNotEmpty;
      case 14:
        return true;
      default:
        return true;
    }
  }

  void _showWarning(String msg, [String title = 'Missing Information']) {
    RaniAlert.warning(context, msg, title: title);
  }

  Future<void> _nextStep() async {
    if (_isSubmitting) return;

    // STEP 1: Profile For
    if (_currentStep == 1) {
      if (_profileFor.trim().isEmpty) {
        _showWarning('Please select who this profile is for.');
        return;
      }
    }

    // STEP 2: Gender
    if (_currentStep == 2) {
      if (_selectedGender == null) {
        _showWarning('Please select gender (Bride or Groom).');
        return;
      }
    }

    // STEP 3: Personal Details (First Name, Last Name, Aadhar Number)
    if (_currentStep == 3) {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final aadhar = _aadharController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

      if (firstName.isEmpty || lastName.isEmpty) {
        _showWarning('First name and Last name are required.');
        return;
      }

      if (aadhar.isEmpty) {
        _showWarning('Aadhar Number is required.', 'Missing Information');
        return;
      }

      if (aadhar.length != 12) {
        _showWarning('Aadhar Number must be exactly 12 digits (only numbers).', 'Invalid Aadhar');
        return;
      }

      // Live verification with API: check if Aadhar already exists
      setState(() => _isSubmitting = true);
      try {
        final res = await ApiService.instance.checkUserExists(aadharNumber: aadhar);
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        if (res['exists'] == true) {
          RaniAlert.error(
            context,
            res['message'] ?? 'An account with this Aadhar number already exists.',
            title: 'Account Exists',
          );
          return;
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
      }
    }

    // STEP 4: Date of Birth
    if (_currentStep == 4) {
      final dayStr = _dayController.text.trim();
      final monthStr = _monthController.text.trim();
      final yearStr = _yearController.text.trim();

      if (dayStr.isEmpty || monthStr.isEmpty || yearStr.isEmpty || yearStr.length != 4) {
        _showWarning('Please enter a complete Date of Birth (DD / MM / YYYY).');
        return;
      }

      final d = int.tryParse(dayStr);
      final m = int.tryParse(monthStr);
      final y = int.tryParse(yearStr);
      final currentYear = DateTime.now().year;

      if (d == null || m == null || y == null) {
        _showWarning('Please enter a valid numeric Date of Birth.', 'Invalid Date');
        return;
      }

      if (m < 1 || m > 12) {
        _showWarning('Month must be between 01 and 12.', 'Invalid Month');
        return;
      }

      final daysInMonth = DateTime(y, m + 1, 0).day;
      if (d < 1 || d > daysInMonth) {
        _showWarning('Invalid day. Month $m in year $y has $daysInMonth days.', 'Invalid Day');
        return;
      }

      if (y < 1940 || y > currentYear - 18) {
        _showWarning('Candidate must be at least 18 years old (Year between 1940 and ${currentYear - 18}).', 'Age Requirement');
        return;
      }

      _dayController.text = d.toString().padLeft(2, '0');
      _monthController.text = m.toString().padLeft(2, '0');
      _yearController.text = y.toString();
    }

    // STEP 5: Religion & Community
    if (_currentStep == 5) {
      if (_selectedReligion == null || _selectedCommunity == null) {
        _showWarning('Religion and Community are required.');
        return;
      }
    }

    // STEP 6: Contact Information (Email & Mobile)
    if (_currentStep == 6) {
      final email = _emailController.text.trim();
      final mobile = _mobileController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

      if (email.isEmpty || mobile.isEmpty) {
        _showWarning('Email and Mobile number are required.');
        return;
      }

      final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
      if (!emailRegex.hasMatch(email)) {
        _showWarning('Please enter a valid email address.', 'Invalid Email');
        return;
      }

      if (mobile.length != 10) {
        _showWarning('Please enter a valid 10-digit Indian mobile number.', 'Invalid Mobile');
        return;
      }

      // Live verification with API: check if Email or Mobile already exists
      setState(() => _isSubmitting = true);
      try {
        final res = await ApiService.instance.checkUserExists(email: email, mobile: mobile);
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        if (res['exists'] == true) {
          RaniAlert.error(
            context,
            res['message'] ?? 'An account with this email or mobile number already exists.',
            title: 'Account Exists',
          );
          return;
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
      }
    }

    // STEP 7: Location
    if (_currentStep == 7) {
      final country = _selectedCountry ?? _countryController.text.trim();
      final state = _selectedState ?? _stateController.text.trim();
      final city = _selectedCity;
      final fullAddress = _fullAddressController.text.trim();

      if (country.isEmpty || state.isEmpty || city == null || city.isEmpty) {
        _showWarning('Country, State, and City are required.');
        return;
      }

      if (fullAddress.isEmpty) {
        _showWarning('Full Address is required.');
        return;
      }
    }

    // STEP 8: Physical & Diet
    if (_currentStep == 8) {
      if (_selectedMaritalStatus == null || _selectedHeight == null || _selectedDiet == null) {
        _showWarning('Physical & Diet details are required.');
        return;
      }
    }

    // STEP 9: Education
    if (_currentStep == 9) {
      if (_selectedQualification == null) {
        _showWarning('Highest Qualification is required.');
        return;
      }
    }

    // STEP 10: Income Details
    if (_currentStep == 10) {
      if (_selectedIncome == null) {
        _showWarning('Annual Income detail is required.');
        return;
      }
    }

    // STEP 11: Career Details
    if (_currentStep == 11) {
      final profession = _professionController.text.trim();
      final designation = _designationController.text.trim();

      if (_selectedWorkingSector == null || profession.isEmpty || designation.isEmpty) {
        _showWarning('Career details (Working With, Profession, Designation) are required.');
        return;
      }
    }

    // STEP 12: Express Yourself (Bio) -> Sends OTP!
    if (_currentStep == 12) {
      final bio = _aboutMeController.text.trim();
      if (bio.isEmpty) {
        _showWarning('Please write a little about yourself.');
        return;
      }

      // Step 12 -> 13: Send OTP to mobile
      final mobile = _mobileController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      setState(() => _isSubmitting = true);
      try {
        final res = await ApiService.instance.sendRegistrationOtp(mobile);
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        if (res['success'] == true) {
          setState(() {
            _currentStep = 13;
          });
          _startOtpTimer(sendOtp: false);
          RaniAlert.success(
            context,
            res['message'] ?? 'A verification code has been sent to +91 $mobile',
            title: 'OTP Sent',
          );
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _otp1Focus.requestFocus();
          });
        } else {
          RaniAlert.error(
            context,
            res['message'] ?? 'Failed to send OTP.',
            title: 'OTP Failed',
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        RaniAlert.error(
          context,
          'Unable to send verification code. Please check your connection.',
          title: 'Network Error',
        );
      }
      return;
    }

    // STEP 13: Verify OTP before allowing Step 14
    if (_currentStep == 13) {
      final otp = '${_otp1Controller.text}${_otp2Controller.text}${_otp3Controller.text}${_otp4Controller.text}';
      final mobile = _mobileController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

      if (otp.length != 4) {
        _showWarning('Please enter the 4-digit OTP.', 'Incomplete OTP');
        return;
      }

      setState(() => _isSubmitting = true);
      try {
        final res = await ApiService.instance.verifyRegistrationOtp(mobile, otp);
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        if (res['success'] == true) {
          setState(() {
            _currentStep = 14;
          });
          RaniAlert.success(
            context,
            'Mobile number verified successfully.',
            title: 'Verified!',
          );
        } else {
          RaniAlert.error(
            context,
            res['message'] ?? 'Invalid OTP. Please try again.',
            title: 'Verification Failed',
          );
          _otp1Controller.clear();
          _otp2Controller.clear();
          _otp3Controller.clear();
          _otp4Controller.clear();
          _otp1Focus.requestFocus();
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        RaniAlert.error(
          context,
          'Verification error. Please check your connection and retry.',
          title: 'Connection Error',
        );
      }
      return;
    }

    // STEP 14: Final Submission
    if (_currentStep == 14) {
      setState(() => _isSubmitting = true);
      try {
        final candidateData = {
          'profile_for': _profileFor,
          'gender': _selectedGender == 'Bride' ? 'Female' : 'Male',
          'first_name': _firstNameController.text.trim(),
          'middle_name': _middleNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'aadhar_number': _aadharController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
          'dob': '${_yearController.text.trim()}-${_monthController.text.trim().padLeft(2, '0')}-${_dayController.text.trim().padLeft(2, '0')}',
          'religion': _selectedReligion ?? 'Hindu',
          'community': _selectedCommunity ?? 'Brahmin',
          'sub_community': _subCommunityController.text.trim(),
          'email': _emailController.text.trim(),
          'mobile': _mobileController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
          'country': _selectedCountry ?? (_countryController.text.trim().isNotEmpty ? _countryController.text.trim() : 'India'),
          'state': _selectedState ?? (_stateController.text.trim().isNotEmpty ? _stateController.text.trim() : 'West Bengal'),
          'city': _selectedCity ?? 'Kolkata',
          'police_st': _policeStationController.text.trim(),
          'pincode': _pincodeController.text.trim(),
          'full_address': _fullAddressController.text.trim().isNotEmpty ? _fullAddressController.text.trim() : 'Kolkata, West Bengal',
          'marital_status': _selectedMaritalStatus ?? 'Never Married',
          'height': _selectedHeight ?? "5' 6\"",
          'diet': _selectedDiet ?? 'Vegetarian',
          'highest_qualification': _selectedQualification ?? 'B.Tech / B.E.',
          'college_name': _collegeNameController.text.trim().isNotEmpty ? _collegeNameController.text.trim() : 'Calcutta University',
          'college_address': _collegeAddressController.text.trim(),
          'annual_income': _selectedIncome ?? 'Rs. 10 - 15 Lakh',
          'working_with': _selectedWorkingSector ?? 'Private Sector',
          'profession': _professionController.text.trim().isNotEmpty ? _professionController.text.trim() : 'Software Engineer',
          'designation': _designationController.text.trim(),
          'company_name': _companyNameController.text.trim(),
          'company_address': _companyAddressController.text.trim(),
          'about_yourself': _aboutMeController.text.trim(),
          'hobbies_interests': _selectedHobbies.toList(),
          'referral_code': _referralCodeController.text.trim(),
        };

        final res = await ApiService.instance.registerFinal(
          candidateData,
          profilePictureFile: _profilePictureFile,
          selfieImageFile: _selfieFile,
          selfieData: _selfieData,
        );
        if (!mounted) return;
        setState(() => _isSubmitting = false);

        if (res['success'] == true) {
          RaniAlert.success(
            context,
            'Profile created successfully! Welcome to Rani Matrimonial.',
            title: 'Registration Completed',
          );
          _showCompletionNotice();
        } else {
          final errorMsg = res['message'] ?? (res['errors'] != null ? res['errors'].toString() : 'Registration failed. Please check details.');
          RaniAlert.error(
            context,
            errorMsg,
            title: 'Registration Failed',
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        RaniAlert.error(
          context,
          'Registration submission failed. Please check your connection and try again.',
          title: 'Submission Error',
        );
      }
      return;
    }

    if (_currentStep < 14) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _showCompletionNotice() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF26121B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE5B842), Color(0xFFC59424)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE5B842).withValues(alpha: 0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 38,
                color: Color(0xFF3B0000),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Profile Created! 🎉',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Congratulations! Your royal profile has been registered and verified successfully.\n\nBegin your journey to find your perfect match now.',
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14.5,
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const RaniMainNavigationScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE5B842), Color(0xFFC59424)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE5B842).withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  'Explore Matches',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF3B0000),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Explicitly override global inputDecorationTheme so no default white background leaks in!
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Cinematic Background Photography
            Image.asset(
              'assets/couple1.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/hero.png',
                fit: BoxFit.cover,
              ),
            ),

            // 2. Heavy Blur & Warm Dark Vignette
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.40),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Foreground Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header: "Join Ranimatrimonial"
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Join ',
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'Ranimatrimonial',
                                  style: TextStyle(
                                    color: Color(0xFFE5B842),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your perfect match is waiting.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 18),

                          // Frosted Glassmorphic Step Container
                          _buildGlassmorphicContainer(),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Frosted Glassmorphic Step Container
  Widget _buildGlassmorphicContainer() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: const Color(0x38352822), // Frosted warm dark tint
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step Header & Milestone Progress Bar
          _buildStepHeader(),

          const SizedBox(height: 18),

          // Active Step Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildCurrentStepWidget(),
          ),

          const SizedBox(height: 24),

          // Action Button with Dynamic Activeness
          _buildContinueButton(),
        ],
      ),
    );
  }

  /// Step Header: Dedicated responsive back button, Step badge & Milestone bar (1, 4, 8, 12, 14)
  Widget _buildStepHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Top Navigation Row: Back button (left), Step badge (center), Balanced spacer (right)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Responsive Back Button with comfortable touch target
            GestureDetector(
              onTap: _previousStep,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Step Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFD4A034).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD4A034).withValues(alpha: 0.40),
                  width: 1.0,
                ),
              ),
              child: Text(
                'STEP $_currentStep OF $_totalSteps',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: const Color(0xFFE5B842),
                ),
              ),
            ),

            // Symmetrical spacer to ensure exact center alignment of the badge
            const SizedBox(width: 36, height: 36),
          ],
        ),

        const SizedBox(height: 14),

        // 2. Responsive Milestone Bar (1 -> 4 -> 8 -> 12 -> 14)
        LayoutBuilder(
          builder: (context, constraints) {
            final double barWidth = constraints.maxWidth;
            const double nodeSize = 26.0;
            const double nodeRadius = nodeSize / 2;
            final milestones = [1, 4, 8, 12, 14];
            final progressFactor = ((_currentStep - 1) / (_totalSteps - 1)).clamp(0.0, 1.0);

            return SizedBox(
              width: barWidth,
              height: 30,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Connecting Track
                  Positioned(
                    left: nodeRadius,
                    right: nodeRadius,
                    child: Container(
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Active Filled Track
                  Positioned(
                    left: nodeRadius,
                    right: nodeRadius,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progressFactor,
                      child: Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE5B842), Color(0xFFFBE491)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE5B842).withValues(alpha: 0.60),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Milestone Nodes Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: milestones.map((milestone) {
                      final isReached = _currentStep >= milestone;
                      final isCurrent = _currentStep == milestone;

                      return Container(
                        width: nodeSize,
                        height: nodeSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isReached
                              ? const Color(0xFFD4A034)
                              : const Color(0xFF382924).withValues(alpha: 0.90),
                          border: Border.all(
                            color: isReached
                                ? const Color(0xFFFFF0B8)
                                : Colors.white.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFD4A034).withValues(alpha: 0.80),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$milestone',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isReached
                                  ? const Color(0xFF3B0000)
                                  : Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Builds the current step content
  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case 1:
        return _buildStep1ProfileFor();
      case 2:
        return _buildStep2SelectGender();
      case 3:
        return _buildStep3PersonalDetails();
      case 4:
        return _buildStep4DateOfBirth();
      case 5:
        return _buildStep5ReligionCommunity();
      case 6:
        return _buildStep6ContactInformation();
      case 7:
        return _buildStep7Location();
      case 8:
        return _buildStep8PhysicalDiet();
      case 9:
        return _buildStep9Education();
      case 10:
        return _buildStep10IncomeDetails();
      case 11:
        return _buildStep11CareerDetails();
      case 12:
        return _buildStep12ExpressYourself();
      case 13:
        return _buildStep13VerifyMobileNumber();
      case 14:
        return _buildStep14ProfilePicture();
      default:
        return _buildStep1ProfileFor();
    }
  }

  /// Step 1: "This Profile is for"
  Widget _buildStep1ProfileFor() {
    return Column(
      key: const ValueKey(1),
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(
              color: const Color(0xFFD4A034),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A034).withValues(alpha: 0.30),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite_border_rounded,
            color: Color(0xFFD4A034),
            size: 26,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'This Profile is for',
          style: GoogleFonts.playfairDisplay(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _profileForOptions.map((option) {
            final isSelected = _profileFor == option;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _profileFor = option;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFAF6F0)
                      : const Color(0xFFD5CCC4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFD4A034) : const Color(0xFFC4B8AC),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFD4A034).withValues(alpha: 0.45),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  option,
                  style: GoogleFonts.outfit(
                    color: isSelected ? const Color(0xFF3B0000) : const Color(0xFF4A181E),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Step 2: "Select Gender" (Groom & Bride Cards)
  Widget _buildStep2SelectGender() {
    return Column(
      key: const ValueKey(2),
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(
              color: const Color(0xFFD4A034),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A034).withValues(alpha: 0.30),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: Color(0xFFD4A034),
            size: 28,
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Select Gender',
          style: GoogleFonts.playfairDisplay(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Choose whether this profile is for a Groom or a Bride',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _buildGenderCard(
                title: 'Groom',
                badge: 'Male',
                imagePath: 'assets/groom.png',
                fallbackImage: 'assets/groom.png',
                isSelected: _selectedGender == 'Groom',
                onTap: () {
                  setState(() {
                    _selectedGender = 'Groom';
                  });
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildGenderCard(
                title: 'Bride',
                badge: 'Female',
                imagePath: 'assets/bride.png',
                fallbackImage: 'assets/bride.png',
                isSelected: _selectedGender == 'Bride',
                onTap: () {
                  setState(() {
                    _selectedGender = 'Bride';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard({
    required String title,
    required String badge,
    required String imagePath,
    required String fallbackImage,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAF6F0) : const Color(0xFFEBE3DC),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4A034) : const Color(0xFFC4B8AC),
            width: isSelected ? 2.2 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4A034).withValues(alpha: 0.40),
                    blurRadius: 16,
                    spreadRadius: 1.5,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFFD4A034) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? const Color(0xFFD4A034) : const Color(0xFFC4B8AC),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 13, color: Color(0xFF3B0000))
                    : null,
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE5B842),
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE5B842).withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          fallbackImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C140E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFBF2DC)
                          : const Color(0xFFDFD4C8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF3B0000)
                            : const Color(0xFF7A6258),
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

  /// Step 3: "Personal Details"
  Widget _buildStep3PersonalDetails() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Personal Details',
            style: GoogleFonts.playfairDisplay(
              fontSize: 23,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildInputLabel('First Name'),
        _buildCleanInputField(
          controller: _firstNameController,
          focusNode: _firstNameFocus,
          hintText: 'e.g. Rahul',
        ),

        const SizedBox(height: 14),

        _buildInputLabel('Middle Name (Optional)'),
        _buildCleanInputField(
          controller: _middleNameController,
          focusNode: _middleNameFocus,
          hintText: '',
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Last Name'),
                  _buildCleanInputField(
                    controller: _lastNameController,
                    focusNode: _lastNameFocus,
                    hintText: 'e.g. Sharma',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Aadhar Number'),
                  _buildCleanInputField(
                    controller: _aadharController,
                    focusNode: _aadharFocus,
                    hintText: '12-digit Aadhar Number',
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Step 4: "Date of Birth"
  Widget _buildStep4DateOfBirth() {
    return Column(
      key: const ValueKey(4),
      children: [
        Text(
          'Date of Birth',
          style: GoogleFonts.playfairDisplay(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Enter birth date as DD / MM / YYYY',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),

        // Responsive DOB Row with Slashes vertically centered to the input fields
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // DAY
            Expanded(
              flex: 5,
              child: _buildDobField(
                label: 'DAY (DD)',
                hint: 'DD',
                controller: _dayController,
                focusNode: _dayFocus,
                maxLength: 2,
                onChanged: (val) {
                  if (val.length == 2) {
                    _monthFocus.requestFocus();
                  }
                },
              ),
            ),

            // Slash 1: exactly matching 48px input height
            SizedBox(
              height: 48,
              width: 20,
              child: Center(
                child: Text(
                  '/',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    color: const Color(0xFFE5B842),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // MONTH
            Expanded(
              flex: 5,
              child: _buildDobField(
                label: 'MONTH (MM)',
                hint: 'MM',
                controller: _monthController,
                focusNode: _monthFocus,
                maxLength: 2,
                onChanged: (val) {
                  if (val.length == 2) {
                    _yearFocus.requestFocus();
                  } else if (val.isEmpty) {
                    _dayFocus.requestFocus();
                  }
                },
              ),
            ),

            // Slash 2: exactly matching 48px input height
            SizedBox(
              height: 48,
              width: 20,
              child: Center(
                child: Text(
                  '/',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    color: const Color(0xFFE5B842),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // YEAR
            Expanded(
              flex: 7,
              child: _buildDobField(
                label: 'YEAR (YYYY)',
                hint: 'YYYY',
                controller: _yearController,
                focusNode: _yearFocus,
                maxLength: 4,
                onChanged: (val) {
                  if (val.isEmpty) {
                    _monthFocus.requestFocus();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDobField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required int maxLength,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFD4A034),
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            maxLength: maxLength,
            textAlign: TextAlign.center,
            onChanged: onChanged,
            cursorColor: const Color(0xFF881337),
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C140E),
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFD5CCC4),
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8C7972),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFC4B8AC),
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFC4B8AC),
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE5B842),
                  width: 1.8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Step 5: "Religion & Community"
  Widget _buildStep5ReligionCommunity() {
    return Column(
      key: const ValueKey(5),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Religion & Community',
            style: GoogleFonts.playfairDisplay(
              fontSize: 23,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildInputLabel('Religion'),
        _buildCleanDropdownSelector(
          title: 'Select Religion',
          value: _selectedReligion,
          items: _religionOptions,
          onSelected: (val) {
            setState(() {
              if (_selectedReligion != val) {
                _selectedReligion = val;
                _selectedCommunity = null; // Reset community when religion changes
              }
            });
          },
        ),

        const SizedBox(height: 14),

        _buildInputLabel('Community'),
        _buildCleanDropdownSelector(
          title: _selectedReligion == null
              ? 'Select Religion First'
              : 'Select Community',
          value: _selectedCommunity,
          items: _currentCommunityOptions,
          onTapOverride: _selectedReligion == null
              ? () {
                  RaniAlert.warning(
                    context,
                    'Please select your Religion first to view matching communities.',
                    title: 'Select Religion',
                  );
                }
              : null,
          onSelected: (val) {
            setState(() {
              _selectedCommunity = val;
            });
          },
        ),

        const SizedBox(height: 14),

        _buildInputLabel('Sub Community (Optional)'),
        _buildCleanInputField(
          controller: _subCommunityController,
          focusNode: _subCommunityFocus,
          hintText: 'Enter Sub Community',
        ),
      ],
    );
  }

  /// Step 6: "Contact Information"
  Widget _buildStep6ContactInformation() {
    return Column(
      key: const ValueKey(6),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Contact Information',
            style: GoogleFonts.playfairDisplay(
              fontSize: 23,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildInputLabel('Email ID'),
        _buildCleanInputField(
          controller: _emailController,
          focusNode: _emailFocus,
          hintText: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 14),

        _buildInputLabel('Mobile Number'),
        _buildPhoneInputField(
          controller: _mobileController,
          focusNode: _mobileFocus,
          hintText: '10-digit number',
        ),
      ],
    );
  }

  /// Clean Phone Input with +91 Prefix Badge
  Widget _buildPhoneInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
  }) {
    final isFocused = focusNode.hasFocus;
    final hasValue = controller.text.isNotEmpty;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: hasValue ? const Color(0xFFFAF6F0) : const Color(0xFFD5CCC4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? const Color(0xFFE5B842)
              : (hasValue ? const Color(0xFFD4A034) : const Color(0xFFC4B8AC)),
          width: isFocused ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '+91',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3B0000),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: const Color(0xFFBFAF9E),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.phone,
              cursorColor: const Color(0xFF881337),
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C140E),
              ),
              decoration: InputDecoration(
                filled: false,
                hintText: hintText,
                hintStyle: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8C7972),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 7: "Location"
  Widget _buildStep7Location() {
    return Column(
      key: const ValueKey(7),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Location',
            style: GoogleFonts.playfairDisplay(
              fontSize: 23,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel('Country (Living In)'),
        _buildCleanDropdownSelector(
          title: 'Select Country',
          value: _selectedCountry,
          items: _countryOptions.isNotEmpty ? _countryOptions : ['India'],
          onSelected: (val) {
            setState(() {
              _selectedCountry = val;
              _countryController.text = val;
              final states = _countryToStates[val] ?? [];
              _selectedState = states.isNotEmpty ? states.first : null;
              _stateController.text = _selectedState ?? '';
              final cities = _selectedState != null
                  ? (_countryStateToCities[val]?[_selectedState] ?? [])
                  : <String>[];
              _selectedCity = cities.isNotEmpty ? cities.first : null;
            });
          },
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('State'),
                  _buildCleanDropdownSelector(
                    title: 'Select State',
                    value: _selectedState,
                    items: _currentStateOptions,
                    onTapOverride: _currentStateOptions.isEmpty
                        ? () {
                            _showWarning('Please select Country first.');
                          }
                        : null,
                    onSelected: (val) {
                      setState(() {
                        _selectedState = val;
                        _stateController.text = val;
                        final cities = _selectedCountry != null
                            ? (_countryStateToCities[_selectedCountry]?[val] ?? [])
                            : <String>[];
                        _selectedCity = cities.isNotEmpty ? cities.first : null;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('City'),
                  _buildCleanDropdownSelector(
                    title: 'Select City',
                    value: _selectedCity,
                    items: _currentCityOptions,
                    onTapOverride: _currentCityOptions.isEmpty
                        ? () {
                            if (_selectedState == null) {
                              _showWarning('Please select State first.');
                            } else {
                              _showWarning('No cities found for .');
                            }
                          }
                        : null,
                    onSelected: (val) {
                      setState(() {
                        _selectedCity = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Police Station'),
                  _buildCleanInputField(
                    controller: _policeStationController,
                    focusNode: _policeStationFocus,
                    hintText: 'e.g. Park Street Police Station',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Pincode'),
                  _buildCleanInputField(
                    controller: _pincodeController,
                    focusNode: _pincodeFocus,
                    hintText: 'e.g. 700016',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildInputLabel('Full Address'),
        _buildCleanInputField(
          controller: _fullAddressController,
          focusNode: _fullAddressFocus,
          hintText: 'Enter your complete residential address',
        ),
      ],
    );
  }

  /// Step 8: "Physical & Diet"
  Widget _buildStep8PhysicalDiet() {
    return Column(
      key: const ValueKey(8),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Physical & Diet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 23,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildInputLabel('Marital Status'),
        _buildCleanDropdownSelector(
          title: 'Select Status',
          value: _selectedMaritalStatus,
          items: _maritalStatusOptions,
          onSelected: (val) {
            setState(() {
              _selectedMaritalStatus = val;
            });
          },
        ),

        const SizedBox(height: 14),

        _buildInputLabel('Height'),
        _buildCleanDropdownSelector(
          title: 'Select Height',
          value: _selectedHeight,
          items: _heightOptions,
          onSelected: (val) {
            setState(() {
              _selectedHeight = val;
            });
          },
        ),

        const SizedBox(height: 14),

        _buildInputLabel('Diet'),
        _buildCleanDropdownSelector(
          title: 'Select Diet',
          value: _selectedDiet,
          items: _dietOptions,
          onSelected: (val) {
            setState(() {
              _selectedDiet = val;
            });
          },
        ),
      ],
    );
  }

  /// Step 9: "Education"
  Widget _buildStep9Education() {
    return Column(
      key: const ValueKey(9),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Education',
            style: GoogleFonts.playfairDisplay(
              fontSize: 23,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildInputLabel('Highest Qualification'),
        _buildCleanDropdownSelector(
          title: 'Select Qualification',
          value: _selectedQualification,
          items: _qualificationOptions,
          onSelected: (val) {
            setState(() {
              _selectedQualification = val;
            });
          },
        ),

        const SizedBox(height: 14),

        _buildInputLabel('College Name'),
        _buildCleanInputField(
          controller: _collegeNameController,
          focusNode: _collegeNameFocus,
          hintText: 'Enter college name',
        ),

        const SizedBox(height: 14),

        _buildInputLabel('College Address'),
        _buildCleanInputField(
          controller: _collegeAddressController,
          focusNode: _collegeAddressFocus,
          hintText: 'Enter college address',
        ),
      ],
    );
  }

  /// Step 10: "Income Details"
  Widget _buildStep10IncomeDetails() {
    return Column(
      key: const ValueKey(10),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Income Details',
            style: GoogleFonts.playfairDisplay(
              fontSize: 23,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),

        _buildInputLabel('Annual Income'),
        _buildCleanDropdownSelector(
          title: 'Select Annual Income',
          value: _selectedIncome,
          items: _incomeOptions,
          onSelected: (val) {
            setState(() {
              _selectedIncome = val;
            });
          },
        ),
      ],
    );
  }

  /// Step 11: "Career Details" (Screenshot 1)
  Widget _buildStep11CareerDetails() {
    return Column(
      key: const ValueKey(11),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Career Details',
            style: GoogleFonts.playfairDisplay(
              fontSize: 23,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel('Working With'),
        _buildCleanDropdownSelector(
          title: 'Select Working Sector',
          value: _selectedWorkingSector,
          items: _workingSectorOptions,
          onSelected: (val) {
            setState(() {
              _selectedWorkingSector = val;
            });
          },
        ),

        const SizedBox(height: 12),

        _buildInputLabel('Your Profession'),
        _buildCleanInputField(
          controller: _professionController,
          focusNode: _professionFocus,
          hintText: 'e.g. Software Engineer, Doctor, Business',
        ),

        const SizedBox(height: 12),

        _buildInputLabel('Your Designation'),
        _buildCleanInputField(
          controller: _designationController,
          focusNode: _designationFocus,
          hintText: 'e.g. Senior Manager, Consultant',
        ),

        const SizedBox(height: 12),

        _buildInputLabel('Company Name'),
        _buildCleanInputField(
          controller: _companyNameController,
          focusNode: _companyNameFocus,
          hintText: 'e.g. TCS, Infosys, Self Employed',
        ),

        const SizedBox(height: 12),

        _buildInputLabel('Company Address'),
        _buildCleanInputField(
          controller: _companyAddressController,
          focusNode: _companyAddressFocus,
          hintText: 'Enter company address',
        ),
      ],
    );
  }

  /// Step 12: "Express Yourself" (Screenshot 2)
  Widget _buildStep12ExpressYourself() {
    return Column(
      key: const ValueKey(12),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Express Yourself',
            style: GoogleFonts.playfairDisplay(
              fontSize: 23,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel('Write a little about yourself...'),
        Container(
          height: 84,
          decoration: BoxDecoration(
            color: const Color(0xFFD5CCC4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _aboutMeFocus.hasFocus
                  ? const Color(0xFFE5B842)
                  : const Color(0xFFC4B8AC),
              width: _aboutMeFocus.hasFocus ? 1.8 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Stack(
            children: [
              TextField(
                controller: _aboutMeController,
                focusNode: _aboutMeFocus,
                maxLines: 3,
                cursorColor: const Color(0xFF881337),
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2C140E),
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'I am a caring and passionate person who loves...',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF8C7972),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Icon(
                  Icons.signal_cellular_0_bar_rounded,
                  size: 14,
                  color: const Color(0xFF8C7972).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        _buildInputLabel('Hobbies & Interests'),
        SizedBox(
          height: 160,
          child: RawScrollbar(
            thumbColor: Colors.white.withValues(alpha: 0.65),
            radius: const Radius.circular(3),
            thickness: 4,
            thumbVisibility: true,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE5B842)
                              : const Color(0xFFD5CCC4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFC59424)
                                : const Color(0xFFC4B8AC),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFE5B842).withValues(alpha: 0.45),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          hobby,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF3B0000)
                                : const Color(0xFF4A181E),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Step 13: "Verify Mobile Number" (Screenshot 3)
  Widget _buildStep13VerifyMobileNumber() {
    final phoneNumber = _mobileController.text.isNotEmpty
        ? _mobileController.text.trim()
        : '6292237210';

    return Column(
      key: const ValueKey(13),
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(
              color: const Color(0xFFD4A034),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A034).withValues(alpha: 0.35),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFFD4A034),
            size: 28,
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Verify Mobile Number',
          style: GoogleFonts.playfairDisplay(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'A 4-digit verification code was sent via WhatsApp to:',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            color: Colors.white.withValues(alpha: 0.82),
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Phone number badge with Edit Number button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD4A034).withValues(alpha: 0.5),
                  width: 1.0,
                ),
              ),
              child: Text(
                '+91 $phoneNumber',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE5B842),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentStep = 6; // Go back to Contact Information
                });
              },
              child: Text(
                'Edit Number',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 4-Digit OTP Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOtpBox(controller: _otp1Controller, focusNode: _otp1Focus, nextFocus: _otp2Focus),
            const SizedBox(width: 12),
            _buildOtpBox(controller: _otp2Controller, focusNode: _otp2Focus, nextFocus: _otp3Focus, prevFocus: _otp1Focus),
            const SizedBox(width: 12),
            _buildOtpBox(controller: _otp3Controller, focusNode: _otp3Focus, nextFocus: _otp4Focus, prevFocus: _otp2Focus),
            const SizedBox(width: 12),
            _buildOtpBox(controller: _otp4Controller, focusNode: _otp4Focus, prevFocus: _otp3Focus),
          ],
        ),

        const SizedBox(height: 20),

        // Resend Timer
        _resendSeconds > 0
            ? RichText(
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  children: [
                    const TextSpan(text: 'Resend code in '),
                    TextSpan(
                      text: '$_resendSeconds',
                      style: const TextStyle(
                        color: Color(0xFFE5B842),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: ' seconds'),
                  ],
                ),
              )
            : GestureDetector(
                onTap: _startOtpTimer,
                child: Text(
                  'Resend Code Now',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE5B842),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildOtpBox({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    FocusNode? prevFocus,
  }) {
    final isFocused = focusNode.hasFocus;
    final hasValue = controller.text.isNotEmpty;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFD5CCC4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? const Color(0xFFE5B842)
              : (hasValue ? const Color(0xFFD4A034) : const Color(0xFFC4B8AC)),
          width: isFocused ? 2.0 : 1.2,
        ),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          maxLength: 1,
          textAlign: TextAlign.center,
          cursorColor: const Color(0xFF881337),
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2C140E),
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) {
            if (val.isNotEmpty && nextFocus != null) {
              nextFocus.requestFocus();
            } else if (val.isEmpty && prevFocus != null) {
              prevFocus.requestFocus();
            }
          },
        ),
      ),
    );
  }

  /// Pick profile picture from gallery
  Future<void> _pickProfilePicture() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _profilePictureFile = File(picked.path);
        });
        if (mounted) {
          RaniAlert.success(
            context,
            'Profile picture selected successfully.',
            title: 'Photo Uploaded',
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking profile picture: $e');
      if (mounted) {
        RaniAlert.error(
          context,
          'Unable to access gallery. Please check permissions.',
          title: 'Photo Error',
        );
      }
    }
  }

  /// Take live selfie with front camera
  Future<void> _takeLiveSelfie() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selfieFile = File(picked.path);
        });
        if (mounted) {
          RaniAlert.success(
            context,
            'Live selfie captured and verified!',
            title: 'Selfie Verified',
          );
        }
      }
    } catch (e) {
      debugPrint('Error taking live selfie: $e');
      if (mounted) {
        RaniAlert.error(
          context,
          'Unable to open camera. Please check camera permissions.',
          title: 'Camera Error',
        );
      }
    }
  }

  /// Send selfie capture link to WhatsApp and poll for completion
  Future<void> _linkToPhoneSelfie() async {
    final mobile = _mobileController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (mobile.length != 10) {
      _showWarning('Please enter a valid 10-digit mobile number in Step 6.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await ApiService.instance.sendSelfieLink(mobile);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (res['success'] == true) {
        _showPhoneSelfiePollingDialog(mobile);
      } else {
        RaniAlert.error(
          context,
          res['message'] ?? 'Failed to send WhatsApp verification link.',
          title: 'Link Failed',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      RaniAlert.error(
        context,
        'Could not send link. Please verify internet connection.',
        title: 'Connection Error',
      );
    }
  }

  /// Show polling dialog for Phone Selfie capture
  void _showPhoneSelfiePollingDialog(String mobile) {
    _selfiePollTimer?.cancel();
    int attempts = 0;
    const maxAttempts = 60; // Up to 3 minutes

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF26121B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFD4A034), width: 1.2),
          ),
          title: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE5B842), Color(0xFFC59424)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE5B842).withValues(alpha: 0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smartphone_rounded,
                  size: 32,
                  color: Color(0xFF3B0000),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Link Sent to Phone',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A secure selfie link has been sent via WhatsApp to +91 $mobile.\n\nPlease open WhatsApp, click the link, and complete your selfie verification on your phone.',
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13.5,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const RaniMatrimonialLoader.mini(size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Waiting for selfie from phone...',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFE5B842),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  _selfiePollTimer?.cancel();
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'Cancel & Try Another Way',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    _selfiePollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      if (attempts >= maxAttempts) {
        timer.cancel();
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          RaniAlert.warning(
            context,
            'Selfie verification timed out. You can take a live selfie directly or try again.',
            title: 'Verification Timeout',
          );
        }
        return;
      }

      try {
        final statusData = await ApiService.instance.checkSelfieStatus(mobile);
        if (statusData['success'] == true && statusData['selfie_data'] != null) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _selfieData = statusData['selfie_data'] as String;
            });
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            RaniAlert.success(
              context,
              'Your live selfie was successfully verified via phone.',
              title: 'Selfie Verified!',
            );
          }
        }
      } catch (e) {
        debugPrint('Polling selfie error: $e');
      }
    });
  }

  /// Step 14: "Profile Picture" (Screenshot 4 - Final Step)
  Widget _buildStep14ProfilePicture() {
    return Column(
      key: const ValueKey(14),
      children: [
        Text(
          'Profile Picture',
          style: GoogleFonts.playfairDisplay(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // Main Upload Box
        GestureDetector(
          onTap: _pickProfilePicture,
          child: Container(
            width: double.infinity,
            height: 125,
            decoration: BoxDecoration(
              color: const Color(0x384E342E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _profilePictureFile != null ? const Color(0xFFE5B842) : const Color(0xFFD4A034),
                width: _profilePictureFile != null ? 1.8 : 1.2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE5B842), Color(0xFFC59424)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE5B842).withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: _profilePictureFile != null
                        ? ClipOval(
                            child: Image.file(
                              _profilePictureFile!,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF3B0000),
                            size: 28,
                          ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _profilePictureFile != null
                        ? 'Photo Uploaded (Tap to Change)'
                        : 'Upload Profile Picture',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Two Quick Action Buttons: Take Live Selfie & Link to Phone
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _takeLiveSelfie,
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: _selfieFile != null ? const Color(0xFFFAF6F0) : const Color(0xFFD5CCC4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selfieFile != null ? const Color(0xFFD4A034) : const Color(0xFFC4B8AC),
                      width: _selfieFile != null ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selfieFile != null ? Icons.check_circle_rounded : Icons.camera_alt_outlined,
                        size: 20,
                        color: _selfieFile != null ? const Color(0xFF1B5E20) : const Color(0xFFD4A034),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selfieFile != null ? 'Selfie Taken ✓' : 'Take Live Selfie',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _selfieFile != null ? const Color(0xFF1B5E20) : const Color(0xFF4A181E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _linkToPhoneSelfie,
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: _selfieData != null ? const Color(0xFFFAF6F0) : const Color(0xFFD5CCC4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selfieData != null ? const Color(0xFFD4A034) : const Color(0xFFC4B8AC),
                      width: _selfieData != null ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selfieData != null ? Icons.check_circle_rounded : Icons.smartphone_rounded,
                        size: 20,
                        color: _selfieData != null ? const Color(0xFF1B5E20) : const Color(0xFFD4A034),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selfieData != null ? 'Phone Verified ✓' : 'Link to Phone',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _selfieData != null ? const Color(0xFF1B5E20) : const Color(0xFF4A181E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Referral Code (Optional) Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0x384E342E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Referral Code (Optional)',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: TextField(
                  controller: _referralCodeController,
                  focusNode: _referralCodeFocus,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C140E),
                    letterSpacing: 1.0,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFD5CCC4),
                    hintText: 'ENTER BRANCH CODE (E.G. BRM001)',
                    hintStyle: GoogleFonts.sourceCodePro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8C7972),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'If you were assisted or referred by a regional branch center, please enter their branch code.',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.70),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Reusable Input Label with nice spacing
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.95),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Reusable Clean Single-Layer Input Field
  Widget _buildCleanInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    final hasValue = controller.text.isNotEmpty;

    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        buildCounter: maxLength != null ? (_, {required currentLength, required isFocused, maxLength}) => null : null,
        cursorColor: const Color(0xFF881337),
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF2C140E),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: hasValue ? const Color(0xFFFAF6F0) : const Color(0xFFD5CCC4),
          hintText: hintText,
          hintStyle: GoogleFonts.outfit(
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8C7972),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: hasValue ? const Color(0xFFD4A034) : const Color(0xFFC4B8AC),
              width: 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: hasValue ? const Color(0xFFD4A034) : const Color(0xFFC4B8AC),
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFE5B842),
              width: 1.8,
            ),
          ),
        ),
      ),
    );
  }

  /// Reusable Clean Dropdown Selector matching the input field style
  Widget _buildCleanDropdownSelector({
    required String title,
    required String? value,
    required List<String> items,
    required ValueChanged<String> onSelected,
    VoidCallback? onTapOverride,
  }) {
    final hasValue = value != null;

    return GestureDetector(
      onTap: () {
        if (onTapOverride != null) {
          onTapOverride();
          return;
        }
        _showSelectionBottomSheet(
          title: title,
          currentValue: value,
          items: items,
          onSelected: onSelected,
        );
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: hasValue ? const Color(0xFFFAF6F0) : const Color(0xFFD5CCC4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue ? const Color(0xFFD4A034) : const Color(0xFFC4B8AC),
            width: hasValue ? 1.8 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value ?? title,
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                  color: hasValue ? const Color(0xFF2C140E) : const Color(0xFF8C7972),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF4A181E),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  /// Sleek Bottom Sheet for Dropdown Selection with optional quick search
  void _showSelectionBottomSheet({
    required String title,
    required String? currentValue,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredItems = searchQuery.isEmpty
                ? items
                : items
                    .where((item) =>
                        item.toLowerCase().contains(searchQuery.toLowerCase()))
                    .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.62,
              decoration: const BoxDecoration(
                color: Color(0xFFFAF6F0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0C3B7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C140E),
                    ),
                  ),
                  if (items.length > 5) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4C5B9)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 20, color: Color(0xFF8C7972)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (query) {
                                setModalState(() {
                                  searchQuery = query.trim();
                                });
                              },
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: const Color(0xFF2C140E),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Text(
                              'No options found',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: const Color(0xFF8C7972),
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredItems.length,
                            separatorBuilder: (context, i) => const Divider(
                              color: Color(0xFFEADFD5),
                              height: 1,
                            ),
                            itemBuilder: (context, i) {
                              final item = filteredItems[i];
                              final isSelected = item == currentValue;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                title: Text(
                                  item,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight:
                                        isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF881337)
                                        : const Color(0xFF2C140E),
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle_rounded,
                                        color: Color(0xFF881337), size: 20)
                                    : null,
                                onTap: () {
                                  onSelected(item);
                                  Navigator.of(context).pop();
                                },
                              );
                            },
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

  /// "Continue" / "Verify & Continue" / "Complete Registration" Action Button
  Widget _buildContinueButton() {
    final isValid = _isCurrentStepValid;

    String buttonText = 'Continue';
    if (_currentStep == 13) {
      buttonText = 'Verify & Continue';
    } else if (_currentStep == 14) {
      buttonText = 'Complete Registration';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: isValid
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE5B842), // Rich Radiant Gold
                  Color(0xFFC79224), // Deep Burnished Gold
                ],
              )
            : null,
        color: isValid ? null : const Color(0xFF8F857D).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(26), // Full sleek rounded pill
        boxShadow: isValid
            ? [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: _isSubmitting ? null : _nextStep,
          child: Center(
            child: _isSubmitting
                ? const RaniMatrimonialLoader.mini(
                    size: 22,
                    color: Color(0xFF3B0000),
                  )
                : Text(
                    buttonText,
                    style: GoogleFonts.outfit(
                      color: isValid
                          ? const Color(0xFF3B0000)
                          : Colors.white.withValues(alpha: 0.65),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}