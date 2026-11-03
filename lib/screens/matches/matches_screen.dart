import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/razorpay_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_matrimonial_loader.dart';
import '../../components/rani_skeleton_loader.dart';
import '../../components/rani_top_bar.dart';
import 'details_screen.dart';
import '../search/search_screen.dart';

/// Screen: Matches Screen (Matches the exact UI of user's phone screenshot)
/// Features:
/// - Top bar: Hamburger/Menu, "Matches", Notification Bell
/// - Horizontal Filter Pills: Search, New (61), Daily (18), All Matches
/// - Immersive vertical profile match card:
///   - Candidate photo with photo counter badge ( 1) & 3-dot options
///   - Name, Age, Blue Tick verified badge (e.g. Sumaiya K, 26 ✔)
///   - Height • Religion/Caste • Profession (e.g. 5' 1" • Sunni • Teacher)
///   - Location (e.g. Midnapore, West Bengal)
///   - Activity badges:  20h ago,  You & Her
///   - Bottom Royal Action Bar: "Like this Profile? Connect Now" + Large Circular Green Checkmark Button
class RaniMatchesScreen extends StatefulWidget {
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenNotifications;
  final ValueChanged<int>? onMatchesCountChanged;
  final bool showAppBar;
  final String initialTab;

  const RaniMatchesScreen({
    super.key,
    this.onOpenSearch,
    this.onOpenNotifications,
    this.onMatchesCountChanged,
    this.showAppBar = true,
    this.initialTab = 'new',
  });

  @override
  State<RaniMatchesScreen> createState() => _RaniMatchesScreenState();
}

class _RaniMatchesScreenState extends State<RaniMatchesScreen> {
  late String _selectedTab; // 'new', 'near_me', 'accepted', 'shortlisted'
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 10;

  List<dynamic> _matches = []; // Currently displayed paginated items (10, then 20, 30...)
  List<dynamic> _cachedPool = []; // Full buffer pool if all data was fetched at once
  String? _errorMessage;
  int _newCount = 0;
  int _nearMeCount = 0;
  int _acceptedCount = 0;
  int _shortlistedCount = 0;

  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _fetchMatches();

    // Listen to PageView vertical scroll to load next 10 items
    _pageController.addListener(() {
      if (_pageController.hasClients && _pageController.page != null) {
        final currentPos = _pageController.page!.round();
        // Trigger load only when user arrives at the loading placeholder page (index == _matches.length)
        if (currentPos >= _matches.length && !_isLoadingMore && _hasMore) {
          _loadMoreMatches();
        }
      }
    });

    // Listen to ListView scroll for Accepted & Shortlisted tabs
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
          if (!_isLoadingMore && _hasMore) {
            _loadMoreMatches();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Check if candidate matches logged-in candidate's city or state (or both)
  bool _isNearMe(dynamic c, String myCity, String myState) {
    if (c == null || c is! Map) return false;
    final cCity = (c['city'] ?? c['district'] ?? '').toString().trim().toLowerCase();
    final cState = (c['state'] ?? '').toString().trim().toLowerCase();

    // 1. Check city match
    if (myCity.isNotEmpty && cCity.isNotEmpty) {
      if (cCity.contains(myCity) || myCity.contains(cCity)) return true;
    }

    // 2. Check state match
    if (myState.isNotEmpty && cState.isNotEmpty) {
      if (cState.contains(myState) || myState.contains(cState)) return true;
    }

    // 3. Fallback when logged-in profile has not set city/state (e.g. West Bengal / Kolkata default)
    if (myCity.isEmpty && myState.isEmpty) {
      if (cCity.contains('kolkata') || cState.contains('bengal') || cState.contains('west')) return true;
    }

    return false;
  }

  /// Initial load or reload of the first 10 candidate data items
  Future<void> _fetchMatches({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
      _cachedPool.clear();
      _matches.clear();
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String tabParam = 'todays';
      if (_selectedTab == 'near_me') {
        tabParam = 'near_me';
      } else if (_selectedTab == 'accepted') {
        tabParam = 'accepted';
      } else if (_selectedTab == 'shortlisted') {
        tabParam = 'shortlisted';
      }

      _currentPage = 1;
      var res = await ApiService.instance.getMatches(tab: tabParam, page: 1);
      if (!mounted) return;

      // If near_me API returned empty list or error, fallback to fetching all candidates and filtering locally:
      if (_selectedTab == 'near_me') {
        final rawMatches = res['matches'];
        final isEmptyList = (rawMatches is List && rawMatches.isEmpty) ||
            (rawMatches is Map && rawMatches['data'] is List && (rawMatches['data'] as List).isEmpty);
        if (res['success'] != true || isEmptyList) {
          final allRes = await ApiService.instance.getMatches(tab: 'all', page: 1);
          if (mounted && allRes['success'] == true) {
            res = allRes;
          }
        }
      }

      if (res['success'] == true) {
        List<dynamic> list = [];
        if (res['matches'] is List) {
          list = List.from(res['matches']);
        } else if (res['matches'] is Map && res['matches']['data'] is List) {
          list = List.from(res['matches']['data']);
          final lastPage = res['matches']['last_page'] ?? 1;
          _hasMore = 1 < lastPage;
        }

        final myCandidate = ApiService.instance.candidate;
        final myCity = (myCandidate?['city'] ?? myCandidate?['district'] ?? myCandidate?['present_city'] ?? '').toString().trim().toLowerCase();
        final myState = (myCandidate?['state'] ?? myCandidate?['present_state'] ?? '').toString().trim().toLowerCase();

        // Calculate Near Me count from full pool of matches
        final rawPool = res['matches'] is List
            ? List.from(res['matches'])
            : (res['matches'] is Map && res['matches']['data'] is List ? List.from(res['matches']['data']) : list);
        final nearMePool = rawPool.where((m) => m['is_shortlisted'] != true && _isNearMe(m, myCity, myState)).toList();
        _nearMeCount = nearMePool.length;

        // Strictly guarantee shortlisted candidates do NOT appear in the NEW and NEAR ME tabs
        if (_selectedTab == 'new') {
          list = list.where((m) => m['is_shortlisted'] != true).toList();
        } else if (_selectedTab == 'near_me') {
          // Strictly show candidates matching logged-in candidate's city or state (or both)
          list = list.where((m) => m['is_shortlisted'] != true && _isNearMe(m, myCity, myState)).toList();
        }

        final counts = res['counts'];
        _cachedPool = list;

        // Strictly show first 10 data items initially
        final initialBatch = list.take(_pageSize).toList();
        final totalCount = res['total'] is int
            ? res['total'] as int
            : (counts is Map && (counts['new'] ?? counts['todays']) is int
                ? (counts['new'] ?? counts['todays']) as int
                : list.length);
        final lastPage = res['last_page'] is int ? res['last_page'] as int : 1;
        _hasMore = res['has_more'] == true || totalCount > initialBatch.length || lastPage > 1 || list.length > _pageSize;

        setState(() {
          _matches = initialBatch;

          if (counts is Map) {
            final todays = counts['new'] ?? counts['todays'] ?? counts['my_matches'];
            if (todays != null) {
              _newCount = todays is int ? todays : int.tryParse('$todays') ?? _newCount;
            }
            if (_selectedTab == 'new' && list.length > _newCount) {
              _newCount = list.length;
            }

            final nearMe = counts['near_me'] ?? counts['nearme'];
            if (nearMe != null) {
              _nearMeCount = nearMe is int ? nearMe : int.tryParse('$nearMe') ?? _nearMeCount;
            }

            final accepted = counts['accepted'];
            if (accepted != null) {
              _acceptedCount = accepted is int ? accepted : int.tryParse('$accepted') ?? _acceptedCount;
            }

            final shortlisted = counts['shortlisted'];
            if (shortlisted != null) {
              _shortlistedCount = shortlisted is int ? shortlisted : int.tryParse('$shortlisted') ?? _shortlistedCount;
            }
          } else {
            if (_selectedTab == 'new') _newCount = list.length;
            if (_selectedTab == 'near_me') _nearMeCount = list.length;
            if (_selectedTab == 'accepted') _acceptedCount = list.length;
            if (_selectedTab == 'shortlisted') _shortlistedCount = list.length;
          }
          if (_newCount > 0) {
            widget.onMatchesCountChanged?.call(_newCount);
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Unable to load matches.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Load more 10 candidates when reaching near end of current list
  Future<void> _loadMoreMatches() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Visible delay so user clearly sees the animated indicator and skeleton shimmer before loading next 10 items
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      // 1. First check if we have more cached in _cachedPool
      if (_cachedPool.length > _matches.length) {
        final nextBatch = _cachedPool.skip(_matches.length).take(_pageSize).toList();
        if (nextBatch.isNotEmpty) {
          setState(() {
            _matches.addAll(nextBatch);
            _hasMore = _cachedPool.length > _matches.length;
            _isLoadingMore = false;
          });
          return;
        }
      }

      // 2. Fetch next page from API
      final nextPage = _currentPage + 1;
      String tabParam = 'todays';
      if (_selectedTab == 'near_me') {
        tabParam = 'near_me';
      } else if (_selectedTab == 'accepted') {
        tabParam = 'accepted';
      } else if (_selectedTab == 'shortlisted') {
        tabParam = 'shortlisted';
      }

      var res = await ApiService.instance.getMatches(tab: tabParam, page: nextPage);
      if (!mounted) return;

      if (_selectedTab == 'near_me') {
        final rawMatches = res['matches'];
        final isEmptyList = (rawMatches is List && rawMatches.isEmpty) ||
            (rawMatches is Map && rawMatches['data'] is List && (rawMatches['data'] as List).isEmpty);
        if (res['success'] != true || isEmptyList) {
          final allRes = await ApiService.instance.getMatches(tab: 'all', page: nextPage);
          if (mounted && allRes['success'] == true) {
            res = allRes;
          }
        }
      }

      if (res['success'] == true) {
        List<dynamic> nextList = [];
        if (res['matches'] is List) {
          nextList = List.from(res['matches']);
        } else if (res['matches'] is Map && res['matches']['data'] is List) {
          nextList = List.from(res['matches']['data']);
          final lastPage = res['matches']['last_page'] ?? nextPage;
          _hasMore = nextPage < lastPage;
        }

        if (_selectedTab == 'new') {
          nextList = nextList.where((m) => m['is_shortlisted'] != true).toList();
        } else if (_selectedTab == 'near_me') {
          final myCandidate = ApiService.instance.candidate;
          final myCity = (myCandidate?['city'] ?? myCandidate?['district'] ?? myCandidate?['present_city'] ?? '').toString().trim().toLowerCase();
          final myState = (myCandidate?['state'] ?? myCandidate?['present_state'] ?? '').toString().trim().toLowerCase();
          nextList = nextList.where((m) => m['is_shortlisted'] != true && _isNearMe(m, myCity, myState)).toList();
        }

        // Deduplicate
        final existingIds = _matches
            .map((m) => m['candidate_code'] ?? m['profile_id'] ?? m['id']?.toString())
            .toSet();
        final uniqueNew = nextList.where((m) {
          final mId = m['candidate_code'] ?? m['profile_id'] ?? m['id']?.toString();
          return !existingIds.contains(mId);
        }).take(_pageSize).toList();

        if (uniqueNew.isNotEmpty) {
          _currentPage = nextPage;
          setState(() {
            _matches.addAll(uniqueNew);
            _cachedPool.addAll(nextList);
            _isLoadingMore = false;
            _hasMore = uniqueNew.length >= _pageSize;
          });
        } else {
          setState(() {
            _isLoadingMore = false;
            _hasMore = false;
          });
        }
      } else {
        setState(() {
          _isLoadingMore = false;
          _hasMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _sendRoyalInterest(dynamic candidate) async {
    final candidateId = (candidate['candidate_code'] ?? candidate['profile_id'] ?? candidate['id']?.toString() ?? '').toString();
    final name = '${candidate['first_name'] ?? 'Candidate'}'.trim();

    RaniMatrimonialLoader.show(context, message: 'Sending connection request to $name...');

    try {
      final res = await ApiService.instance.sendInterest(candidateId);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        setState(() {
          candidate['request_type'] = 'sent';
          candidate['is_connected'] = true;
        });
        RaniAlert.success(
          context,
          res['message'] ?? 'Connection request sent to $name! You will be notified when accepted.',
          title: 'Connected! 🎉',
        );
      } else {
        if (res['insufficient_balance'] == true || (res['message'] != null && res['message'].toString().toLowerCase().contains('balance'))) {
          _showInsufficientBalanceDialog(candidate, res['message'] ?? 'Please recharge your wallet.');
        } else {
          RaniAlert.error(context, res['message'] ?? 'Could not send interest.');
        }
      }
    } catch (e) {
      if (mounted) {
        RaniMatrimonialLoader.hide(context);
        RaniAlert.error(context, 'Error: $e');
      }
    }
  }

  void _showInsufficientBalanceDialog(dynamic candidate, String message) {
    RaniRazorpayService.showRechargeModal(
      context: context,
      defaultAmount: 100,
      subtitle: message,
      onPaymentSuccess: (amount) {
        _sendRoyalInterest(candidate);
      },
    );
  }

  Future<void> _toggleShortlist(dynamic candidate) async {
    final profileId = candidate['candidate_code'] ?? candidate['profile_id'] ?? candidate['id']?.toString() ?? '';
    final name = '${candidate['first_name'] ?? 'Candidate'}'.trim();
    final isCurrentlyShortlisted = candidate['is_shortlisted'] == true;

    setState(() {
      candidate['is_shortlisted'] = !isCurrentlyShortlisted;
    });

    try {
      final res = await ApiService.instance.toggleShortlist(profileId);
      if (!mounted) return;

      if (res['success'] == true) {
        final isShortlisted = res['shortlisted'] == true;
        setState(() {
          candidate['is_shortlisted'] = isShortlisted;
          if (isShortlisted) {
            // Once shortlisted, remove from NEW or NEAR ME tab immediately
            if (_selectedTab == 'new' || _selectedTab == 'near_me') {
              _matches.removeWhere((m) {
                final mId = m['candidate_code'] ?? m['profile_id'] ?? m['id']?.toString();
                return mId == profileId || m == candidate;
              });
              if (_selectedTab == 'new' && _newCount > 0) _newCount--;
              if (_selectedTab == 'near_me' && _nearMeCount > 0) _nearMeCount--;
            }
            if (res['count'] is int) {
              _shortlistedCount = res['count'];
            } else {
              _shortlistedCount++;
            }
          } else {
            // When un-shortlisted from the Shortlisted tab, remove immediately
            if (_selectedTab == 'shortlisted') {
              _matches.removeWhere((m) {
                final mId = m['candidate_code'] ?? m['profile_id'] ?? m['id']?.toString();
                return mId == profileId || m == candidate;
              });
            }
            if (res['count'] is int) {
              _shortlistedCount = res['count'];
            } else {
              _shortlistedCount = _shortlistedCount > 0 ? _shortlistedCount - 1 : 0;
            }
          }
        });
        RaniAlert.success(
          context,
          isShortlisted ? '$name added to Shortlist!' : '$name removed from Shortlist.',
          title: isShortlisted ? 'Shortlisted' : 'Removed',
        );
      } else {
        setState(() {
          candidate['is_shortlisted'] = isCurrentlyShortlisted;
        });
        RaniAlert.error(context, res['message'] ?? 'Action failed.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          candidate['is_shortlisted'] = isCurrentlyShortlisted;
        });
        RaniAlert.error(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: widget.showAppBar
          ? RaniTopBar(
              title: 'Matches',
              notificationCount: 3,
              onNotificationPressed: widget.onOpenNotifications,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Tabs Row: Filter icon | (bar) NEW 61 Accepted 12 Shortlisted 8 (Theme styled)
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Filter icon (Theme Burgundy)
                  GestureDetector(
                    onTap: () {
                      if (widget.onOpenSearch != null) {
                        widget.onOpenSearch!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
                        );
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE8DFD5)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF750000).withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.slider_horizontal_3,
                        size: 18,
                        color: Color(0xFF750000), // Brand Royal Burgundy
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Vertical divider bar |
                  Center(
                    child: Container(
                      width: 1.5,
                      height: 22,
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.5), // Brand Gold tint
                    ),
                  ),

                  const SizedBox(width: 10),

                  // NEW
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedTab != 'new') {
                          setState(() => _selectedTab = 'new');
                          _fetchMatches(isRefresh: true);
                        }
                      },
                      child: _buildTabPill('New $_newCount', _selectedTab == 'new'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Near Me
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedTab != 'near_me') {
                          setState(() => _selectedTab = 'near_me');
                          _fetchMatches(isRefresh: true);
                        }
                      },
                      child: _buildTabPill('Near Me $_nearMeCount', _selectedTab == 'near_me'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Shortlisted
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedTab != 'shortlisted') {
                          setState(() => _selectedTab = 'shortlisted');
                          _fetchMatches(isRefresh: true);
                        }
                      },
                      child: _buildTabPill('Shortlisted $_shortlistedCount', _selectedTab == 'shortlisted'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Main Content: Full-image single card vertical PageView
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF8B0000), Color(0xFF6B0000)], // Royal Burgundy Theme
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF8B0000) : const Color(0xFFE8DFD5),
          width: 1.2,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF750000).withValues(alpha: 0.32),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF5A0812), // Theme Burgundy for text
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      if (_selectedTab == 'new' || _selectedTab == 'near_me') {
        return const RaniSkeletonMatchScreen();
      } else if (_selectedTab == 'accepted') {
        return const RaniSkeletonCandidateList(isAcceptedTab: true);
      } else {
        return const RaniSkeletonCandidateList(isAcceptedTab: false);
      }
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: Color(0xFFD32F2F)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF750000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _fetchMatches,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_matches.isEmpty) {
      String emptyTitle = 'No Matches Right Now';
      String emptySubtitle = 'Explore other categories or adjust your filters to discover compatible candidates.';

      if (_selectedTab == 'near_me') {
        emptyTitle = 'No Nearby Candidates Found';
        emptySubtitle = 'No candidates currently found in your city or state. Explore other tabs to discover matches.';
      } else if (_selectedTab == 'accepted') {
        emptyTitle = 'No Accepted Matches';
        emptySubtitle = 'When other members accept your connect requests, they will show up here.';
      } else if (_selectedTab == 'shortlisted') {
        emptyTitle = 'No Shortlisted Profiles';
        emptySubtitle = 'Tap the heart icon on any match card to save candidates to your shortlist.';
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF750000).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.heart_fill, size: 36, color: Color(0xFF750000)),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2B0A0D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6B6B6B)),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF750000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
                  );
                },
                icon: const Icon(CupertinoIcons.search, size: 16),
                label: const Text('Search All Candidates'),
              ),
            ],
          ),
        ),
      );
    }

    // 1. Single profile per vertical screen view for NEW and NEAR ME tabs with 10 data pagination & infinite swipe
    if (_selectedTab == 'new' || _selectedTab == 'near_me') {
      return RefreshIndicator(
        color: const Color(0xFF750000),
        onRefresh: () => _fetchMatches(isRefresh: true),
        child: PageView.builder(
          controller: _pageController,
          physics: const AlwaysScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          onPageChanged: (index) {
            if (index >= _matches.length && !_isLoadingMore && _hasMore) {
              _loadMoreMatches();
            }
          },
          itemCount: _matches.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _matches.length) {
              final candidate = _matches[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: _buildFullImageMatchCard(candidate),
              );
            } else {
              // Trigger fetch if landing directly on the loading page
              if (!_isLoadingMore && _hasMore) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadMoreMatches();
                });
              }
              // Luxury Royal Match Discovery Card loader matching the exact card design
              return _buildPagingDiscoveryLoaderCard();
            }
          },
        ),
      );
    }

    // 2. Scrollable ListView for Accepted and Shortlisted candidates with pagination
    return RefreshIndicator(
      color: const Color(0xFF750000),
      onRefresh: () => _fetchMatches(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: _matches.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _matches.length) {
            final candidate = _matches[index];
            return _buildCandidateListCard(
              candidate,
              isAcceptedTab: _selectedTab == 'accepted',
            );
          } else {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CupertinoActivityIndicator(color: Color(0xFF750000)),
                      const SizedBox(width: 10),
                      Text(
                        'Discovering more profiles...',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF750000),
                        ),
                      ),
                    ],
                  ),
                ),
                RaniSkeletonCandidateList(
                  itemCount: 2,
                  isAcceptedTab: _selectedTab == 'accepted',
                ),
              ],
            );
          }
        },
      ),
    );
  }

  /// Luxury Royal Match Discovery Card loader matching the exact card design
  Widget _buildPagingDiscoveryLoaderCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFBF8F3),
              Color(0xFFF6EFE6),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF750000).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Top-left Match Badge Placeholder
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF750000).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.sparkles, size: 12, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 5),
                    Text(
                      'Curating Profiles',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF750000),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top-right Heart Button Placeholder
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE8DFD5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.heart, size: 18, color: Color(0xFFC7B8AA)),
              ),
            ),

            // Center: Royal Animated Discovery Emblem & Uniform Title
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Royal Glowing Halo Emblem
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF750000).withValues(alpha: 0.06),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF750000), Color(0xFF4E0000)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF750000).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.sparkles,
                          color: Color(0xFFE5B842),
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Uniform Title (No counts)
                  Text(
                    'Discovering Matches...',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2B0A0D),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    'Finding compatible profiles for you',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7C6E65),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Elegant Indicator
                  const CupertinoActivityIndicator(
                    radius: 11,
                    color: Color(0xFF750000),
                  ),
                ],
              ),
            ),

            // Bottom Realistic Match Card Footer Skeleton
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 140,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEADBCE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 190,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E4D8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF750000).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF750000).withValues(alpha: 0.15),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Connect Now',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF750000).withValues(alpha: 0.4),
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

  String _formatCandidateId(dynamic c) {
    if (c == null) return 'RM00024';
    final raw = c['candidate_code'] ?? c['profile_id'] ?? c['id'];
    if (raw == null) return 'RM00024';
    String str = raw.toString().trim();
    while (str.toUpperCase().startsWith('RMRM')) {
      str = str.substring(2);
    }
    if (!str.toUpperCase().startsWith('RM')) {
      if (int.tryParse(str) != null) {
        return 'RM${str.padLeft(5, '0')}';
      }
      return 'RM$str';
    }
    return str;
  }

  /// Candidate List Card for Accepted & Shortlisted tabs
  Widget _buildCandidateListCard(dynamic c, {required bool isAcceptedTab}) {
    final profileId = _formatCandidateId(c);
    final firstName = c['first_name'] ?? 'Candidate';
    final lastName = c['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final age = c['age']?.toString() ?? '24';
    final height = c['height']?.toString() ?? "5' 4\"";
    final religion = c['religion']?.toString() ?? 'Muslim';
    final community = c['community']?.toString() ?? '';
    final religionWithCommunity = (community.isNotEmpty && community.toLowerCase() != 'all' && community.toLowerCase() != 'all communities')
        ? '$religion, $community'
        : religion;
    final profession = c['profession']?.toString() ?? c['designation']?.toString() ?? 'Professional';
    final income = c['annual_income']?.toString() ?? '';
    final city = c['city']?.toString() ?? 'Kolkata';
    final state = c['state']?.toString() ?? 'West Bengal';
    final locationText = (city.isNotEmpty && state.isNotEmpty) ? '$city, $state' : (city.isNotEmpty ? city : state);
    final photo = c['photo'] ?? c['profile_picture'] ?? '';
    final isVerified = c['verified'] == true || c['is_verified'] == 1 || (c['bluetick'] != null && c['bluetick']['is_accept'] == 1);
    final matchScore = c['match_score']?.toString() ?? c['match_percentage']?.toString() ?? '95';
    final photoCount = (c['photos'] is List && (c['photos'] as List).isNotEmpty)
        ? (c['photos'] as List).length
        : (photo.toString().isNotEmpty ? 1 : 1);
    final isInterestSent = c['request_type'] == 'sent' || c['is_connected'] == true || isAcceptedTab;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE8DE), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RaniMatchDetailsScreen(
                  profileId: profileId,
                  initialProfileData: c,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Candidate Photo with match badge
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 95,
                            height: 115,
                            child: photo.toString().isNotEmpty
                                ? Image.network(
                                    photo.toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFFEFE7DC),
                                      child: const Icon(CupertinoIcons.person_fill, size: 45, color: Color(0xFFB5A795)),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFFEFE7DC),
                                    child: const Icon(CupertinoIcons.person_fill, size: 45, color: Color(0xFFB5A795)),
                                  ),
                          ),
                        ),
                        // Match score badge
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5B842),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.star_fill, size: 9, color: Color(0xFF4A0000)),
                                const SizedBox(width: 2.5),
                                Text(
                                  '$matchScore%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF4A0000),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Photo count badge at bottom-right of thumbnail
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.photo_on_rectangle,
                                  color: Color(0xFFE5B842),
                                  size: 9.5,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$photoCount',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Info Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E1E1E),
                                  ),
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  CupertinoIcons.checkmark_seal_fill,
                                  size: 16,
                                  color: Color(0xFF2196F3),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'ID: $profileId',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$age yrs, $height • $religionWithCommunity',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4A4A4A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.briefcase, size: 12, color: Color(0xFF750000)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  income.isNotEmpty ? '$profession • $income' : profession,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF555555),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.location_solid, size: 12, color: Color(0xFFD32F2F)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  locationText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF666666),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFEFE8DE)),
                const SizedBox(height: 10),

                // Action Buttons Row
                if (isAcceptedTab) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 13, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 4),
                            Text(
                              'Connected',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF750000),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RaniMatchDetailsScreen(
                                profileId: profileId,
                                initialProfileData: c,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 14),
                        label: Text(
                          'View Contact',
                          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      // Shortlist Heart Toggle Button (Filled Red Heart)
                      GestureDetector(
                        onTap: () => _toggleShortlist(c),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: const Icon(CupertinoIcons.heart_fill, size: 18, color: Color(0xFFE53935)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Connect CTA Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInterestSent ? const Color(0xFF2E7D32) : const Color(0xFF750000),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: isInterestSent ? null : () => _sendRoyalInterest(c),
                          icon: Icon(
                            isInterestSent ? CupertinoIcons.checkmark_alt : CupertinoIcons.heart,
                            size: 15,
                          ),
                          label: Text(
                            isInterestSent ? 'Connected' : 'Connect Now',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Full-Image Immersive Profile Match Card
  Widget _buildFullImageMatchCard(dynamic c) {
    final profileId = _formatCandidateId(c);
    final firstName = c['first_name'] ?? 'Candidate';
    final lastName = c['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final age = c['age']?.toString() ?? '22';
    final religion = c['religion']?.toString() ?? 'Muslim';
    final profession = c['profession']?.toString() ?? c['designation']?.toString() ?? 'Doctor';
    final city = c['city']?.toString() ?? 'Howrah';
    final state = c['state']?.toString() ?? 'West Bengal';
    final locationText = (city.isNotEmpty && state.isNotEmpty) ? '$city, $state' : (city.isNotEmpty ? city : state);
    final photo = c['photo'] ?? c['profile_picture'] ?? '';
    final isVerified = c['verified'] == true || c['is_verified'] == 1 || (c['bluetick'] != null && c['bluetick']['is_accept'] == 1);
    final isShortlisted = c['is_shortlisted'] == true;
    final matchScore = c['match_score']?.toString() ?? c['match_percentage']?.toString() ?? '99';
    final photoCount = (c['photos'] is List && (c['photos'] as List).isNotEmpty)
        ? (c['photos'] as List).length
        : (photo.toString().isNotEmpty ? 1 : 1);
    final isInterestSent = c['request_type'] == 'sent' || c['is_connected'] == true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RaniMatchDetailsScreen(
              profileId: profileId,
              initialProfileData: c,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Full Image Background
              photo.toString().isNotEmpty
                  ? Image.network(
                      photo.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFDED5C9),
                        child: const Icon(CupertinoIcons.person_fill, size: 80, color: Colors.white70),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFDED5C9),
                      child: const Icon(CupertinoIcons.person_fill, size: 80, color: Colors.white70),
                    ),

              // 2. Bottom Royal Burgundy Gradient Overlay for optimal legibility
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF260003).withValues(alpha: 0.15),
                        const Color(0xFF200003).withValues(alpha: 0.65),
                        const Color(0xFF150002).withValues(alpha: 0.96),
                      ],
                      stops: const [0.42, 0.62, 0.80, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Top-Left Corner: Percentage of Matching
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5B842), // Golden yellow
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF750000).withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.star_fill, size: 12, color: Color(0xFF4A0000)),
                      const SizedBox(width: 4),
                      Text(
                        '$matchScore% Match',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4A0000), // Theme Burgundy
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Top-Right Corner: Wishlist Heart Icon
              Positioned(
                top: 14,
                right: 14,
                child: GestureDetector(
                  onTap: () => _toggleShortlist(c),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isShortlisted ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                      color: isShortlisted ? const Color(0xFFE53935) : const Color(0xFF333333),
                      size: 20,
                    ),
                  ),
                ),
              ),

              // 5. Bottom Info Content (Name, Blue Tick, ID, Age, Religion, Professional, Location, Connect Button)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Candidate Name, Blue Tick, ID & Photo Count Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left: Candidate Name & ID
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                        shadows: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isVerified) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      CupertinoIcons.checkmark_seal_fill,
                                      size: 20,
                                      color: Color(0xFF2196F3), // Verified Blue Tick
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: $profileId',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right: Photo Count Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.60),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.photo_on_rectangle,
                                color: Color(0xFFE5B842),
                                size: 12.5,
                              ),
                              const SizedBox(width: 4.5),
                              Text(
                                '$photoCount Photos',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Age • Religion • Professional
                    Text(
                      '$age yrs • $religion • $profession',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                        shadows: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 3),

                    // Location (City, State)
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.location_solid,
                          size: 14,
                          color: Color(0xFFFF5252),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.88),
                              shadows: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Connect Button Just
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInterestSent ? const Color(0xFF2E7D32) : const Color(0xFF750000),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isInterestSent ? null : () => _sendRoyalInterest(c),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isInterestSent ? CupertinoIcons.checkmark_alt : CupertinoIcons.heart,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isInterestSent ? 'Connected' : 'Connect',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
