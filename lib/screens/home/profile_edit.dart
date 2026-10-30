import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_matrimonial_loader.dart';

/// Screen: Candidate Profile Edit Screen (matching website my_profile.blade.php)
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

  // 1. Basic Details
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String _gender = 'Female';
  String _maritalStatus = 'Never Married';
  String _religion = 'Hindu';
  String _community = 'General';
  String _motherTongue = 'Bengali';
  String _height = "5' 4\"";

  // 2. About Me
  final TextEditingController _aboutMeController = TextEditingController();

  // 3. Family Details
  final TextEditingController _fatherProfessionController = TextEditingController();
  final TextEditingController _motherProfessionController = TextEditingController();
  final TextEditingController _familyLocationController = TextEditingController();
  int _brothersCount = 0;
  int _sistersCount = 0;
  String _familyFinancialStatus = 'Middle Class';
  String _familyType = 'Nuclear Family';
  String _familyValues = 'Moderate';

  // 4. Astro Details
  String _manglik = 'Non-Manglik';
  final TextEditingController _gothraController = TextEditingController();
  final TextEditingController _timeOfBirthController = TextEditingController();
  final TextEditingController _cityOfBirthController = TextEditingController();

  // 5. Lifestyle
  String _diet = 'Vegetarian';
  String _bloodGroup = 'B+';
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _healthInfoController = TextEditingController();
  final TextEditingController _grewUpInController = TextEditingController();

  // 6. Education & Career
  String _highestQualification = 'Bachelor of Technology';
  final TextEditingController _collegeNameController = TextEditingController();
  String _workingWith = 'Private Company';
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  String _annualIncome = '₹ 5 - 10 Lakh';

  // 7. Location & Address
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _fullAddressController = TextEditingController();
  final TextEditingController _policeStController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  String _residencyStatus = 'Citizen';

  // Master Options
  final List<String> _genders = ['Male', 'Female'];
  final List<String> _maritalStatuses = ['Never Married', 'Divorced', 'Widowed', 'Awaiting Divorce'];
  final List<String> _religions = ['Hindu', 'Muslim', 'Christian', 'Sikh', 'Jain', 'Buddhist', 'Parsi', 'Jewish', 'Other'];
  final List<String> _motherTongues = ['Bengali', 'Hindi', 'English', 'Urdu', 'Odia', 'Assamese', 'Telugu', 'Tamil', 'Marathi', 'Gujarati', 'Punjabi', 'Malayalam', 'Kannada'];
  final List<String> _heights = [
    "4' 8\"", "4' 9\"", "4' 10\"", "4' 11\"", "5' 0\"", "5' 1\"", "5' 2\"", "5' 3\"",
    "5' 4\"", "5' 5\"", "5' 6\"", "5' 7\"", "5' 8\"", "5' 9\"", "5' 10\"", "5' 11\"",
    "6' 0\"", "6' 1\"", "6' 2\"", "6' 3\"", "6' 4\""
  ];
  final List<String> _diets = ['Vegetarian', 'Non-Vegetarian', 'Eggetarian', 'Jain', 'Vegan'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _manglikOptions = ['Non-Manglik', 'Manglik', 'Angshik Manglik', 'Don\'t Know'];
  final List<String> _financialStatuses = ['Middle Class', 'Upper Middle Class', 'Affluent', 'High Class'];
  final List<String> _familyTypes = ['Nuclear Family', 'Joint Family'];
  final List<String> _familyValuesList = ['Traditional', 'Moderate', 'Liberal'];
  final List<String> _workingSectors = ['Private Company', 'Government / PSU', 'Business / Self-Employed', 'Defense / Civil Services', 'Not Working'];
  final List<String> _incomes = [
    'No Income', 'Under ₹ 3 Lakh', '₹ 3 - 5 Lakh', '₹ 5 - 10 Lakh',
    '₹ 10 - 15 Lakh', '₹ 15 - 20 Lakh', '₹ 20 - 30 Lakh', '₹ 30 - 50 Lakh', '₹ 50 Lakh+'
  ];
  final List<String> _residencyTypes = ['Citizen', 'Permanent Resident', 'Work Permit', 'Student Visa'];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final candidate = widget.initialCandidate ?? ApiService.instance.candidate;
    if (candidate != null) {
      _populateFromMap(candidate);
      setState(() => _isLoading = false);
    }

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

  void _populateFromMap(Map<String, dynamic> c) {
    _firstNameController.text = c['first_name']?.toString() ?? '';
    _lastNameController.text = c['last_name']?.toString() ?? '';
    _dobController.text = c['dob']?.toString() ?? '';

    final g = c['gender']?.toString();
    if (g != null && _genders.any((x) => x.toLowerCase() == g.toLowerCase())) {
      _gender = _genders.firstWhere((x) => x.toLowerCase() == g.toLowerCase());
    }

    final m = c['marital_status']?.toString();
    if (m != null && _maritalStatuses.contains(m)) _maritalStatus = m;

    final r = c['religion']?.toString();
    if (r != null && _religions.contains(r)) _religion = r;

    _community = c['community']?.toString() ?? 'General';

    final mt = c['mother_tongue']?.toString();
    if (mt != null && _motherTongues.contains(mt)) _motherTongue = mt;

    final h = c['height']?.toString();
    if (h != null && _heights.contains(h)) _height = h;

    _aboutMeController.text = c['about_yourself']?.toString() ?? '';

    _fatherProfessionController.text = c['father_profession']?.toString() ?? '';
    _motherProfessionController.text = c['mother_profession']?.toString() ?? '';
    _familyLocationController.text = c['family_location']?.toString() ?? '';
    _brothersCount = int.tryParse(c['brothers_count']?.toString() ?? '0') ?? 0;
    _sistersCount = int.tryParse(c['sisters_count']?.toString() ?? '0') ?? 0;

    final fin = c['family_financial_status']?.toString();
    if (fin != null && _financialStatuses.contains(fin)) _familyFinancialStatus = fin;

    final ft = c['family_type']?.toString();
    if (ft != null && _familyTypes.contains(ft)) _familyType = ft;

    final fv = c['family_values']?.toString();
    if (fv != null && _familyValuesList.contains(fv)) _familyValues = fv;

    final mg = c['manglik']?.toString();
    if (mg != null && _manglikOptions.contains(mg)) _manglik = mg;

    _gothraController.text = c['gothra']?.toString() ?? '';
    _timeOfBirthController.text = c['time_of_birth']?.toString() ?? '';
    _cityOfBirthController.text = c['city_of_birth']?.toString() ?? '';

    final d = c['diet']?.toString();
    if (d != null && _diets.contains(d)) _diet = d;

    final bg = c['blood_group']?.toString();
    if (bg != null && _bloodGroups.contains(bg)) _bloodGroup = bg;

    _weightController.text = c['weight']?.toString() ?? '';
    _healthInfoController.text = c['health_info']?.toString() ?? '';
    _grewUpInController.text = c['grew_up_in']?.toString() ?? '';

    _highestQualification = c['highest_qualification']?.toString() ?? 'Bachelor of Technology';
    _collegeNameController.text = c['college_name']?.toString() ?? '';

    final ww = c['working_with']?.toString();
    if (ww != null && _workingSectors.contains(ww)) _workingWith = ww;

    _professionController.text = c['profession']?.toString() ?? '';
    _designationController.text = c['designation']?.toString() ?? '';
    _companyNameController.text = c['company_name']?.toString() ?? '';

    final inc = c['annual_income']?.toString();
    if (inc != null && _incomes.contains(inc)) _annualIncome = inc;

    _cityController.text = c['city']?.toString() ?? '';
    _stateController.text = c['state']?.toString() ?? '';
    _countryController.text = c['country']?.toString() ?? 'India';
    _fullAddressController.text = c['full_address']?.toString() ?? '';
    _policeStController.text = c['police_st']?.toString() ?? '';
    _pincodeController.text = c['pincode']?.toString() ?? '';

    final res = c['residency_status']?.toString();
    if (res != null && _residencyTypes.contains(res)) _residencyStatus = res;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
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
    _collegeNameController.dispose();
    _professionController.dispose();
    _designationController.dispose();
    _companyNameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
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

    final payload = {
      'first_name': fn,
      'last_name': _lastNameController.text.trim(),
      'dob': _dobController.text.trim(),
      'gender': _gender,
      'marital_status': _maritalStatus,
      'religion': _religion,
      'community': _community,
      'mother_tongue': _motherTongue,
      'height': _height,
      'about_yourself': _aboutMeController.text.trim(),
      'father_profession': _fatherProfessionController.text.trim(),
      'mother_profession': _motherProfessionController.text.trim(),
      'family_location': _familyLocationController.text.trim(),
      'brothers_count': _brothersCount.toString(),
      'sisters_count': _sistersCount.toString(),
      'family_financial_status': _familyFinancialStatus,
      'family_type': _familyType,
      'family_values': _familyValues,
      'manglik': _manglik,
      'gothra': _gothraController.text.trim(),
      'time_of_birth': _timeOfBirthController.text.trim(),
      'city_of_birth': _cityOfBirthController.text.trim(),
      'diet': _diet,
      'blood_group': _bloodGroup,
      'weight': _weightController.text.trim(),
      'health_info': _healthInfoController.text.trim(),
      'grew_up_in': _grewUpInController.text.trim(),
      'highest_qualification': _highestQualification,
      'college_name': _collegeNameController.text.trim(),
      'working_with': _workingWith,
      'profession': _professionController.text.trim(),
      'designation': _designationController.text.trim(),
      'company_name': _companyNameController.text.trim(),
      'annual_income': _annualIncome,
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'country': _countryController.text.trim(),
      'full_address': _fullAddressController.text.trim(),
      'police_st': _policeStController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'residency_status': _residencyStatus,
    };

    try {
      final res = await ApiService.instance.updateProfile('all', payload);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      setState(() => _isSaving = false);

      if (mounted) {
        if (res['success'] == true) {
          RaniAlert.success(context, 'Profile updated successfully!');
          Navigator.pop(context, true);
        } else {
          RaniAlert.error(context, res['message'] ?? 'Failed to update profile.');
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
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Marital Status',
                      value: _maritalStatus,
                      items: _maritalStatuses,
                      onChanged: (v) => setState(() => _maritalStatus = v!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Religion',
                      value: _religion,
                      items: _religions,
                      onChanged: (v) => setState(() => _religion = v!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Mother Tongue',
                      value: _motherTongue,
                      items: _motherTongues,
                      onChanged: (v) => setState(() => _motherTongue = v!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Height',
                      value: _height,
                      items: _heights,
                      onChanged: (v) => setState(() => _height = v!),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. About Myself
                _buildCardSection(
                  title: 'About Myself',
                  icon: CupertinoIcons.doc_text_fill,
                  children: [
                    _buildTextField(
                      label: 'Express yourself in a few words',
                      controller: _aboutMeController,
                      maxLines: 4,
                      hint: 'Describe your personality, hobbies, background and what partner you are seeking...',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. Education & Career
                _buildCardSection(
                  title: 'Education & Career',
                  icon: CupertinoIcons.briefcase_fill,
                  children: [
                    _buildTextField(label: 'Highest Qualification', controller: TextEditingController(text: _highestQualification)),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'College / Institute Name', controller: _collegeNameController),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Working With',
                      value: _workingWith,
                      items: _workingSectors,
                      onChanged: (v) => setState(() => _workingWith = v!),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Profession', controller: _professionController, hint: 'Software Engineer, Doctor, etc.'),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Designation', controller: _designationController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Company Name', controller: _companyNameController),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Annual Income',
                      value: _annualIncome,
                      items: _incomes,
                      onChanged: (v) => setState(() => _annualIncome = v!),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 4. Family Background
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
                      onChanged: (v) => setState(() => _familyFinancialStatus = v!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Family Type',
                      value: _familyType,
                      items: _familyTypes,
                      onChanged: (v) => setState(() => _familyType = v!),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 5. Horoscope & Astro
                _buildCardSection(
                  title: 'Horoscope & Astro',
                  icon: CupertinoIcons.sparkles,
                  children: [
                    _buildDropdown(
                      label: 'Manglik Status',
                      value: _manglik,
                      items: _manglikOptions,
                      onChanged: (v) => setState(() => _manglik = v!),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Gothra', controller: _gothraController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Time of Birth', controller: _timeOfBirthController, hint: '10:30 AM'),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'City of Birth', controller: _cityOfBirthController),
                  ],
                ),

                const SizedBox(height: 16),

                // 6. Lifestyle & Health
                _buildCardSection(
                  title: 'Lifestyle & Health',
                  icon: CupertinoIcons.heart_fill,
                  children: [
                    _buildDropdown(
                      label: 'Diet Preference',
                      value: _diet,
                      items: _diets,
                      onChanged: (v) => setState(() => _diet = v!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Blood Group',
                      value: _bloodGroup,
                      items: _bloodGroups,
                      onChanged: (v) => setState(() => _bloodGroup = v!),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Weight (kg)', controller: _weightController, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Grew Up In', controller: _grewUpInController, hint: 'Kolkata, Mumbai, etc.'),
                  ],
                ),

                const SizedBox(height: 16),

                // 7. Location & Address
                _buildCardSection(
                  title: 'Location & Address',
                  icon: CupertinoIcons.location_solid,
                  children: [
                    _buildTextField(label: 'City', controller: _cityController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'State', controller: _stateController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Country', controller: _countryController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Full Residential Address', controller: _fullAddressController, maxLines: 2),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Police Station', controller: _policeStController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Pincode', controller: _pincodeController, keyboardType: TextInputType.number),
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8DFD5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              icon: const Icon(CupertinoIcons.chevron_down, size: 16, color: Color(0xFF750000)),
              style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF1E1E1E)),
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
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
