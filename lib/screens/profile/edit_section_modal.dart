import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Master Dropdown Options matching website and mobile register options
  static const List<String> _maritalStatuses = [
    'Never Married',
    'Divorced',
    'Widowed',
    'Awaiting Divorce',
  ];

  static const List<String> _heights = [
    "4' 8\"", "4' 9\"", "4' 10\"", "4' 11\"", "5' 0\"", "5' 1\"", "5' 2\"", "5' 3\"",
    "5' 4\"", "5' 5\"", "5' 6\"", "5' 7\"", "5' 8\"", "5' 9\"", "5' 10\"", "5' 11\"",
    "6' 0\"", "6' 1\"", "6' 2\"", "6' 3\"", "6' 4\""
  ];

  static const List<String> _diets = [
    'Vegetarian',
    'Non-Vegetarian',
    'Eggetarian',
    'Jain',
    'Vegan',
  ];

  static const List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  static const List<String> _religions = [
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

  static const List<String> _workingSectors = [
    'Private Company',
    'Government / PSU',
    'Business / Self-Employed',
    'Defense / Civil Services',
    'Not Working',
  ];

  static const List<String> _incomes = [
    'No Income',
    'Under ₹ 3 Lakh',
    '₹ 3 - 5 Lakh',
    '₹ 5 - 10 Lakh',
    '₹ 10 - 15 Lakh',
    '₹ 15 - 20 Lakh',
    '₹ 20 - 30 Lakh',
    '₹ 30 - 50 Lakh',
    '₹ 50 Lakh+',
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
    'Show to all connected matches',
    'Show only after express interest accepted',
    'Keep hidden',
  ];

  // Controllers & Values
  // 1. About
  late final TextEditingController _aboutController;
  late final TextEditingController _hobbiesController;

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
  late final TextEditingController _communityController;
  late final TextEditingController _subCommunityController;
  String? _motherTongue;
  late final TextEditingController _gothraController;

  // 4. Astro
  String? _manglik;
  late final TextEditingController _timeOfBirthController;
  late final TextEditingController _cityOfBirthController;

  // 5. Education & Career
  late final TextEditingController _qualificationController;
  late final TextEditingController _collegeController;
  String? _workingWith;
  late final TextEditingController _professionController;
  late final TextEditingController _designationController;
  late final TextEditingController _companyController;
  String? _annualIncome;

  // 6. Location
  late final TextEditingController _countryController;
  late final TextEditingController _stateController;
  late final TextEditingController _cityController;
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
    dynamic rawHobbies = c['hobbies_interests'];
    String hobbiesText = '';
    if (rawHobbies is List) {
      hobbiesText = rawHobbies.join(', ');
    } else if (rawHobbies != null) {
      hobbiesText = rawHobbies.toString();
    }
    _hobbiesController = TextEditingController(text: hobbiesText);

    // 2. Basics
    _maritalStatus = _findMatch(_maritalStatuses, c['marital_status']);
    _height = _findMatch(_heights, c['height']);
    _diet = _findMatch(_diets, c['diet']);
    _bloodGroup = _findMatch(_bloodGroups, c['blood_group']);
    _healthInfoController = TextEditingController(text: c['health_info']?.toString() ?? '');
    _grewUpInController = TextEditingController(text: c['grew_up_in']?.toString() ?? '');
    _disabilityController = TextEditingController(text: c['disability']?.toString() ?? 'None');

    // 3. Religious
    _religion = _findMatch(_religions, c['religion']);
    _communityController = TextEditingController(text: c['community']?.toString() ?? '');
    _subCommunityController = TextEditingController(text: c['sub_community']?.toString() ?? '');
    _motherTongue = _findMatch(_motherTongues, c['mother_tongue']);
    _gothraController = TextEditingController(text: c['gothra']?.toString() ?? '');

    // 4. Astro
    _manglik = _findMatch(_manglikOptions, c['manglik']);
    _timeOfBirthController = TextEditingController(text: c['time_of_birth']?.toString() ?? '');
    _cityOfBirthController = TextEditingController(text: c['city_of_birth']?.toString() ?? '');

    // 5. Education & Career
    _qualificationController = TextEditingController(text: c['highest_qualification']?.toString() ?? '');
    _collegeController = TextEditingController(text: c['college_name']?.toString() ?? '');
    _workingWith = _findMatch(_workingSectors, c['working_with']);
    _professionController = TextEditingController(text: c['profession']?.toString() ?? '');
    _designationController = TextEditingController(text: c['designation']?.toString() ?? '');
    _companyController = TextEditingController(text: c['company_name']?.toString() ?? '');
    _annualIncome = _findMatch(_incomes, c['annual_income']);

    // 6. Location
    _countryController = TextEditingController(text: c['country']?.toString() ?? 'India');
    _stateController = TextEditingController(text: c['state']?.toString() ?? '');
    _cityController = TextEditingController(text: c['city']?.toString() ?? '');
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

  @override
  void dispose() {
    _aboutController.dispose();
    _hobbiesController.dispose();
    _healthInfoController.dispose();
    _grewUpInController.dispose();
    _disabilityController.dispose();
    _communityController.dispose();
    _subCommunityController.dispose();
    _gothraController.dispose();
    _timeOfBirthController.dispose();
    _cityOfBirthController.dispose();
    _qualificationController.dispose();
    _collegeController.dispose();
    _professionController.dispose();
    _designationController.dispose();
    _companyController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _policeStController.dispose();
    _fullAddressController.dispose();
    _fatherProfessionController.dispose();
    _motherProfessionController.dispose();
    _familyLocationController.dispose();
    super.dispose();
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
          'hobbies_interests': _hobbiesController.text.trim(),
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
          'community': _communityController.text.trim(),
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
          'highest_qualification': _qualificationController.text.trim(),
          'college_name': _collegeController.text.trim(),
          if (_workingWith != null) 'working_with': _workingWith,
          'profession': _professionController.text.trim(),
          'designation': _designationController.text.trim(),
          'company_name': _companyController.text.trim(),
          if (_annualIncome != null) 'annual_income': _annualIncome,
        };

      case ProfileSection.location:
        return {
          'country': _countryController.text.trim(),
          'state': _stateController.text.trim(),
          'city': _cityController.text.trim(),
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
            const SizedBox(height: 16),
            _buildFieldLabel('Hobbies & Interests (comma-separated)'),
            _buildTextField(
              controller: _hobbiesController,
              hint: 'e.g. Reading, Traveling, Cooking, Music',
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
              items: _maritalStatuses,
              hint: 'Select marital status',
              onChanged: (val) => setState(() => _maritalStatus = val),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Height'),
            _buildDropdownField(
              value: _height,
              items: _heights,
              hint: 'Select height',
              onChanged: (val) => setState(() => _height = val),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Diet'),
            _buildDropdownField(
              value: _diet,
              items: _diets,
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
              items: _religions,
              hint: 'Select religion',
              onChanged: (val) => setState(() => _religion = val),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Community (Caste)'),
            _buildTextField(
              controller: _communityController,
              hint: 'e.g. Brahmin, Kayastha, Sunri, etc.',
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
            _buildTextField(
              controller: _qualificationController,
              hint: 'e.g. B.Tech, M.Tech, MBA, MBBS, B.Com',
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
              items: _workingSectors,
              hint: 'Select working sector',
              onChanged: (val) => setState(() => _workingWith = val),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Profession'),
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
              items: _incomes,
              hint: 'Select annual income',
              onChanged: (val) => setState(() => _annualIncome = val),
            ),
          ],
        );

      case ProfileSection.location:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Country'),
            _buildTextField(
              controller: _countryController,
              hint: 'e.g. India',
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('State'),
            _buildTextField(
              controller: _stateController,
              hint: 'e.g. West Bengal',
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('City'),
            _buildTextField(
              controller: _cityController,
              hint: 'e.g. Kolkata',
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
        style: GoogleFonts.outfit(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E1E1E),
        ),
        decoration: InputDecoration(
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
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFE8DE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          hint: Text(
            hint,
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF9E9E9E)),
          ),
          icon: const Icon(CupertinoIcons.chevron_down, size: 16, color: Color(0xFF750000)),
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

