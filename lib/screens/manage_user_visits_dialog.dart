import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';

Future<Map<String, dynamic>?> showManageUserVisitsDialog(
  BuildContext context,
  AdminUser user,
) => showDialog<Map<String, dynamic>>(
  context: context,
  builder: (_) => _ManageUserVisitsDialog(user: user),
);

class _ManageUserVisitsDialog extends StatefulWidget {
  const _ManageUserVisitsDialog({required this.user});

  final AdminUser user;

  @override
  State<_ManageUserVisitsDialog> createState() =>
      _ManageUserVisitsDialogState();
}

class _ManageUserVisitsDialogState extends State<_ManageUserVisitsDialog> {
  final _searchController = TextEditingController();
  List<Place> _places = [];
  Set<String> _visitedPlaceIds = {};
  final Set<String> _selectedPlaceIds = {};
  Map<String, dynamic> _visitState = const {};
  String _category = 'All';
  String? _error;
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _lastResult;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AdminService.instance.fetchPlaces(),
        AdminService.instance.fetchUserVisitState(widget.user.id),
      ]);
      if (!mounted) return;
      final places = results[0] as List<Place>;
      final state = results[1] as Map<String, dynamic>;
      setState(() {
        _places = places;
        _visitState = state;
        _visitedPlaceIds = (state['visited_place_ids'] as List)
            .map((id) => id.toString())
            .toSet();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  List<String> get _categories => [
    'All',
    ..._places.map((place) => place.category).toSet().toList()..sort(),
  ];

  List<Place> get _filteredPlaces {
    final query = _searchController.text.trim().toLowerCase();
    return _places
        .where((place) {
          if (_category != 'All' && place.category != _category) return false;
          if (query.isEmpty) return true;
          return [
            place.name,
            place.nameAr ?? '',
            place.category,
            place.categoryAr ?? '',
          ].any((value) => value.toLowerCase().contains(query));
        })
        .toList(growable: false);
  }

  Future<void> _removeVisit(Place place) async {
    setState(() => _saving = true);
    try {
      final result = await AdminService.instance.updateUserVisits(
        userId: widget.user.id,
        placeIds: [place.id],
        add: false,
      );
      if (!mounted) return;
      setState(() {
        _lastResult = result;
        _visitState = result;
        _visitedPlaceIds = (result['visited_place_ids'] as List)
            .map((id) => id.toString())
            .toSet();
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed visit to ${place.name}. Stats synced.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not remove visit: $error')));
    }
  }

  Future<void> _addSelectedVisits() async {
    if (_selectedPlaceIds.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final result = await AdminService.instance.updateUserVisits(
        userId: widget.user.id,
        placeIds: _selectedPlaceIds.toList(growable: false),
        add: true,
      );
      if (!mounted) return;
      setState(() {
        _lastResult = result;
        _visitState = result;
        _visitedPlaceIds = (result['visited_place_ids'] as List)
            .map((id) => id.toString())
            .toSet();
        _selectedPlaceIds.clear();
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visits, XP, and badges synced.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add visits: $error')));
    }
  }

  String _formatBadgeName(dynamic badge) {
    if (badge is! Map) return 'Achievement';
    final name = (badge['name'] ?? badge['id'] ?? 'Achievement').toString();
    return name
        .replaceFirst('ach_', '')
        .replaceAll('_name', '')
        .replaceAll('_', ' ');
  }

  Widget _summary() {
    final badges = _visitState['badges'] is List
        ? _visitState['badges'] as List
        : const <dynamic>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.user.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          Text(
            widget.user.email,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _statChip(
                Icons.place_outlined,
                '${_visitState['places_visited'] ?? _visitedPlaceIds.length} visits',
              ),
              _statChip(
                Icons.stars_rounded,
                '${_visitState['total_points'] ?? 0} XP',
              ),
              _statChip(Icons.military_tech_rounded, '${badges.length} badges'),
            ],
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: badges
                  .map(
                    (badge) => Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(_formatBadgeName(badge)),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) => Chip(
    avatar: Icon(icon, size: 16, color: AppTheme.primary),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Manage User Visits & Badges',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(context, _lastResult),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _loading ? const LinearProgressIndicator() : _summary(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search places in Arabic or English',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 170,
                    child: DropdownButtonFormField<String>(
                      initialValue: categories.contains(_category)
                          ? _category
                          : 'All',
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(
                                category,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) =>
                          setState(() => _category = value ?? 'All'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_selectedPlaceIds.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_selectedPlaceIds.length} unvisited place(s) selected',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Could not load user visits: $_error'),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredPlaces.isEmpty
                    ? const Center(child: Text('No matching places.'))
                    : ListView.separated(
                        itemCount: _filteredPlaces.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final place = _filteredPlaces[index];
                          final visited = _visitedPlaceIds.contains(place.id);
                          final selected = _selectedPlaceIds.contains(place.id);
                          return ListTile(
                            dense: true,
                            leading: visited
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.success,
                                  )
                                : Checkbox(
                                    value: selected,
                                    onChanged: _saving
                                        ? null
                                        : (value) => setState(() {
                                            if (value == true) {
                                              _selectedPlaceIds.add(place.id);
                                            } else {
                                              _selectedPlaceIds.remove(
                                                place.id,
                                              );
                                            }
                                          }),
                                  ),
                            title: Text(
                              [
                                place.name,
                                if ((place.nameAr ?? '').trim().isNotEmpty)
                                  place.nameAr!,
                              ].join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              [
                                place.category,
                                if ((place.categoryAr ?? '').trim().isNotEmpty)
                                  place.categoryAr!,
                                visited ? 'Visited' : 'Not visited',
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: visited
                                ? IconButton(
                                    tooltip: 'Remove this visit',
                                    onPressed: _saving
                                        ? null
                                        : () => _removeVisit(place),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: AppTheme.danger,
                                    ),
                                  )
                                : null,
                            onTap: visited || _saving
                                ? null
                                : () => setState(() {
                                    if (selected) {
                                      _selectedPlaceIds.remove(place.id);
                                    } else {
                                      _selectedPlaceIds.add(place.id);
                                    }
                                  }),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed:
                        _loading ||
                            _error != null ||
                            _saving ||
                            _selectedPlaceIds.isEmpty
                        ? null
                        : _addSelectedVisits,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Add Visits & Sync Badges'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
