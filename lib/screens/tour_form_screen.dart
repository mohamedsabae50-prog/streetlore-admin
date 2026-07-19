import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class TourFormScreen extends StatefulWidget {
  final Tour? tour;
  const TourFormScreen({super.key, this.tour});
  @override
  State<TourFormScreen> createState() => _TourFormScreenState();
}

class _TourFormScreenState extends State<TourFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _id;
  late TextEditingController _title;
  late TextEditingController _description;
  late TextEditingController _duration;
  late TextEditingController _imageUrl;
  List<Place> _allPlaces = [];
  List<Place> _selectedPlaces = [];
  bool _saving = false;
  bool _loading = true;

  bool get _isEditing => widget.tour != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tour;
    _id = TextEditingController(text: t?.id ?? 't_${DateTime.now().millisecondsSinceEpoch}');
    _title = TextEditingController(text: t?.title ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _duration = TextEditingController(text: t?.duration ?? '');
    _imageUrl = TextEditingController(text: t?.imageUrl ?? '');
    _selectedPlaces = List<Place>.from(t?.places ?? const []);
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await AdminService.instance.fetchPlaces();
      if (!mounted) return;
      setState(() {
        _allPlaces = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load places: $e')));
    }
  }

  Future<void> _pickPlaces() async {
    final result = await showModalBottomSheet<List<Place>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PlacePickerSheet(
        all: _allPlaces,
        initiallySelected: _selectedPlaces,
      ),
    );
    if (result != null) {
      setState(() => _selectedPlaces = result);
    }
  }

  void _removePlace(Place p) {
    setState(() => _selectedPlaces.removeWhere((x) => x.id == p.id));
  }

  void _movePlace(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final p = _selectedPlaces.removeAt(oldIndex);
      _selectedPlaces.insert(newIndex, p);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final tour = Tour(
        id: _id.text.trim(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        duration: _duration.text.trim(),
        imageUrl: _imageUrl.text.trim(),
        places: _selectedPlaces,
      );
      if (_isEditing) {
        await AdminService.instance.updateTour(tour);
      } else {
        await AdminService.instance.createTour(tour);
      }
      if (!mounted) return;
      Navigator.pop(context, tour);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Tour' : 'New Tour',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Update' : 'Create',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppTheme.primary)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _label('ID'),
                  TextFormField(
                    controller: _id,
                    enabled: !_isEditing,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'ID is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _label('Title'),
                  TextFormField(
                    controller: _title,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _label('Description'),
                  TextFormField(
                    controller: _description,
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Description is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Duration'),
                            TextFormField(
                              controller: _duration,
                              decoration: const InputDecoration(
                                  hintText: '4 Hours'),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _label('Cover image URL'),
                  TextFormField(
                    controller: _imageUrl,
                    decoration: const InputDecoration(
                      hintText: 'https://images.unsplash.com/...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Image URL is required'
                        : null,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _label('Stops (${_selectedPlaces.length})'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _pickPlaces,
                        icon: const Icon(Icons.add_location_alt_outlined,
                            size: 18),
                        label: const Text('Add stops'),
                      ),
                    ],
                  ),
                  if (_selectedPlaces.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.border, style: BorderStyle.solid),
                      ),
                      child: const Center(
                        child: Text('No stops yet — tap "Add stops"',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: _selectedPlaces.length,
                      onReorder: _movePlace,
                      itemBuilder: (context, i) {
                        final p = _selectedPlaces[i];
                        return Container(
                          key: ValueKey(p.id),
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: i,
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.drag_indicator_rounded,
                                      color: AppTheme.textSecondary),
                                ),
                              ),
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.primary,
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary)),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppTheme.danger),
                                onPressed: () => _removePlace(p),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isEditing ? 'Update Tour' : 'Create Tour'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
      );
}

class _PlacePickerSheet extends StatefulWidget {
  final List<Place> all;
  final List<Place> initiallySelected;
  const _PlacePickerSheet({
    required this.all,
    required this.initiallySelected,
  });
  @override
  State<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<_PlacePickerSheet> {
  late Set<String> _selected;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.initiallySelected.map((p) => p.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter.isEmpty
        ? widget.all
        : widget.all
            .where((p) =>
                p.name.toLowerCase().contains(_filter.toLowerCase()) ||
                p.category.toLowerCase().contains(_filter.toLowerCase()))
            .toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Pick places',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('${_selected.length} selected',
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _filter = v),
                  decoration: const InputDecoration(
                    hintText: 'Search places...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    final selected = _selected.contains(p.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (_) => setState(() {
                        if (selected) {
                          _selected.remove(p.id);
                        } else {
                          _selected.add(p.id);
                        }
                      }),
                      title: Text(p.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      subtitle: Text(
                        '${p.category} · ${p.id}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final picked = widget.all
                          .where((p) => _selected.contains(p.id))
                          .toList();
                      Navigator.pop(context, picked);
                    },
                    child: Text('Confirm (${_selected.length})'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
