import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_navigation_screen.dart';

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
  final TextEditingController _countryController = TextEditingController(text: 'India');
  final TextEditingController _stateController = TextEditingController(text: 'West Bengal');
  String? _selectedCity;
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

  // Step 14: Profile Picture & Referral
  bool _hasUploadedPhoto = false;
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

  final List<String> _religionOptions = const [
    'Hindu',
    'Muslim',
    'Sikh',
    'Christian',
    'Jain',
    'Buddhist',
    'Parsi',
    'Jewish',
    'Other',
  ];

  final List<String> _communityOptions = const [
    'Brahmin',
    'Rajput',
    'Agarwal',
    'Kayastha',
    'Maratha',
    'Yadav',
    'Khatri',
    'Sunni',
    'Shia',
    'Jat',
    'Baniya',
    'Gupta',
    'Other',
  ];

  final List<String> _cityOptions = const [
    'Kolkata',
    'Howrah',
    'Durgapur',
    'Asansol',
    'Siliguri',
    'Bardhaman',
    'Malda',
    'Baharampur',
    'Kharagpur',
    'Shantipur',
    'Dankuni',
    'Dhulian',
    'Ranaghat',
    'Haldia',
    'Habra',
    'Uluberia',
    'Other',
  ];

  final List<String> _maritalStatusOptions = const [
    'Never Married',
    'Divorced',
    'Widowed',
    'Awaiting Divorce',
    'Annulled',
  ];

  final List<String> _heightOptions = const [
    '4\' 5" (135 cm)',
    '4\' 6" (137 cm)',
    '4\' 7" (140 cm)',
    '4\' 8" (142 cm)',
    '4\' 9" (145 cm)',
    '4\' 10" (147 cm)',
    '4\' 11" (150 cm)',
    '5\' 0" (152 cm)',
    '5\' 1" (155 cm)',
    '5\' 2" (157 cm)',
    '5\' 3" (160 cm)',
    '5\' 4" (163 cm)',
    '5\' 5" (165 cm)',
    '5\' 6" (168 cm)',
    '5\' 7" (170 cm)',
    '5\' 8" (173 cm)',
    '5\' 9" (175 cm)',
    '5\' 10" (178 cm)',
    '5\' 11" (180 cm)',
    '6\' 0" (183 cm)',
    '6\' 1" (185 cm)',
    '6\' 2" (188 cm)',
    '6\' 3" (191 cm)',
    '6\' 4" (193 cm)',
  ];

  final List<String> _dietOptions = const [
    'Vegetarian',
    'Non-Vegetarian',
    'Eggetarian',
    'Vegan',
    'Jain',
  ];

  final List<String> _qualificationOptions = const [
    'MBA',
    'B.Tech / B.E.',
    'M.Tech / M.E.',
    'MBBS / MD',
    'BCA / MCA',
    'B.Sc / M.Sc',
    'B.Com / M.Com',
    'B.A / M.A',
    'BBA',
    'CA / CS',
    'LLB / LLM',
    'Ph.D / Doctorate',
    'Diploma',
    'Higher Secondary (12th)',
    'Other',
  ];

  final List<String> _incomeOptions = const [
    'No Income',
    'Below 2 Lakhs',
    '2 - 3 Lakhs',
    '3 - 4 Lakhs',
    '4 - 6 Lakhs',
    '6 - 10 Lakhs',
    '10 - 15 Lakhs',
    '15 - 25 Lakhs',
    '25 - 50 Lakhs',
    '50 Lakhs - 1 Crore',
    'Above 1 Crore',
  ];

  final List<String> _workingSectorOptions = const [
    'Private Sector',
    'Government / Public Sector',
    'Civil Services',
    'Business / Self Employed',
    'Defence',
    'Non-Profit / NGO',
    'Not Working',
    'Other',
  ];

  final List<String> _allHobbies = const [
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
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_refreshState);
    _lastNameController.addListener(_refreshState);
    _dayController.addListener(_refreshState);
    _monthController.addListener(_refreshState);
    _yearController.addListener(_refreshState);
    _emailController.addListener(_refreshState);
    _mobileController.addListener(_refreshState);
    _countryController.addListener(_refreshState);
    _stateController.addListener(_refreshState);
    _collegeNameController.addListener(_refreshState);
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
  }

  void _refreshState() {
    setState(() {});
  }

  void _startOtpTimer() {
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

    super.dispose();
  }

  /// Validation logic for each step
  bool get _isCurrentStepValid {
    switch (_currentStep) {
      case 1:
        return _profileFor.isNotEmpty;
      case 2:
        return _selectedGender != null;
      case 3:
        return _firstNameController.text.trim().isNotEmpty &&
            _lastNameController.text.trim().isNotEmpty;
      case 4:
        return _dayController.text.trim().length == 2 &&
            _monthController.text.trim().length == 2 &&
            _yearController.text.trim().length == 4;
      case 5:
        return _selectedReligion != null && _selectedCommunity != null;
      case 6:
        return _emailController.text.contains('@') &&
            _mobileController.text.trim().length >= 10;
      case 7:
        return _countryController.text.trim().isNotEmpty &&
            _stateController.text.trim().isNotEmpty &&
            _selectedCity != null;
      case 8:
        return _selectedMaritalStatus != null &&
            _selectedHeight != null &&
            _selectedDiet != null;
      case 9:
        return _selectedQualification != null &&
            _collegeNameController.text.trim().isNotEmpty;
      case 10:
        return _selectedIncome != null;
      case 11:
        return _selectedWorkingSector != null &&
            _professionController.text.trim().isNotEmpty;
      case 12:
        return _aboutMeController.text.trim().isNotEmpty ||
            _selectedHobbies.isNotEmpty;
      case 13:
        return _otp1Controller.text.isNotEmpty &&
            _otp2Controller.text.isNotEmpty &&
            _otp3Controller.text.isNotEmpty &&
            _otp4Controller.text.isNotEmpty;
      case 14:
        return true; // Final step (picture & referral code)
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_isCurrentStepValid) return;

    if (_currentStep < 14) {
      setState(() {
        _currentStep++;
      });
      if (_currentStep == 13) {
        _startOtpTimer();
      }
    } else {
      _showCompletionNotice();
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
                imagePath: 'assets/growm2.png',
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
                imagePath: 'assets/bride2.png',
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
              _selectedReligion = val;
            });
          },
        ),

        const SizedBox(height: 14),

        _buildInputLabel('Community'),
        _buildCleanDropdownSelector(
          title: 'Select Community',
          value: _selectedCommunity,
          items: _communityOptions,
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
        _buildCleanInputField(
          controller: _countryController,
          focusNode: _countryFocus,
          hintText: 'India',
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('State'),
                  _buildCleanInputField(
                    controller: _stateController,
                    focusNode: _stateFocus,
                    hintText: 'West Bengal',
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
                    items: _cityOptions,
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
          onTap: () {
            setState(() {
              _hasUploadedPhoto = !_hasUploadedPhoto;
            });
          },
          child: Container(
            width: double.infinity,
            height: 125,
            decoration: BoxDecoration(
              color: const Color(0x384E342E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFD4A034),
                width: 1.2,
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
                    child: Icon(
                      _hasUploadedPhoto ? Icons.check_circle_rounded : Icons.image_outlined,
                      color: const Color(0xFF3B0000),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _hasUploadedPhoto ? 'Photo Uploaded (Tap to Change)' : 'Upload Profile Picture',
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
                onTap: () {
                  setState(() {
                    _hasUploadedPhoto = true;
                  });
                },
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5CCC4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFC4B8AC),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 20,
                        color: Color(0xFFD4A034),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Take Live Selfie',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4A181E),
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
                onTap: () {
                  setState(() {
                    _hasUploadedPhoto = true;
                  });
                },
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5CCC4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFC4B8AC),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.smartphone_rounded,
                        size: 20,
                        color: Color(0xFFD4A034),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Link to Phone',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4A181E),
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
  }) {
    final hasValue = controller.text.isNotEmpty;

    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
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
  }) {
    final hasValue = value != null;

    return GestureDetector(
      onTap: () {
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

  /// Sleek Bottom Sheet for Dropdown Selection
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
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.58,
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
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, i) => const Divider(
                  color: Color(0xFFEADFD5),
                  height: 1,
                ),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final isSelected = item == currentValue;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    title: Text(
                      item,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF881337) : const Color(0xFF2C140E),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF881337), size: 20)
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
      ),
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
          onTap: isValid ? _nextStep : null,
          child: Center(
            child: Text(
              buttonText,
              style: GoogleFonts.outfit(
                 color: isValid
                    ? const Color(0xFF3B0000) // Deep wine text on gold
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