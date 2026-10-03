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
  bool _savingOrder = false;
  String _filter = '';
  bool _editOrder = true;

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

  Future<void> _persistOrder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = _places.removeAt(oldIndex);
    _places.insert(newIndex, moved);
    setState(() {});

    // v1.0.69 fix: build the display_order payload from the NEW indices,
    // never from the Place.displayOrder field on each object (which still
    // holds the OLD DB values until the RPC runs and we re-fetch).
    // 10-step gaps leave room to drop a new place between any two
    // existing ones without re-numbering the world.
    const int step = 10;
    final placeIds = <String>[];
    final newOrders = <int>[];
    for (var i = 0; i < _places.length; i++) {
      placeIds.add(_places[i].id);
      newOrders.add((i + 1) * step);
    }
    final entries = List<({String id, int displayOrder})>.generate(
      _places.length,
      (i) => (id: placeIds[i], displayOrder: newOrders[i]),
    );

    setState(() => _savingOrder = true);
    try {
      await AdminService.instance.updateDisplayOrders(entries);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New order saved')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order save FAILED — reverted. Tap for details.',
          ),
          duration: const Duration(seconds: 8),
          backgroundColor: AppTheme.danger,
          action: SnackBarAction(
            label: 'Details',
            textColor: Colors.white,
            onPressed: () => _showErrorDialog(msg),
          ),
        ),
      );
      // v1.0.65: always reload from the server after a failure so the
      // local optimistic re-order doesn't linger in the UI and look like
      // it actually persisted.
      await _load();
    } finally {
      if (mounted) setState(() => _savingOrder = false);
    }
  }

  Future<void> _showErrorDialog(String msg) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save failed'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: SelectableText(
              msg,
              style: const TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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

  void _openEdit(Place p) async {
    final result = await Navigator.push<Place>(
      context,
      MaterialPageRoute(builder: (_) => PlaceFormScreen(place: p)),
    );
    if (result != null) _load();
  }

  void _openPhotos(Place p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PhotosListScreen(place: p)),
    );
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
        actions: [
          IconButton(
            icon: Icon(
              _editOrder ? Icons.drag_indicator_rounded : Icons.list_alt_rounded,
              color: _editOrder ? AppTheme.primary : null,
            ),
            onPressed: () => setState(() => _editOrder = !_editOrder),
            tooltip: _editOrder
                ? 'Stop reordering (drag handles hidden)'
                : 'Reorder places by drag-and-drop',
          ),
        ],
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
          if (_savingOrder)
            const LinearProgressIndicator(minHeight: 2),
          if (_editOrder && !_loading && _places.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              width: double.infinity,
              color: AppTheme.primary.withValues(alpha: 0.08),
              child: Text(
                'Drag-and-drop mode — long-press a row and drag to reorder. '
                'Changes save automatically.',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
                    : _editOrder
                        ? ReorderableListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                            itemCount: filtered.length,
                            buildDefaultDragHandles: false,
                            onReorder: _persistOrder,
                            itemBuilder: (context, i) {
                              final p = filtered[i];
                              return Padding(
                                key: ValueKey('place_${p.id}'),
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: _PlaceRow(
                                  place: p,
                                  orderPosition: i + 1,
                                  onPhotos: () => _openPhotos(p),
                                  onEdit: () => _openEdit(p),
                                  onDelete: () => _delete(p),
                                  dragHandle: ReorderableDragStartListener(
                                    index: i,
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.drag_handle_rounded,
                                        color: Colors.black45,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 90),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final p = filtered[i];
                                return _PlaceRow(
                                  place: p,
                                  orderPosition: i + 1,
                                  onPhotos: () => _openPhotos(p),
                                  onEdit: () => _openEdit(p),
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
  final int orderPosition;
  final VoidCallback onPhotos;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? dragHandle;

  const _PlaceRow({
    required this.place,
    required this.orderPosition,
    required this.onPhotos,
    required this.onEdit,
    required this.onDelete,
    this.dragHandle,
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
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: AppTheme.bg,
                child: const Icon(
                  Icons.image_not_supported_rounded,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$orderPosition',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
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
          if (dragHandle != null) dragHandle!,
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