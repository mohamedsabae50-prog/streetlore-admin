import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';
import 'photos_list_screen.dart';
import 'place_form_screen.dart';
import 'places_list_screen.dart';
import 'tour_form_screen.dart';
import 'tours_list_screen.dart';
import 'users_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _placesCount = 0;
  int _toursCount = 0;
  int _photosCount = 0;
  bool _photosAvailable = true;
  bool _loading = true;
  AdminAnalytics? _analytics;
  bool _analyticsLoading = true;
  String? _analyticsError;

  @override
  void initState() {
    super.initState();
    _refreshCounts();
  }

  Future<void> _refreshCounts() async {
    setState(() {
      _loading = true;
      _analyticsLoading = true;
      _analyticsError = null;
    });
    final photosFuture = AdminService.instance.fetchPhotoCount();
    final analyticsFuture = AdminService.instance.fetchAdminAnalytics();
    try {
      final counts = await AdminService.instance.fetchDashboardCounts();
      if (!mounted) return;
      setState(() {
        _placesCount = counts.places;
        _toursCount = counts.tours;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load counts: $e')));
    }
    try {
      final photosCount = await photosFuture;
      if (!mounted) return;
      setState(() {
        _photosCount = photosCount;
        _photosAvailable = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _photosAvailable = false);
    }
    try {
      final analytics = await analyticsFuture;
      if (!mounted) return;
      setState(() {
        _analytics = analytics;
        _analyticsLoading = false;
        _analyticsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _analyticsLoading = false;
        _analyticsError = '$e';
      });
    }
  }

  Future<void> _signOut() async {
    await AdminService.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Text(
              'Streetlore Admin',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(width: 10),
            Text(
              'v1.1.1',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshCounts,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.location_on_rounded,
                      color: AppTheme.primary,
                      title: 'Places',
                      count: _placesCount,
                      loading: _loading,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PlacesListScreen(),
                          ),
                        );
                        _refreshCounts();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.tour_rounded,
                      color: AppTheme.success,
                      title: 'Tours',
                      count: _toursCount,
                      loading: _loading,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ToursListScreen(),
                          ),
                        );
                        _refreshCounts();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.photo_library_rounded,
                      color: AppTheme.warning,
                      title: _photosAvailable
                          ? 'User Photos'
                          : 'User Photos (setup needed)',
                      count: _photosCount,
                      loading: _loading,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PhotosListScreen(),
                          ),
                        );
                        _refreshCounts();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _AnalyticsPanel(
                analytics: _analytics,
                loading: _analyticsLoading,
                error: _analyticsError,
                onRetry: _refreshCounts,
              ),
              const SizedBox(height: 28),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _ActionCard(
                icon: Icons.add_location_alt_rounded,
                color: AppTheme.primary,
                title: 'Add a Place',
                subtitle: 'Create a new location, museum, or restaurant',
                onTap: () async {
                  final result = await Navigator.push<Place>(
                    context,
                    MaterialPageRoute(builder: (_) => const PlaceFormScreen()),
                  );
                  if (result != null) _refreshCounts();
                },
              ),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.tour_rounded,
                color: AppTheme.success,
                title: 'Add a Tour',
                subtitle: 'Create a new tour and pick its places',
                onTap: () async {
                  final result = await Navigator.push<Tour>(
                    context,
                    MaterialPageRoute(builder: (_) => const TourFormScreen()),
                  );
                  if (result != null) _refreshCounts();
                },
              ),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.people_alt_rounded,
                color: AppTheme.warning,
                title: 'Manage Users',
                subtitle: 'Search users and remove inappropriate accounts',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersListScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  final AdminAnalytics? analytics;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  const _AnalyticsPanel({
    required this.analytics,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Analytics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Usage and engagement at a glance',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (error != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Analytics unavailable: $error',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRetry,
                  tooltip: 'Retry analytics',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          )
        else if (analytics case final stats?)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _AnalyticsMetricCard(
                      icon: Icons.auto_awesome_rounded,
                      color: AppTheme.primary,
                      value: stats.totalAiGuideUsage,
                      label: 'AI guide calls',
                      caption: 'Current 24-hour quota windows',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnalyticsMetricCard(
                      icon: Icons.check_circle_outline_rounded,
                      color: AppTheme.success,
                      value: stats.totalCheckins,
                      label: 'Total check-ins',
                      caption: 'All recorded visits',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _PopularToursCard(tours: stats.popularTours),
              const SizedBox(height: 14),
              _TopPlacesByCheckinsCard(places: stats.topPlacesByCheckins),
            ],
          ),
      ],
    );
  }
}

class _AnalyticsMetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final String caption;

  const _AnalyticsMetricCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 138),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PopularToursCard extends StatelessWidget {
  final List<PopularTour> tours;

  const _PopularToursCard({required this.tours});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: AppTheme.warning),
              SizedBox(width: 8),
              Text(
                'Most viewed tours',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (tours.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No published tours yet',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            )
          else
            ...tours.indexed.map((entry) {
              final (index, tour) = entry;
              return Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.warning,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tour.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tour.viewCount.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _TopPlacesByCheckinsCard extends StatelessWidget {
  final List<PlaceCheckinCount> places;

  const _TopPlacesByCheckinsCard({required this.places});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.place_rounded, color: AppTheme.success),
              SizedBox(width: 8),
              Text(
                'Top Places by Check-ins',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (places.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No check-ins recorded yet',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            )
          else
            ...places.indexed.map((entry) {
              final (index, place) = entry;
              return Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        place.placeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      place.checkinCount.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final int count;
  final bool loading;
  final VoidCallback onTap;
  const _StatCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
    required this.loading,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              loading ? '...' : '$count',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Manage',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
