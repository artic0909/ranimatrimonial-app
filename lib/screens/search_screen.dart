import 'package:flutter/material.dart';
import '../theme/rani_colors.dart';
import '../theme/rani_spacing.dart';
import '../theme/rani_typography.dart';
import '../components/rani_buttons.dart';

/// Screen 5: Search & Filter Screen
/// Directly from the design reference:
/// - "Search Profiles"
/// - Segmented Tabs (Basic, Lifestyle, Background)
/// - "Looking for" (Bride, Groom, Any)
/// - "Age Range" slider (25 - 30)
/// - "Location" dropdown
/// - "Profession" dropdown
/// - "Religion" dropdown
/// - "Search" primary button & "Reset" button
class RaniSearchScreen extends StatefulWidget {
  const RaniSearchScreen({super.key});

  @override
  State<RaniSearchScreen> createState() => _RaniSearchScreenState();
}

class _RaniSearchScreenState extends State<RaniSearchScreen> {
  String _selectedTab = 'Basic';
  String _lookingFor = 'Groom';
  RangeValues _ageRange = const RangeValues(25, 30);
  String _location = 'Kolkata, West Bengal';
  String _profession = 'Software Engineer';
  String _religion = 'Hindu';

  final List<String> _tabs = const ['Basic', 'Lifestyle', 'Background'];
  final List<String> _lookingForOptions = const ['Bride', 'Groom', 'Any'];

  final List<String> _locations = const [
    'Kolkata, West Bengal',
    'Mumbai, Maharashtra',
    'New Delhi, Delhi',
    'Bangalore, Karnataka',
    'Hyderabad, Telangana',
    'Chennai, Tamil Nadu',
    'Jaipur, Rajasthan',
  ];

  final List<String> _professions = const [
    'Software Engineer',
    'Doctor',
    'Investment Banker',
    'Civil Services Officer',
    'Chartered Accountant',
    'Architect',
    'Business / Entrepreneur',
  ];

  final List<String> _religions = const [
    'Hindu',
    'Muslim',
    'Sikh',
    'Christian',
    'Jain',
    'Buddhist',
    'Parsi',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RaniColors.canvas,
      appBar: AppBar(
        backgroundColor: RaniColors.surfaceAlt,
        elevation: 0,
        title: Text(
          'Search Profiles',
          style: RaniTypography.headingSm(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: RaniSpacing.screenPadding,
          vertical: RaniSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Tabs: Basic, Lifestyle, Background
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: RaniSpacing.roundedFull,
                border: Border.all(color: RaniColors.neutral),
              ),
              child: Row(
                children: _tabs.map((tab) {
                  final isSelected = _selectedTab == tab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTab = tab;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? RaniColors.primary : Colors.transparent,
                          borderRadius: RaniSpacing.roundedFull,
                        ),
                        child: Text(
                          tab,
                          textAlign: TextAlign.center,
                          style: isSelected
                              ? RaniTypography.button(color: Colors.white)
                              : RaniTypography.button(color: RaniColors.textMuted),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: RaniSpacing.xl),

            // Looking For section
            Text(
              'Looking for',
              style: RaniTypography.labelMd(color: RaniColors.ink).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: RaniSpacing.xs),
            Row(
              children: _lookingForOptions.map((opt) {
                final isSelected = _lookingFor == opt;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _lookingFor = opt;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? RaniColors.primary : Colors.white,
                          borderRadius: RaniSpacing.roundedFull,
                          border: Border.all(
                            color: isSelected ? RaniColors.primary : RaniColors.neutral,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          opt,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : RaniColors.ink,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: RaniSpacing.xl),

            // Age Range section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Age Range',
                  style: RaniTypography.labelMd(color: RaniColors.ink).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_ageRange.start.round()} - ${_ageRange.end.round()}',
                  style: RaniTypography.labelSm(color: RaniColors.primary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: _ageRange,
              min: 21,
              max: 60,
              divisions: 39,
              activeColor: RaniColors.primary,
              inactiveColor: RaniColors.neutral,
              onChanged: (values) {
                setState(() {
                  _ageRange = values;
                });
              },
            ),

            const SizedBox(height: RaniSpacing.lg),

            // Location dropdown
            Text(
              'Location',
              style: RaniTypography.labelMd(color: RaniColors.ink).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: RaniSpacing.xs),
            _buildDropdown(
              value: _location,
              items: _locations,
              onChanged: (val) {
                if (val != null) setState(() => _location = val);
              },
            ),

            const SizedBox(height: RaniSpacing.lg),

            // Profession dropdown
            Text(
              'Profession',
              style: RaniTypography.labelMd(color: RaniColors.ink).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: RaniSpacing.xs),
            _buildDropdown(
              value: _profession,
              items: _professions,
              onChanged: (val) {
                if (val != null) setState(() => _profession = val);
              },
            ),

            const SizedBox(height: RaniSpacing.lg),

            // Religion dropdown
            Text(
              'Religion',
              style: RaniTypography.labelMd(color: RaniColors.ink).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: RaniSpacing.xs),
            _buildDropdown(
              value: _religion,
              items: _religions,
              onChanged: (val) {
                if (val != null) setState(() => _religion = val);
              },
            ),

            const SizedBox(height: RaniSpacing.xxl),

            // Search button
            SizedBox(
              width: double.infinity,
              child: RaniPrimaryButton(
                text: 'Search',
                icon: const Icon(Icons.search, size: 18, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Found 142 matches in $_location for $_profession',
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: RaniSpacing.sm),

            // Reset button
            Center(
              child: RaniTextButton(
                text: 'Reset',
                onPressed: () {
                  setState(() {
                    _ageRange = const RangeValues(25, 30);
                    _lookingFor = 'Groom';
                    _location = 'Kolkata, West Bengal';
                    _profession = 'Software Engineer';
                    _religion = 'Hindu';
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: RaniSpacing.roundedMd,
        border: Border.all(color: RaniColors.neutral, width: 1.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: RaniColors.textMuted),
          style: RaniTypography.bodySm(color: RaniColors.ink),
          dropdownColor: Colors.white,
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }
}
