import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class TourFormScreen extends StatefulWidget {
  final Tour? tour;
  const TourFormScreen({super.key, this.tour});
  @override
  State<TourFormScreen> createState() => _TourFormScreenState();
}

class _CoverDraft {
  Uint8List? bytes;
  String ext = 'jpg';
  String? uploadedUrl;
}

class _TourFormScreenState extends State<TourFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _id;
  late TextEditingController _titleEn;
  late TextEditingController _titleAr;
  late TextEditingController _descriptionEn;
  late TextEditingController _descriptionAr;
  late TextEditingController _durationEn;
  late TextEditingController _durationAr;
  late TextEditingController _category;
  late TextEditingController _categoryAr;
  late TextEditingController _imageUrl;
  late TextEditingController _search;

  final _cover = _CoverDraft();

  List<Place> _allPlaces = [];
  List<Place> _selectedPlaces = [];
  bool _saving = false;
  bool _loading = true;
  bool _uploadingCover = false;

  bool get _isEditing => widget.tour != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tour;
    _id = TextEditingController(
      text: t?.id ?? 'tour_${DateTime.now().millisecondsSinceEpoch}',
    );
    _titleEn = TextEditingController(text: t?.title ?? '');
    _titleAr = TextEditingController(text: t?.titleAr ?? '');
    _descriptionEn = TextEditingController(text: t?.description ?? '');
    _descriptionAr = TextEditingController(text: t?.descriptionAr ?? '');
    _durationEn = TextEditingController(text: t?.duration ?? '');
    _durationAr = TextEditingController(text: t?.durationAr ?? '');
    _category = TextEditingController(text: t?.category ?? 'Historical');
    _categoryAr = TextEditingController(text: t?.categoryAr ?? '');
    _imageUrl = TextEditingController(text: t?.imageUrl ?? '');
    _search = TextEditingController();
    _selectedPlaces = List<Place>.from(t?.places ?? const []);
    _load();
  }

  @override
  void dispose() {
    _id.dispose();
    _titleEn.dispose();
    _titleAr.dispose();
    _descriptionEn.dispose();
    _descriptionAr.dispose();
    _durationEn.dispose();
    _durationAr.dispose();
    _category.dispose();
    _categoryAr.dispose();
    _imageUrl.dispose();
    _search.dispose();
    super.dispose();
  }

  String? _nullable(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
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

  Future<void> _pickAndUploadCover() async {
    if (_uploadingCover) return;
    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file picker: $e')),
      );
      return;
    }
    if (picked == null) return;
    try {
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) throw Exception('Picked file is empty');
      final ext = picked.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      if (!mounted) return;
      setState(() {
        _cover.bytes = bytes;
        _cover.ext = ext;
        _uploadingCover = true;
      });
      final publicUrl = await AdminService.instance.uploadImageBytes(
        bytes,
        'tours',
        '${_id.text.trim()}.$ext',
      );
      if (!mounted) return;
      setState(() {
        _cover.uploadedUrl = publicUrl;
        _imageUrl.text = publicUrl;
        _uploadingCover = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingCover = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cover upload failed: $e')),
      );
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
        searchCtrl: _search,
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
        title: _titleEn.text.trim(),
        titleAr: _nullable(_titleAr),
        description: _descriptionEn.text.trim(),
        descriptionAr: _nullable(_descriptionAr),
        duration: _durationEn.text.trim(),
        durationAr: _nullable(_durationAr),
        category: _category.text.trim().isEmpty
            ? 'General'
            : _category.text.trim(),
        categoryAr: _nullable(_categoryAr),
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
      debugPrint('TourFormScreen save error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coverPreview = _cover.uploadedUrl ?? _imageUrl.text.trim();
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
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary)),
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
                  const SizedBox(height: 18),

                  _label('Title (English)'),
                  TextFormField(
                    controller: _titleEn,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _label('Title (Arabic)'),
                  TextFormField(
                    controller: _titleAr,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: 'عنوان الجولة بالعربي',
                    ),
                  ),
                  const SizedBox(height: 18),

                  _label('Description (English)'),
                  TextFormField(
                    controller: _descriptionEn,
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Description is required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _label('Description (Arabic)'),
                  TextFormField(
                    controller: _descriptionAr,
                    maxLines: 3,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: 'وصف الجولة بالعربي',
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Duration (English)'),
                            TextFormField(
                              controller: _durationEn,
                              decoration: const InputDecoration(
                                hintText: '4 Hours',
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Duration (Arabic)'),
                            TextFormField(
                              controller: _durationAr,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                hintText: '٤ ساعات',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Category / Theme'),
                            TextFormField(
                              controller: _category,
                              decoration: const InputDecoration(
                                hintText: 'Historical, Coastal, Spiritual…',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Category (Arabic)'),
                            TextFormField(
                              controller: _categoryAr,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                hintText: 'تاريخي / ساحلي / روحاني',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  _label('Cover image'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: coverPreview.isEmpty
                              ? Container(
                                  color: AppTheme.bg,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: AppTheme.textSecondary,
                                    size: 28,
                                  ),
                                )
                              : (kIsWeb
                                  ? Image.network(
                                      coverPreview,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                              color: AppTheme.bg,
                                              child: const Icon(
                                                  Icons.broken_image_outlined),
                                            ),
                                    )
                                  : Image.network(
                                      coverPreview,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                              color: AppTheme.bg,
                                              child: const Icon(
                                                  Icons.broken_image_outlined),
                                            ),
                                    )),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed:
                                  _uploadingCover ? null : _pickAndUploadCover,
                              icon: _uploadingCover
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.upload_rounded, size: 18),
                              label: Text(_uploadingCover
                                  ? 'Uploading…'
                                  : 'Upload to Supabase'),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'or paste a URL below',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _imageUrl,
                    decoration: const InputDecoration(
                      hintText: 'https://upload.wikimedia.org/...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Cover image is required'
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),

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
                            color: AppTheme.border,
                            style: BorderStyle.solid),
                      ),
                      child: const Center(
                        child: Text(
                          'No stops yet — tap "Add stops"',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
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
                                icon: const Icon(Icons.close_rounded,
                                    color: AppTheme.danger),
                                onPressed: () => _removePlace(p),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isEditing ? 'Update Tour' : 'Create Tour'),
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
  final TextEditingController searchCtrl;
  const _PlacePickerSheet({
    required this.all,
    required this.initiallySelected,
    required this.searchCtrl,
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
    widget.searchCtrl.addListener(_syncFilter);
  }

  @override
  void dispose() {
    widget.searchCtrl.removeListener(_syncFilter);
    super.dispose();
  }

  void _syncFilter() {
    if (_filter == widget.searchCtrl.text) return;
    setState(() => _filter = widget.searchCtrl.text);
  }

  String _localizedName(Place p) {
    final ar = p.nameAr;
    if (ar != null && ar.isNotEmpty) {
      // Show bilingual for clarity, but trim long descriptions.
      return '${p.name} / $ar';
    }
    return p.name;
  }

  @override
  Widget build(BuildContext context) {
    final q = _filter.toLowerCase();
    final filtered = q.isEmpty
        ? widget.all
        : widget.all
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q) ||
                (p.nameAr?.toLowerCase().contains(q) ?? false))
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
                  controller: widget.searchCtrl,
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
                      title: Text(_localizedName(p),
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