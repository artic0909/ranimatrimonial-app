import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/rani_colors.dart';
import '../theme/rani_elevation.dart';
import '../theme/rani_spacing.dart';
import '../theme/rani_typography.dart';
import 'profile_detail_screen.dart';
import 'search_screen.dart';

/// Screen 3: Main Feed / Home Screen
/// Matches the design mockup:
/// - App bar with logo, filter icon, and favorites icon
/// - Rounded search bar: "Search by location, profession..."
/// - Filter tabs: Today's, Shortlisted, My Matches, Accepted
/// - "Featured Profiles" with "See All"
/// - 2-Column Profile Grid with photo, heart button, verified badge, name, profession & city
class RaniHomeScreen extends StatefulWidget {
  const RaniHomeScreen({super.key});

  @override
  State<RaniHomeScreen> createState() => _RaniHomeScreenState();
}

class _RaniHomeScreenState extends State<RaniHomeScreen> {
  String _selectedFilter = "Today's";

  final List<String> _filters = const [
    "Today's",
    'Shortlisted',
    'My Matches',
    'Accepted',
  ];

  final List<Map<String, dynamic>> _profiles = const [
    {
      'name': 'Anirban, 28',
      'profession': 'Software Engineer',
      'location': 'Kolkata, West Bengal',
      'image': 'assets/male/correct1.png',
      'isVerified': true,
      'height': '5\'11"',
      'religion': 'Hindu',
      'community': 'Bengali',
      'about':
          'Senior software engineer passionate about technology, music, and travel. Seeking an understanding partner who values family traditions.',
    },
    {
      'name': 'Priyanka, 26',
      'profession': 'Doctor',
      'location': 'Kolkata, West Bengal',
      'image': 'assets/bride.png',
      'isVerified': true,
      'height': '5\'4"',
      'religion': 'Hindu',
      'community': 'Bengali',
      'about':
          'I am a kind, family-oriented and ambitious person. Looking for a genuine life partner who values family, respect and mutual growth.',
    },
    {
      'name': 'Sneha, 25',
      'profession': 'Teacher',
      'location': 'Kolkata, West Bengal',
      'image': 'assets/female/correct1.png',
      'isVerified': true,
      'height': '5\'3"',
      'religion': 'Hindu',
      'community': 'Bengali',
      'about':
          'Educator who loves literature, arts, and creative learning. Seeking a caring companion with mutual respect.',
    },
    {
      'name': 'Rohan, 29',
      'profession': 'Investment Banker',
      'location': 'New Delhi, Delhi',
      'image': 'assets/groom.png',
      'isVerified': true,
      'height': '6\'0"',
      'religion': 'Hindu',
      'community': 'Punjabi',
      'about':
          'Finance professional based in Delhi. Enjoys sports, literature, and weekend getaways. Looking for someone genuine and grounded.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RaniColors.canvas,
      appBar: AppBar(
        backgroundColor: RaniColors.surfaceAlt,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.tune, color: RaniColors.cream, size: 22),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RaniSearchScreen(),
              ),
            );
          },
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 28,
                width: 28,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.favorite,
                  color: RaniColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rani',
                    style: RaniTypography.headingSm(color: Colors.white).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    'MATRIMONIAL',
                    style: RaniTypography.captionUppercase(color: RaniColors.gold).copyWith(
                      fontSize: 8,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: RaniColors.cream, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your saved favorites will appear here.'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: RaniSpacing.md),

            // Search Bar ("Search by location, profession...")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: RaniSpacing.screenPadding),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RaniSearchScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: RaniSpacing.roundedMd,
                    border: Border.all(
                      color: RaniColors.neutral,
                      width: 1.0,
                    ),
                    boxShadow: RaniElevation.sm,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: RaniColors.textMuted, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search by location, profession...',
                          style: RaniTypography.bodySm(color: RaniColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: RaniSpacing.md),

            // Filter Tabs row: Today's, Shortlisted, My Matches, Accepted
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: RaniSpacing.screenPadding),
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6B0000) : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filter,
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 14.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: RaniSpacing.lg),

            // "Featured Profiles" & "See All"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: RaniSpacing.screenPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Featured Profiles',
                      style: RaniTypography.headingMd(color: RaniColors.ink).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RaniSearchScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'See All',
                      style: RaniTypography.labelSm(color: RaniColors.primary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: RaniSpacing.sm),

            // 2-Column Profile Grid matching the mockup cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: RaniSpacing.screenPadding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final aspectRatio = screenWidth < 350
                      ? 0.60
                      : (screenWidth < 380 ? 0.65 : 0.68);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: aspectRatio,
                    ),
                    itemCount: _profiles.length,
                    itemBuilder: (context, index) {
                      final profile = _profiles[index];
                      return _ProfileFeedCard(
                        profile: profile,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RaniProfileDetailScreen(
                                profile: profile,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: RaniSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _ProfileFeedCard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onTap;

  const _ProfileFeedCard({
    required this.profile,
    required this.onTap,
  });

  @override
  State<_ProfileFeedCard> createState() => _ProfileFeedCardState();
}

class _ProfileFeedCardState extends State<_ProfileFeedCard> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final name = profile['name'] as String;
    final profession = profile['profession'] as String;
    final location = profile['location'] as String;
    final image = profile['image'] as String;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: RaniSpacing.roundedLg,
          border: Border.all(
            color: RaniColors.gold.withValues(alpha: 0.35),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo with Heart overlay
            Expanded(
              flex: 11,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    image,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: RaniColors.cream,
                      child: const Icon(Icons.person, color: RaniColors.gold, size: 48),
                    ),
                  ),
                  // Heart button on top-right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : RaniColors.primary,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Bottom Details
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: RaniTypography.labelMd(color: RaniColors.ink).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      profession,
                      style: RaniTypography.caption(color: RaniColors.textMuted).copyWith(
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      location,
                      style: RaniTypography.caption(color: RaniColors.textMuted).copyWith(
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}
