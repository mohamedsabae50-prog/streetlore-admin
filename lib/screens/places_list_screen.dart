import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';
import 'photos_list_screen.dart';
import 'place_form_screen.dart';

class PlacesListScreen extends StatefulWidget {
  const PlacesListScreen({super.key});
  @override
  State<PlacesListScreen> createState() => _PlacesListScreenState();
}

class _PlacesListScreenState extends State<PlacesListScreen> {
  List<Place> _places = [];
  bool _loading = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await AdminService.instance.fetchPlaces();
      if (!mounted) return;
      setState(() {
        _places = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Load failed: $e')));
    }
  }

  Future<void> _delete(Place p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete place?'),
        content: Text('"${p.name}" will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AdminService.instance.deletePlace(p.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Place deleted')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter.isEmpty
        ? _places
        : _places
            .where((p) =>
                p.name.toLowerCase().contains(_filter.toLowerCase()) ||
                p.category.toLowerCase().contains(_filter.toLowerCase()))
            .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Places',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<Place>(
            context,
            MaterialPageRoute(builder: (_) => const PlaceFormScreen()),
          );
          if (result != null) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Place'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _filter = v),
              decoration: InputDecoration(
                hintText: 'Search by name or category...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _filter.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _filter = ''),
                      ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 64,
                                color: AppTheme.textSecondary
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 10),
                            const Text('No places found',
                                style: TextStyle(
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final p = filtered[i];
                            return _PlaceRow(
                              place: p,
                              onPhotos: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          PhotosListScreen(place: p)),
                                );
                              },
                              onEdit: () async {
                                final result = await Navigator.push<Place>(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          PlaceFormScreen(place: p)),
                                );
                                if (result != null) _load();
                              },
                              onDelete: () => _delete(p),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  final Place place;
  final VoidCallback onPhotos;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PlaceRow({
    required this.place,
    required this.onPhotos,
    required this.onEdit,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              place.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: AppTheme.bg,
                child: const Icon(Icons.image_not_supported_rounded,
                    color: AppTheme.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${place.category} · ${place.priceLevel.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (place.isHiddenGem)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'HIDDEN GEM',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined,
                color: AppTheme.success),
            onPressed: onPhotos,
            tooltip: 'Photos',
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppTheme.primary),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.danger),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
