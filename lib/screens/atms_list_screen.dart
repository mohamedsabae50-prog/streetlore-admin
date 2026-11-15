import 'package:flutter/material.dart';

import '../models/governorates_config.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';
import 'place_form_screen.dart';

class AtmsListScreen extends StatefulWidget {
  const AtmsListScreen({super.key});

  @override
  State<AtmsListScreen> createState() => _AtmsListScreenState();
}

class _AtmsListScreenState extends State<AtmsListScreen> {
  List<Place> _atms = [];
  bool _loading = true;
  String _query = '';
  String _governorateFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final places = await AdminService.instance.fetchPlaces();
      if (!mounted) return;
      setState(() {
        _atms = atmPlaces(places);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load ATMs: $error')));
    }
  }

  int _countForGovernorate(String governorateId) => _atms
      .where(
        (place) => normalizeGovernorateId(place.governorate) == governorateId,
      )
      .length;

  Future<void> _openForm({Place? place}) async {
    final result = await Navigator.push<Place>(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceFormScreen(
          place: place,
          lockedCategory: 'ATMs',
          initialGovernorate: _governorateFilter == 'all'
              ? 'alexandria'
              : _governorateFilter,
        ),
      ),
    );
    if (!mounted) return;
    if (result != null) _load();
  }

  Future<void> _delete(Place place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ATM?'),
        content: Text('"${place.name}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      await AdminService.instance.deletePlace(place.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ATM deleted')));
      _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = _atms
        .where((place) {
          final matchesGovernorate =
              _governorateFilter == 'all' ||
              normalizeGovernorateId(place.governorate) == _governorateFilter;
          final matchesQuery =
              query.isEmpty ||
              place.name.toLowerCase().contains(query) ||
              (place.nameAr?.toLowerCase().contains(query) ?? false) ||
              place.address.toLowerCase().contains(query) ||
              place.id.toLowerCase().contains(query);
          return matchesGovernorate && matchesQuery;
        })
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('ATMs · الصراف الآلي')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('New ATM'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search ATMs',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('all', 'All (الكل)', _atms.length),
                      for (final governorate in GovernorateConfig.all)
                        _filterChip(
                          governorate.id,
                          '${governorate.nameEn} (${governorate.nameAr})',
                          _countForGovernorate(governorate.id),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? const Center(child: Text('No ATMs found'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final place = filtered[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.atm_rounded),
                          ),
                          title: Text(place.name),
                          subtitle: Text(
                            '${place.nameAr} · ${place.address} · '
                            '${normalizeGovernorateId(place.governorate)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Edit ATM',
                                onPressed: () => _openForm(place: place),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Delete ATM',
                                onPressed: () => _delete(place),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String id, String label, int count) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      selected: _governorateFilter == id,
      label: Text('$label · $count'),
      onSelected: (_) => setState(() => _governorateFilter = id),
    ),
  );
}
