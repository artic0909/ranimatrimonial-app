import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../components/rani_alert.dart';
import '../components/rani_skeleton_loader.dart';
import 'profile_detail_screen.dart';
import 'search_screen.dart';

/// Screen: Home Screen with ultra-modern UI & Candidate Name Header
/// Replaces "RANI MATRIMONIAL" text with the logged-in candidate's actual name & avatar.
/// Uses modern Cupertino / Lucide-style icons and clean layout matching user specification.
class RaniHomeScreen extends StatefulWidget {
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenFilter;
  final VoidCallback? onOpenProfile;
  final bool showCandidateHeader;

  const RaniHomeScreen({
    super.key,
    this.onOpenSearch,
    this.onOpenFilter,
    this.onOpenProfile,
    this.showCandidateHeader = true,
  });

  @override
  State<RaniHomeScreen> createState() => _RaniHomeScreenState();
}

class _RaniHomeScreenState extends State<RaniHomeScreen> {
  bool _isLoading = true;
  List<dynamic> _matches = [];
  String? _errorMessage;

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  String _selectedAge = 'All';
  String _selectedReligion = 'All';
  String _selectedEducation = 'All';
  String _selectedLocation = 'All';

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches({String? keyword}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Ensure candidate profile data is loaded
      if (ApiService.instance.candidate == null) {
        await ApiService.instance.getMyProfile();
      }

      Map<String, dynamic> res;
      if (keyword != null && keyword.trim().isNotEmpty) {
        res = await ApiService.instance.searchProfiles({
          'keyword': keyword.trim(),
          'religion': _selectedReligion == 'All' ? 'all' : _selectedReligion,
          'city': _selectedLocation == 'All' ? 'all' : _selectedLocation,
        });
        if (mounted && res['success'] == true) {
          setState(() {
            _matches = res['candidates'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }

      res = await ApiService.instance.getMatches(tab: 'all');
      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _matches = res['matches'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = res['message'] ?? 'Unable to load candidate profiles.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network connection error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleShortlist(String profileId, String name, int index) async {
    try {
      final res = await ApiService.instance.toggleShortlist(profileId);
      if (!mounted) return;

      if (res['success'] == true) {
        final isShortlisted = res['shortlisted'] == true;
        setState(() {
          _matches[index]['is_shortlisted'] = isShortlisted;
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Filter',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E0A0A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterOptionChip('All Religions', _selectedReligion == 'All', (val) {
                    setState(() => _selectedReligion = 'All');
                    Navigator.pop(ctx);
                    _loadMatches();
                  }),
                  _buildFilterOptionChip('Hindu', _selectedReligion == 'Hindu', (val) {
                    setState(() => _selectedReligion = 'Hindu');
                    Navigator.pop(ctx);
                    _loadMatches();
                  }),
                  _buildFilterOptionChip('Muslim', _selectedReligion == 'Muslim', (val) {
                    setState(() => _selectedReligion = 'Muslim');
                    Navigator.pop(ctx);
                    _loadMatches();
                  }),
                  _buildFilterOptionChip('Sikh', _selectedReligion == 'Sikh', (val) {
                    setState(() => _selectedReligion = 'Sikh');
                    Navigator.pop(ctx);
                    _loadMatches();
                  }),
                  _buildFilterOptionChip('Jain', _selectedReligion == 'Jain', (val) {
                    setState(() => _selectedReligion = 'Jain');
                    Navigator.pop(ctx);
                    _loadMatches();
                  }),
                  _buildFilterOptionChip('Christian', _selectedReligion == 'Christian', (val) {
                    setState(() => _selectedReligion = 'Christian');
                    Navigator.pop(ctx);
                    _loadMatches();
                  }),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF750000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
                    );
                  },
                  icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 18),
                  label: Text(
                    'Open Advanced Search',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOptionChip(String label, bool isSelected, ValueChanged<bool> onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF750000),
      backgroundColor: const Color(0xFFF7F2EB),
      labelStyle: GoogleFonts.outfit(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF333333),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? const Color(0xFF750000) : const Color(0xFFE5DDD5)),
      ),
    );
  }

  void _showAgePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final ageRanges = ['All', '18 - 25', '25 - 30', '30 - 35', '35 - 45', '45+'];
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Age Range',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...ageRanges.map((range) => ListTile(
                    title: Text(range, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    trailing: _selectedAge == range
                        ? const Icon(CupertinoIcons.checkmark_alt, color: Color(0xFF750000))
                        : null,
                    onTap: () {
                      setState(() => _selectedAge = range);
                      Navigator.pop(ctx);
                      _loadMatches();
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showEducationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = ['All', 'Graduate', 'Post Graduate', 'Doctorate', 'Engineering', 'Medical', 'Management'];
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Education',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) => ListTile(
                    title: Text(opt, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    trailing: _selectedEducation == opt
                        ? const Icon(CupertinoIcons.checkmark_alt, color: Color(0xFF750000))
                        : null,
                    onTap: () {
                      setState(() => _selectedEducation = opt);
                      Navigator.pop(ctx);
                      _loadMatches();
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = ['All', 'Kolkata', 'Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Pune'];
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select City / Location',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) => ListTile(
                    title: Text(opt, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    trailing: _selectedLocation == opt
                        ? const Icon(CupertinoIcons.checkmark_alt, color: Color(0xFF750000))
                        : null,
                    onTap: () {
                      setState(() => _selectedLocation = opt);
                      Navigator.pop(ctx);
                      _loadMatches();
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF750000),
          onRefresh: _loadMatches,
          child: CustomScrollView(
            slivers: [
              // 1. Top Header with Candidate Name & Modern Icons (Replaces RANI MATRIMONIAL text)
              if (widget.showCandidateHeader)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _buildCandidateHeader(),
                  ),
                ),

              // 2. Modern Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8DFD5), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.025),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF1E1E1E)),
                      decoration: InputDecoration(
                        hintText: 'Search by name, city, profession...',
                        hintStyle: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF8E8E8E),
                        ),
                        prefixIcon: const Icon(
                          CupertinoIcons.search,
                          color: Color(0xFF757575),
                          size: 19,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadMatches();
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (val) => _loadMatches(keyword: val),
                    ),
                  ),
                ),
              ),

              // 3. Modern Horizontal Filter Pills (Age v, Religion v, Education v, Location v)
              SliverToBoxAdapter(
                child: Container(
                  height: 38,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildPillChip('Age', _selectedAge, _showAgePicker),
                      const SizedBox(width: 8),
                      _buildPillChip('Religion', _selectedReligion, _showFilterBottomSheet),
                      const SizedBox(width: 8),
                      _buildPillChip('Education', _selectedEducation, _showEducationPicker),
                      const SizedBox(width: 8),
                      _buildPillChip('Location', _selectedLocation, _showLocationPicker),
                    ],
                  ),
                ),
              ),

              // 4. Matches Grid (2-Column Grid)
              _buildMatchesGrid(),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Header: Replaces "Rani Matrimonial" text with the candidate's actual name & avatar
  Widget _buildCandidateHeader() {
    final candidate = ApiService.instance.candidate;
    final firstName = candidate?['first_name'] ?? 'Candidate';
    final lastName = candidate?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final photo = candidate?['profile_picture'] ?? '';
    final code = candidate?['candidate_code'] ?? candidate?['profile_id'] ?? '';

    return Row(
      children: [
        // Candidate Avatar with gradient ring
        GestureDetector(
          onTap: () {
            if (widget.onOpenProfile != null) {
              widget.onOpenProfile!();
            }
          },
          child: Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4A034), Color(0xFF750000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF750000).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: photo.isNotEmpty
                      ? Image.network(
                          photo,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(firstName),
                        )
                      : _buildInitialsAvatar(firstName),
                ),
              ),
              // Modern online green indicator dot
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Candidate Name (Replaces Rani Matrimonial text)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Welcome,',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8C827A),
                    ),
                  ),
                  if (code.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EAE1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        code,
                        style: GoogleFonts.outfit(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF750000),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 1),
              Text(
                fullName.isNotEmpty ? fullName : 'Royal Candidate',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1E1E),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),

        // Modern Notification & Filter Action Buttons
        Row(
          children: [
            _buildModernHeaderAction(
              icon: CupertinoIcons.bell,
              hasBadge: true,
              onTap: () {
                RaniAlert.info(
                  context,
                  'You have no new notifications right now.',
                  title: 'Notifications',
                );
              },
            ),
            const SizedBox(width: 8),
            _buildModernHeaderAction(
              icon: CupertinoIcons.slider_horizontal_3,
              hasBadge: false,
              onTap: _showFilterBottomSheet,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'R';
    return Container(
      color: const Color(0xFFF5ECE0),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF750000),
        ),
      ),
    );
  }

  Widget _buildModernHeaderAction({
    required IconData icon,
    required bool hasBadge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8E0D5), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF2C2C2C)),
            if (hasBadge)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD32F2F),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillChip(String label, String value, VoidCallback onTap) {
    final hasValue = value != 'All';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: hasValue ? const Color(0xFFFBECEC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? const Color(0xFF750000) : const Color(0xFFE4DAD0),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasValue ? '$label: $value' : label,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                color: hasValue ? const Color(0xFF750000) : const Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_down,
              size: 11,
              color: hasValue ? const Color(0xFF750000) : const Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesGrid() {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: RaniSkeletonGrid(itemCount: 6),
      );
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: Color(0xFFD32F2F)),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF750000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _loadMatches,
                  icon: const Icon(CupertinoIcons.arrow_clockwise, size: 16),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_matches.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.heart, size: 54, color: Color(0xFF750000)),
                const SizedBox(height: 14),
                Text(
                  'No Profiles Found',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E0A0A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Try resetting your filters or search terms.',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2-Column Match Cards Grid
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 16,
          childAspectRatio: 0.62,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final candidate = _matches[index];
            return _buildMatchCard(candidate, index);
          },
          childCount: _matches.length,
        ),
      ),
    );
  }

  Widget _buildMatchCard(dynamic candidate, int index) {
    final profileId = candidate['id']?.toString() ?? '';
    final firstName = candidate['first_name'] ?? 'Candidate';
    final lastName = candidate['last_name'] ?? '';
    final displayName = lastName.isNotEmpty
        ? '$firstName ${lastName[0]}.'
        : firstName;

    final age = candidate['age'] ?? '26';
    final profession = candidate['profession'] ?? candidate['designation'] ?? 'Professional';
    final city = candidate['city'] ?? 'City';
    final state = candidate['state'] ?? 'State';
    final location = state.isNotEmpty ? '$city, $state' : city;

    final photo = candidate['photo'] ?? '';
    final isVerified = candidate['verified'] == true;
    final isShortlisted = candidate['is_shortlisted'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE8DE), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Photo with Heart Shortlist Icon & "✓ Verified profile" Pill
          Expanded(
            flex: 12,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  photo,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFF3ECE4),
                    child: const Center(
                      child: Icon(CupertinoIcons.person_fill, size: 48, color: Color(0xFF8B0000)),
                    ),
                  ),
                ),

                // Top Right Circular White Heart Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleShortlist(profileId, firstName, index),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isShortlisted ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                        size: 17,
                        color: const Color(0xFF750000),
                      ),
                    ),
                  ),
                ),

                // Bottom Left "✓ Verified profile" Pill (shown when candidate is verified)
                if (isVerified)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            size: 13,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verified profile',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Info Section (Name, Age, Profession, Location, View Profile button)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & Age Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                    Text(
                      '$age years',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF616161),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                // Profession
                Text(
                  profession,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF555555),
                  ),
                ),

                const SizedBox(height: 2),

                // Location
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: const Color(0xFF757575),
                  ),
                ),

                const SizedBox(height: 8),

                // Theme Burgundy "View Profile" Button with modern arrow
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF750000), // Theme Burgundy
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RaniProfileDetailScreen(
                            profileId: profileId,
                            initialProfileData: candidate,
                          ),
                        ),
                      ).then((_) => _loadMatches());
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Profile',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.chevron_right, size: 12, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
