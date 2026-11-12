import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/local_draft_mode_banner.dart';
import 'places_list_screen.dart';
import 'tours_list_screen.dart';

class LocalPreviewScreen extends StatelessWidget {
  const LocalPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Governorate Local Preview',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const LocalDraftModeBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Text(
              'No place or tour edits from this preview are sent to Supabase.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          _PreviewTile(
            icon: Icons.place_outlined,
            title: 'Places · الأماكن',
            subtitle: 'Browse and draft Alexandria and Cairo places',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlacesListScreen()),
            ),
          ),
          _PreviewTile(
            icon: Icons.route_outlined,
            title: 'Tours · الجولات',
            subtitle: 'Browse and draft governorate-specific itineraries',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ToursListScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PreviewTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
