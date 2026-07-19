import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';
import 'photo_form_screen.dart';
import 'photos_list_screen.dart';
import 'place_form_screen.dart';
import 'places_list_screen.dart';
import 'tour_form_screen.dart';
import 'tours_list_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _refreshCounts();
  }

  Future<void> _refreshCounts() async {
    setState(() => _loading = true);
    try {
      final places = await AdminService.instance.fetchPlaces();
      final tours = await AdminService.instance.fetchTours();
      if (!mounted) return;
      setState(() {
        _placesCount = places.length;
        _toursCount = tours.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load counts: $e')),
      );
    }
    try {
      final photos = await AdminService.instance.fetchPhotos();
      if (!mounted) return;
      setState(() {
        _photosCount = photos.length;
        _photosAvailable = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _photosAvailable = false);
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
        title: const Text('Streetlore Admin',
            style: TextStyle(fontWeight: FontWeight.w800)),
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
                              builder: (_) => const PlacesListScreen()),
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
                              builder: (_) => const ToursListScreen()),
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
                      title: _photosAvailable ? 'Photos' : 'Photos (setup needed)',
                      count: _photosCount,
                      loading: _loading,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PhotosListScreen()),
                        );
                        _refreshCounts();
                      },
                    ),
                  ),
                ],
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
                    MaterialPageRoute(
                        builder: (_) => const PlaceFormScreen()),
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
                    MaterialPageRoute(
                        builder: (_) => const TourFormScreen()),
                  );
                  if (result != null) _refreshCounts();
                },
              ),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.add_a_photo_rounded,
                color: AppTheme.warning,
                title: 'Add a Photo',
                subtitle: 'Photo with Arabic & English caption and username',
                onTap: () async {
                  final result = await Navigator.push<PlacePhoto>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PhotoFormScreen()),
                  );
                  if (result != null) _refreshCounts();
                },
              ),
            ],
          ),
        ),
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
                      fontWeight: FontWeight.w800),
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
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
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
