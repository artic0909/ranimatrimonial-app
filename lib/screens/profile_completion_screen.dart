import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../components/rani_alert.dart';
import 'aadhaar_verification_screen.dart';

/// Screen: Candidate Profile Details Completion
/// Contains all candidate fields available on the website profile edit (my_profile.blade.php):
/// - About Yourself / Bio
/// - Family Background (Father & Mother professions, Siblings, Family Location, Financial Status, Family Type & Values)
/// - Horoscope & Astro (Mother Tongue, Manglik, Gothra, Birth Time & City)
/// - Physical & Lifestyle (Height, Weight, Diet, Blood Group, Health Info, Grew Up In)
/// - Education & Career (Qualification, College, Working Sector, Profession, Designation, Company, Income)
/// - Location & Residency (Residency Status, Police Station, Pincode)
class RaniProfileCompletionScreen extends StatefulWidget {
  final String? initialAadhar;

  const RaniProfileCompletionScreen({
    super.key,
    this.initialAadhar,
  });

  @override
  State<RaniProfileCompletionScreen> createState() => _RaniProfileCompletionScreenState();
}

class _RaniProfileCompletionScreenState extends State<RaniProfileCompletionScreen> {
  bool _isSaving = false;

  // 1. About Yourself
  final TextEditingController _aboutMeController = TextEditingController();

  // 2. Family details
  final TextEditingController _fatherProfessionController = TextEditingController();
  final TextEditingController _motherProfessionController = TextEditingController();
  final TextEditingController _familyLocationController = TextEditingController();
  int _brothersCount = 0;
  int _sistersCount = 0;
  String _familyFinancialStatus = 'Middle Class';
  String _familyType = 'Nuclear Family';
  String _familyValues = 'Moderate';

  // 3. Astro details
  String _motherTongue = 'Bengali';
  String _manglik = 'Non-Manglik';
  final TextEditingController _gothraController = TextEditingController();
  final TextEditingController _timeOfBirthController = TextEditingController();
  final TextEditingController _cityOfBirthController = TextEditingController();

  // 4. Lifestyle / Physical
  String _diet = 'Vegetarian';
  String _bloodGroup = 'B+';
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _healthInfoController = TextEditingController();
  final TextEditingController _grewUpInController = TextEditingController();

  // 5. Education & Career
  String _workingWith = 'Private Company';
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  String _annualIncome = 'Rs. 10 - 15 Lakh';

  // 6. Location & Residency
  String _residencyStatus = 'Citizen';
  final TextEditingController _policeStController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  final List<String> _motherTongues = [
    'Bengali', 'Hindi', 'Urdu', 'English', 'Odia', 'Assamese',
    'Telugu', 'Tamil', 'Marathi', 'Gujarati', 'Punjabi', 'Malayalam'
  ];

  final List<String> _manglikOptions = [
    'Non-Manglik', 'Manglik', 'Anshik Manglik', "Don't Know"
  ];

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  final List<String> _financialStatuses = [
    'Rich / Affluent', 'Upper Middle Class', 'Middle Class', 'Modest'
  ];

  final List<String> _familyTypes = [
    'Nuclear Family', 'Joint Family'
  ];

  final List<String> _familyValuesList = [
    'Traditional', 'Moderate', 'Liberal'
  ];

  final List<String> _diets = [
    'Vegetarian', 'Non-Vegetarian', 'Eggetarian', 'Jain', 'Vegan'
  ];

  final List<String> _workingSectors = [
    'Private Company', 'Government / Public Sector', 'Business / Self Employed',
    'Defense / Civil Services', 'Not Working'
  ];

  final List<String> _incomes = [
    'Rs. 0 - 3 Lakh', 'Rs. 3 - 6 Lakh', 'Rs. 6 - 10 Lakh', 'Rs. 10 - 15 Lakh',
    'Rs. 15 - 25 Lakh', 'Rs. 25 - 50 Lakh', 'Rs. 50 Lakh - 1 Crore', 'Rs. 1 Crore & above'
  ];

  final List<String> _residencyTypes = [
    'Citizen', 'Permanent Resident', 'Work Permit', 'Student Visa', 'Temporary Visa'
  ];

  @override
  void initState() {
    super.initState();
    _prefillCandidateData();
  }

  void _prefillCandidateData() {
    final c = ApiService.instance.candidate;
    if (c == null) return;

    if (c['about_yourself'] != null) _aboutMeController.text = c['about_yourself'];
    if (c['father_profession'] != null) _fatherProfessionController.text = c['father_profession'];
    if (c['mother_profession'] != null) _motherProfessionController.text = c['mother_profession'];
    if (c['family_location'] != null) _familyLocationController.text = c['family_location'];
    if (c['brothers_count'] != null) _brothersCount = int.tryParse(c['brothers_count'].toString()) ?? 0;
    if (c['sisters_count'] != null) _sistersCount = int.tryParse(c['sisters_count'].toString()) ?? 0;
    if (c['family_financial_status'] != null && _financialStatuses.contains(c['family_financial_status'])) {
      _familyFinancialStatus = c['family_financial_status'];
    }
    if (c['family_type'] != null && _familyTypes.contains(c['family_type'])) {
      _familyType = c['family_type'];
    }
    if (c['family_values'] != null && _familyValuesList.contains(c['family_values'])) {
      _familyValues = c['family_values'];
    }

    if (c['mother_tongue'] != null && _motherTongues.contains(c['mother_tongue'])) {
      _motherTongue = c['mother_tongue'];
    }
    if (c['manglik'] != null && _manglikOptions.contains(c['manglik'])) {
      _manglik = c['manglik'];
    }
    if (c['gothra'] != null) _gothraController.text = c['gothra'];
    if (c['time_of_birth'] != null) _timeOfBirthController.text = c['time_of_birth'];
    if (c['city_of_birth'] != null) _cityOfBirthController.text = c['city_of_birth'];

    if (c['diet'] != null && _diets.contains(c['diet'])) _diet = c['diet'];
    if (c['blood_group'] != null && _bloodGroups.contains(c['blood_group'])) _bloodGroup = c['blood_group'];
    if (c['weight'] != null) _weightController.text = c['weight'].toString();
    if (c['health_info'] != null) _healthInfoController.text = c['health_info'];
    if (c['grew_up_in'] != null) _grewUpInController.text = c['grew_up_in'];

    if (c['working_with'] != null && _workingSectors.contains(c['working_with'])) _workingWith = c['working_with'];
    if (c['designation'] != null) _designationController.text = c['designation'];
    if (c['company_name'] != null) _companyNameController.text = c['company_name'];
    if (c['annual_income'] != null && _incomes.contains(c['annual_income'])) _annualIncome = c['annual_income'];

    if (c['residency_status'] != null && _residencyTypes.contains(c['residency_status'])) {
      _residencyStatus = c['residency_status'];
    }
    if (c['police_st'] != null) _policeStController.text = c['police_st'];
    if (c['pincode'] != null) _pincodeController.text = c['pincode'];
  }

  @override
  void dispose() {
    _aboutMeController.dispose();
    _fatherProfessionController.dispose();
    _motherProfessionController.dispose();
    _familyLocationController.dispose();
    _gothraController.dispose();
    _timeOfBirthController.dispose();
    _cityOfBirthController.dispose();
    _weightController.dispose();
    _healthInfoController.dispose();
    _grewUpInController.dispose();
    _designationController.dispose();
    _companyNameController.dispose();
    _policeStController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _skipToVerification() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RaniAadhaarVerificationScreen(
          prefilledAadhar: widget.initialAadhar,
        ),
      ),
    );
  }

  Future<void> _submitProfileDetails() async {
    setState(() => _isSaving = true);

    final payload = {
      // 1. Bio
      'about_yourself': _aboutMeController.text.trim(),

      // 2. Family
      'father_profession': _fatherProfessionController.text.trim(),
      'mother_profession': _motherProfessionController.text.trim(),
      'family_location': _familyLocationController.text.trim(),
      'brothers_count': _brothersCount,
      'sisters_count': _sistersCount,
      'family_financial_status': _familyFinancialStatus,
      'family_type': _familyType,
      'family_values': _familyValues,

      // 3. Astro
      'mother_tongue': _motherTongue,
      'manglik': _manglik,
      'gothra': _gothraController.text.trim(),
      'time_of_birth': _timeOfBirthController.text.trim(),
      'city_of_birth': _cityOfBirthController.text.trim(),

      // 4. Lifestyle & Health
      'diet': _diet,
      'blood_group': _bloodGroup,
      'weight': _weightController.text.trim(),
      'health_info': _healthInfoController.text.trim(),
      'grew_up_in': _grewUpInController.text.trim(),

      // 5. Career & Income
      'working_with': _workingWith,
      'designation': _designationController.text.trim(),
      'company_name': _companyNameController.text.trim(),
      'annual_income': _annualIncome,

      // 6. Location & Residency
      'residency_status': _residencyStatus,
      'police_st': _policeStController.text.trim(),
      'pincode': _pincodeController.text.trim(),
    };

    try {
      final res = await ApiService.instance.updateProfile('extended', payload);
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (res['success'] == true) {
        RaniAlert.success(
          context,
          'Profile details saved! Proceeding to document verification.',
          title: 'Details Saved',
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RaniAadhaarVerificationScreen(
            prefilledAadhar: widget.initialAadhar,
          ),
        ),
      );
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
          'Candidate Details',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2B0A0D),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _skipToVerification,
            child: Text(
              'Skip',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF750000),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8DFD5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF750000).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.sparkles, color: Color(0xFF750000), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Website Profile Details',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2B0A0D),
                          ),
                        ),
                        Text(
                          'Fill in all your profile details to maximize compatibility & match score.',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF6B6B6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: About Yourself / Bio
                    _buildSectionHeader(
                      icon: CupertinoIcons.chat_bubble_text_fill,
                      title: 'About Yourself & Partner Preferences',
                      stepNumber: '01',
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildTextArea(
                          controller: _aboutMeController,
                          label: 'About Yourself',
                          hint: 'Describe your personality, passions, lifestyle, and what you are looking for in an ideal partner...',
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Section 2: Family Background
                    _buildSectionHeader(
                      icon: CupertinoIcons.person_3_fill,
                      title: 'Family Background',
                      stepNumber: '02',
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildTextField(
                          controller: _fatherProfessionController,
                          label: "Father's Profession / Occupation",
                          hint: 'e.g. Business Owner, Retired, Govt Service',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _motherProfessionController,
                          label: "Mother's Profession / Occupation",
                          hint: 'e.g. Homemaker, Teacher, Govt Employee',
                        ),
                        const SizedBox(height: 14),
                        // Siblings Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildCounterField(
                                label: 'Brothers',
                                count: _brothersCount,
                                onDecrement: () {
                                  if (_brothersCount > 0) setState(() => _brothersCount--);
                                },
                                onIncrement: () {
                                  setState(() => _brothersCount++);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildCounterField(
                                label: 'Sisters',
                                count: _sistersCount,
                                onDecrement: () {
                                  if (_sistersCount > 0) setState(() => _sistersCount--);
                                },
                                onIncrement: () {
                                  setState(() => _sistersCount++);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildDropdownField(
                          label: 'Family Financial Status',
                          value: _familyFinancialStatus,
                          items: _financialStatuses,
                          onChanged: (v) => setState(() => _familyFinancialStatus = v!),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Family Type',
                                value: _familyType,
                                items: _familyTypes,
                                onChanged: (v) => setState(() => _familyType = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Family Values',
                                value: _familyValues,
                                items: _familyValuesList,
                                onChanged: (v) => setState(() => _familyValues = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _familyLocationController,
                          label: 'Family Location / Native City',
                          hint: 'e.g. Midnapore, West Bengal',
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Section 3: Astro & Kundli
                    _buildSectionHeader(
                      icon: CupertinoIcons.moon_stars_fill,
                      title: 'Horoscope & Astro Details',
                      stepNumber: '03',
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildDropdownField(
                          label: 'Mother Tongue',
                          value: _motherTongue,
                          items: _motherTongues,
                          onChanged: (v) => setState(() => _motherTongue = v!),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownField(
                          label: 'Manglik Status',
                          value: _manglik,
                          items: _manglikOptions,
                          onChanged: (v) => setState(() => _manglik = v!),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _gothraController,
                          label: 'Gothra (Optional)',
                          hint: 'e.g. Kashyap, Shandilya, Bharadwaj',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _timeOfBirthController,
                                label: 'Time of Birth (Optional)',
                                hint: 'e.g. 10:30 AM',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _cityOfBirthController,
                                label: 'City of Birth',
                                hint: 'e.g. Kolkata',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Section 4: Physical & Lifestyle
                    _buildSectionHeader(
                      icon: CupertinoIcons.heart_fill,
                      title: 'Lifestyle, Diet & Health',
                      stepNumber: '04',
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Diet',
                                value: _diet,
                                items: _diets,
                                onChanged: (v) => setState(() => _diet = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Blood Group',
                                value: _bloodGroup,
                                items: _bloodGroups,
                                onChanged: (v) => setState(() => _bloodGroup = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _weightController,
                                label: 'Weight (kg)',
                                hint: 'e.g. 58',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _grewUpInController,
                                label: 'Grew Up In',
                                hint: 'e.g. Durgapur',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _healthInfoController,
                          label: 'Health Information / Special Needs (Optional)',
                          hint: 'e.g. None (Normal)',
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Section 5: Education & Career Extras
                    _buildSectionHeader(
                      icon: CupertinoIcons.briefcase_fill,
                      title: 'Career & Employment Details',
                      stepNumber: '05',
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildDropdownField(
                          label: 'Working Sector',
                          value: _workingWith,
                          items: _workingSectors,
                          onChanged: (v) => setState(() => _workingWith = v!),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _designationController,
                          label: 'Designation / Role',
                          hint: 'e.g. Senior Software Engineer',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _companyNameController,
                          label: 'Employer / Company Name',
                          hint: 'e.g. Tata Consultancy Services',
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownField(
                          label: 'Annual Income',
                          value: _annualIncome,
                          items: _incomes,
                          onChanged: (v) => setState(() => _annualIncome = v!),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Section 6: Residency & Location Details
                    _buildSectionHeader(
                      icon: CupertinoIcons.location_solid,
                      title: 'Residency & Address Details',
                      stepNumber: '06',
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildDropdownField(
                          label: 'Residency Status',
                          value: _residencyStatus,
                          items: _residencyTypes,
                          onChanged: (v) => setState(() => _residencyStatus = v!),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _policeStController,
                                label: 'Police Station',
                                hint: 'e.g. Park Street',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _pincodeController,
                                label: 'Pincode',
                                hint: 'e.g. 700016',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    // Save & Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF750000),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isSaving ? null : _submitProfileDetails,
                        child: _isSaving
                            ? const CupertinoActivityIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Save & Continue to Verification',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(CupertinoIcons.arrow_right, size: 16),
                                ],
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
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String stepNumber,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF750000),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            stepNumber,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 16, color: const Color(0xFF750000)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2B0A0D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String hint,
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
          decoration: BoxDecoration(
            color: const Color(0xFFFBF8F4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDED5C9)),
          ),
          child: TextField(
            controller: controller,
            maxLines: 4,
            style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF1E1E1E)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF9E9E9E)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
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
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFFBF8F4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDED5C9)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF1E1E1E)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF9E9E9E)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
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
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF8F4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDED5C9)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(value) ? value : items.first,
              icon: const Icon(CupertinoIcons.chevron_down, size: 14, color: Color(0xFF750000)),
              style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF1E1E1E)),
              onChanged: onChanged,
              items: items.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(opt),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounterField({
    required String label,
    required int count,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
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
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF8F4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDED5C9)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: onDecrement,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(CupertinoIcons.minus_circle, size: 22, color: Color(0xFF750000)),
                ),
              ),
              Text(
                '$count',
                style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
              GestureDetector(
                onTap: onIncrement,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(CupertinoIcons.plus_circle, size: 22, color: Color(0xFF750000)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
