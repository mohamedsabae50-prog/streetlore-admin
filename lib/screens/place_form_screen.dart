import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../models/egypt_governorates.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class PlaceFormScreen extends StatefulWidget {
  final Place? place;
  const PlaceFormScreen({super.key, this.place});
  @override
  State<PlaceFormScreen> createState() => _PlaceFormScreenState();
}

class _PhotoDraft {
  Uint8List? bytes;
}

class _CoverBadge extends StatelessWidget {
  const _CoverBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Cover',
        style: TextStyle(
          color: Theme.of(context).colorScheme.surface,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PlaceFormScreenState extends State<PlaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _id;
  late TextEditingController _name;
  late TextEditingController _nameAr;
  late TextEditingController _description;
  late TextEditingController _descriptionAr;
  late TextEditingController _imageUrl;
  late List<TextEditingController> _imageUrls;
  late TextEditingController _category;
  late TextEditingController _categoryAr;
  late TextEditingController _lat;
  late TextEditingController _lng;
  final MapController _mapController = MapController();
  final GlobalKey _mapKey = GlobalKey();
  LatLng _selectedPoint = LatLng(31.2001, 29.9187);
  bool _mapReady = false;
  bool _isDraggingPin = false;
  bool _updatingCoordinatesFromMap = false;
  late TextEditingController _address;
  late TextEditingController _addressAr;
  late TextEditingController _openHours;
  late TextEditingController _reviewCount;
  late TextEditingController _priceNote;
  late TextEditingController _priceLocal;
  late TextEditingController _priceForeigner;
  late TextEditingController _rating;
  late TextEditingController _displayOrder;
  PriceLevel _priceLevel = PriceLevel.free;
  String _governorate = 'alexandria';
  bool _isHiddenGem = false;
  bool _isFeatured = false;
  bool _enableChat = true;
  bool _enableGallery = true;
  bool _saving = false;
  final List<_PhotoDraft> _primaryImageDrafts = [];

  bool get _isEditing => widget.place != null;

  @override
  void initState() {
    super.initState();
    final p = widget.place;
    _id = TextEditingController(text: p?.id ?? _suggestId());
    _name = TextEditingController(text: p?.name ?? '');
    _nameAr = TextEditingController(text: p?.nameAr ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _descriptionAr = TextEditingController(text: p?.descriptionAr ?? '');
    final initialUrls = <String>[];
    final seenInitialUrls = <String>{};
    for (final value in [p?.imageUrl ?? '', ...?p?.imageUrls]) {
      final url = value.trim();
      if (url.isNotEmpty && seenInitialUrls.add(url)) {
        initialUrls.add(url);
      }
    }
    _imageUrl = TextEditingController(
      text: initialUrls.isNotEmpty ? initialUrls.first : '',
    );
    _imageUrls = initialUrls
        .map((u) => TextEditingController(text: u))
        .toList(growable: true);
    _category = TextEditingController(text: p?.category ?? 'Historical');
    _categoryAr = TextEditingController(text: p?.categoryAr ?? '');
    _lat = TextEditingController(text: (p?.lat ?? 31.2001).toString());
    _lng = TextEditingController(text: (p?.lng ?? 29.9187).toString());
    _selectedPoint = _coordinatesFromFields() ?? _selectedPoint;
    _address = TextEditingController(text: p?.address ?? 'Alexandria, Egypt');
    _addressAr = TextEditingController(text: p?.addressAr ?? '');
    _openHours = TextEditingController(
      text: p?.openHours ?? '9:00 AM - 6:00 PM',
    );
    _reviewCount = TextEditingController(
      text: (p?.reviewCount ?? 0).toString(),
    );
    _priceNote = TextEditingController(text: p?.priceNote ?? '');
    _priceLocal = TextEditingController(
      text: p?.priceLocalEgp?.toString() ?? '',
    );
    _priceForeigner = TextEditingController(
      text: p?.priceForeignerEgp?.toString() ?? '',
    );
    _rating = TextEditingController(text: (p?.rating ?? 0).toString());
    _displayOrder = TextEditingController(
      text: (p?.displayOrder ?? 999).toString(),
    );
    _priceLevel = p?.priceLevel ?? PriceLevel.free;
    _governorate = AdminGovernorate.all.any((g) => g.id == p?.governorate)
        ? p!.governorate
        : 'alexandria';
    _isHiddenGem = p?.isHiddenGem ?? false;
    _isFeatured = p?.isFeatured ?? false;
    _enableChat = p?.enableChat ?? true;
    _enableGallery = p?.enableGallery ?? true;
    _lat.addListener(_onCoordFieldChanged);
    _lng.addListener(_onCoordFieldChanged);
  }

  void _onCoordFieldChanged() {
    if (!mounted || _updatingCoordinatesFromMap) return;
    final point = _coordinatesFromFields();
    if (point != null) {
      _selectedPoint = point;
      if (_mapReady && !_isDraggingPin) {
        _mapController.move(point, _mapController.camera.zoom);
      }
    }
    setState(() {});
  }

  LatLng? _coordinatesFromFields() {
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if (lat == null ||
        lng == null ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      return null;
    }
    return LatLng(lat, lng);
  }

  void _setCoordinatesFromMap(LatLng point) {
    if (!point.latitude.isFinite ||
        !point.longitude.isFinite ||
        point.latitude < -90 ||
        point.latitude > 90 ||
        point.longitude < -180 ||
        point.longitude > 180) {
      return;
    }
    _selectedPoint = point;
    _updatingCoordinatesFromMap = true;
    _lat.text = point.latitude.toStringAsFixed(6);
    _lng.text = point.longitude.toStringAsFixed(6);
    _updatingCoordinatesFromMap = false;
    if (mounted) setState(() {});
  }

  void _centerMapOnPin() {
    if (_mapReady) {
      _mapController.move(_selectedPoint, _mapController.camera.zoom);
    }
  }

  void _updatePinFromDrag(DragUpdateDetails details) {
    final renderObject = _mapKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final localPosition = renderObject.globalToLocal(details.globalPosition);
    _setCoordinatesFromMap(
      _mapController.camera.screenOffsetToLatLng(localPosition),
    );
  }

  bool get _isOffshoreNorthwestOfAlexandria {
    final lat = _selectedPoint.latitude;
    final lng = _selectedPoint.longitude;
    return lat > 31.23 && lat < 31.45 && lng > 29.70 && lng < 29.95;
  }

  String _suggestId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    return 'p_$ts';
  }

  String? _nullable(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<List<_PhotoDraft>> _readPickedFiles(List<XFile> files) async {
    final out = <_PhotoDraft>[];
    final failures = <String>[];
    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          failures.add('${file.name}: selected file was empty');
          continue;
        }
        out.add(_PhotoDraft()..bytes = bytes);
      } catch (error) {
        failures.add('${file.name}: $error');
      }
    }
    if (failures.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not read ${failures.length} selected image(s): '
            '${failures.join('; ')}',
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    }
    return out;
  }

  Future<void> _addPrimaryImage() async {
    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open file picker: $e')));
      return;
    }
    if (picked == null) return;
    final drafts = await _readPickedFiles([picked]);
    if (drafts.isEmpty || !mounted) return;
    setState(() => _primaryImageDrafts.addAll(drafts));
  }

  Future<void> _addMultiplePrimaryImages() async {
    final picker = ImagePicker();
    final List<XFile> picked;
    try {
      picked = await picker.pickMultiImage(
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open file picker: $e')));
      return;
    }
    if (picked.isEmpty) return;
    final drafts = await _readPickedFiles(picked);
    if (drafts.isEmpty || !mounted) return;
    setState(() {
      _primaryImageDrafts.addAll(drafts);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _addOfficialUrlFromPicked() async {
    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open file picker: $e')));
      return;
    }
    if (picked == null) return;
    setState(() => _saving = true);
    try {
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) throw Exception('Picked file is empty');
      final ts = DateTime.now().microsecondsSinceEpoch;
      final id = 'ph_${ts}_off';
      final url = await AdminService.instance.uploadImageBytes(
        bytes,
        'places',
        '$id.jpg',
      );
      if (!mounted) return;
      setState(() {
        _imageUrls.add(TextEditingController(text: url));
        if (_imageUrl.text.trim().isEmpty) _imageUrl.text = url;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _removePrimaryImage(int index) {
    setState(() {
      _primaryImageDrafts.removeAt(index);
    });
  }

  void _removeExistingCover() {
    setState(() {
      final currentCover = _imageUrl.text.trim();
      final coverIndex = _imageUrls.indexWhere(
        (controller) => controller.text.trim() == currentCover,
      );
      if (coverIndex >= 0) {
        _imageUrls.removeAt(coverIndex).dispose();
      }
      _imageUrl.text = _imageUrls
          .map((controller) => controller.text.trim())
          .firstWhere((url) => url.isNotEmpty, orElse: () => '');
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final errors = <String>[];
    final imageUrlsList = _imageUrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .fold<List<String>>(<String>[], (urls, url) {
          if (!urls.contains(url)) urls.add(url);
          return urls;
        });

    final uploadedUrls = <String>[];
    final ts = DateTime.now().microsecondsSinceEpoch;
    var pIdx = 0;
    for (final draft in _primaryImageDrafts) {
      if (draft.bytes == null) continue;
      try {
        final url = await AdminService.instance.uploadImageBytes(
          draft.bytes!,
          'places',
          'place_${ts}_$pIdx.jpg',
        );
        uploadedUrls.add(url);
        pIdx++;
      } catch (e) {
        errors.add('Upload primary #${pIdx + 1}: $e');
      }
    }

    final orderedImageUrls = <String>[];
    final seenImageUrls = <String>{};
    for (final url in [...imageUrlsList, ...uploadedUrls]) {
      if (seenImageUrls.add(url)) orderedImageUrls.add(url);
    }
    final finalImageUrl = orderedImageUrls.isEmpty
        ? ''
        : orderedImageUrls.first;

    // 3) Build the place object with the resolved cover imageUrl.
    final place = Place(
      id: _id.text.trim(),
      name: _name.text.trim(),
      nameAr: _nullable(_nameAr),
      description: _description.text.trim(),
      descriptionAr: _nullable(_descriptionAr),
      imageUrl: finalImageUrl,
      imageUrls: orderedImageUrls,
      rating: double.tryParse(_rating.text) ?? 0,
      category: _category.text.trim(),
      categoryAr: _nullable(_categoryAr),
      lat: double.tryParse(_lat.text) ?? 0,
      lng: double.tryParse(_lng.text) ?? 0,
      address: _address.text.trim(),
      addressAr: _nullable(_addressAr),
      governorate: _governorate,
      openHours: _openHours.text.trim(),
      reviewCount: int.tryParse(_reviewCount.text) ?? 0,
      priceLevel: _priceLevel,
      priceNote: _priceNote.text.trim(),
      priceLocalEgp: int.tryParse(_priceLocal.text.trim()),
      priceForeignerEgp: int.tryParse(_priceForeigner.text.trim()),
      isHiddenGem: _isHiddenGem,
      isFeatured: _isFeatured,
      displayOrder: int.tryParse(_displayOrder.text.trim()) ?? 999,
      enableChat: _enableChat,
      enableGallery: _enableGallery,
    );

    // 4) Persist the place in ONE call (with the new cover, if any).
    try {
      if (_isEditing) {
        await AdminService.instance.updatePlace(place);
      } else {
        await AdminService.instance.createPlace(place);
      }
    } catch (e) {
      errors.insert(0, 'Save place: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            duration: const Duration(seconds: 8),
          ),
        );
      }
      return;
    }

    if (mounted) setState(() => _saving = false);

    if (errors.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved with ${errors.length} error(s): ${errors.first}',
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Place saved successfully')));
    }

    if (!mounted) return;
    Navigator.pop(context, place);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Place' : 'New Place',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isEditing ? 'Update' : 'Create',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section(
              icon: Icons.image_rounded,
              title: 'Images',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add one or more images. The first one is the cover.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addPrimaryImage,
                          icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                          label: const Text('Add image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(44),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addMultiplePrimaryImages,
                          icon: const Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 18,
                          ),
                          label: const Text('Upload multiple'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(44),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildImageGrid(),
                ],
              ),
            ),

            _section(
              icon: Icons.collections_rounded,
              title: 'Official Image URLs',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add direct image URLs for the swipeable gallery shown in the app. These URLs are merged with the uploaded images below and saved to places.image_urls.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._imageUrls.asMap().entries.map(
                    (entry) => _buildOfficialUrlRow(entry.key, entry.value),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addOfficialUrlRow,
                          icon: const Icon(Icons.add_link_rounded, size: 18),
                          label: const Text('Add image URL'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: BorderSide(
                              color: AppTheme.primary.withValues(alpha: 0.5),
                            ),
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addOfficialUrlFromPicked,
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('Upload as URL'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.success,
                            side: BorderSide(
                              color: AppTheme.success.withValues(alpha: 0.5),
                            ),
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            _section(
              icon: Icons.fingerprint_rounded,
              title: 'Identification',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelBilingual('ID', isEn: true),
                  TextFormField(
                    controller: _id,
                    enabled: !_isEditing,
                    decoration: const InputDecoration(hintText: 'p_unique_id'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'ID is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelBilingual('Rating (0-5)', isEn: true),
                            TextFormField(
                              controller: _rating,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: _validateNumber,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelBilingual('Display Order', isEn: true),
                            TextFormField(
                              controller: _displayOrder,
                              keyboardType: TextInputType.number,
                              validator: _validateNumber,
                              decoration: const InputDecoration(
                                hintText: '1, 2, 3… (lower = first)',
                                helperText:
                                    '1 appears first, 2 second, etc. Default 999.',
                                prefixIcon: Icon(
                                  Icons.format_list_numbered_rounded,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelBilingual('Review count', isEn: true),
                            TextFormField(
                              controller: _reviewCount,
                              keyboardType: TextInputType.number,
                              validator: _validateNumber,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelBilingual('Featured', isEn: true),
                            SwitchListTile.adaptive(
                              value: _isFeatured,
                              onChanged: (v) => setState(() => _isFeatured = v),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _labelBilingual('Category', isEn: true),
                  DropdownButtonFormField<String>(
                    initialValue: _category.text.isEmpty
                        ? null
                        : _category.text,
                    items: const [
                      DropdownMenuItem(
                        value: 'Historical',
                        child: Text('Historical'),
                      ),
                      DropdownMenuItem(
                        value: 'Culture',
                        child: Text('Culture'),
                      ),
                      DropdownMenuItem(value: 'Nature', child: Text('Nature')),
                      DropdownMenuItem(value: 'Food', child: Text('Food')),
                      DropdownMenuItem(
                        value: 'Shopping',
                        child: Text('Shopping'),
                      ),
                      DropdownMenuItem(
                        value: 'Mosques',
                        child: Text('Mosques'),
                      ),
                      DropdownMenuItem(
                        value: 'Churches',
                        child: Text('Churches'),
                      ),
                      DropdownMenuItem(
                        value: 'Streets',
                        child: Text('Streets'),
                      ),
                      DropdownMenuItem(value: 'ATM', child: Text('ATM')),
                      DropdownMenuItem(value: 'Hotel', child: Text('Hotel')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _category.text = v);
                      }
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category_rounded),
                      hintText: 'Pick a category',
                    ),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.45),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF3B82F6,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'EN',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'English Content',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Required fields shown in blue. Both English fields are mandatory.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _labelBilingual('Name (English)', isEn: true),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      hintText: 'Qaitbay Citadel',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name (English) is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _labelBilingual('Description (English)', isEn: true),
                  TextFormField(
                    controller: _description,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Full description in English...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Description (English) is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _labelBilingual('Address (English)', isEn: true),
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(
                      hintText: 'Corniche, Anfushi, Alexandria',
                      prefixIcon: Icon(Icons.place_rounded),
                    ),
                  ),
                ],
              ),
            ),

            _section(
              icon: Icons.translate_rounded,
              title: 'Arabic Content',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelBilingual('Name (AR)', isEn: false),
                  TextFormField(
                    controller: _nameAr,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: 'قلعة قايتباي',
                      prefixIcon: Icon(Icons.translate_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _labelBilingual('Description (AR)', isEn: false),
                  TextFormField(
                    controller: _descriptionAr,
                    maxLines: 5,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: 'الوصف بالعربي...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _labelBilingual('Address (AR)', isEn: false),
                  TextFormField(
                    controller: _addressAr,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: 'الكورنيش، الأنفوشي، الإسكندرية',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _labelBilingual('Category (AR)', isEn: false),
                  TextFormField(
                    controller: _categoryAr,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: 'الفئة بالعربي...',
                    ),
                  ),
                ],
              ),
            ),

            _section(
              icon: Icons.location_city_rounded,
              title: 'Governorate (المحافظة)',
              child: DropdownButtonFormField<String>(
                initialValue: _governorate,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                items: [
                  for (final governorate in AdminGovernorate.all)
                    DropdownMenuItem(
                      value: governorate.id,
                      child: Text(
                        '${governorate.nameEn} — ${governorate.nameAr}',
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _governorate = value);
                  if (!_isEditing) {
                    final selected = AdminGovernorate.all.firstWhere(
                      (item) => item.id == value,
                    );
                    final center = LatLng(
                      selected.centerLat,
                      selected.centerLng,
                    );
                    if (_mapReady) {
                      _mapController.move(center, 11);
                    } else {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _mapReady) {
                          _mapController.move(center, 11);
                        }
                      });
                    }
                  }
                },
              ),
            ),
            _section(
              icon: Icons.map_rounded,
              title: 'Location (lat / lng)',
              child: _mapPicker(),
            ),

            _section(
              icon: Icons.access_time_rounded,
              title: 'Operating Hours',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelBilingual('Open Hours', isEn: false),
                  TextFormField(
                    controller: _openHours,
                    decoration: const InputDecoration(
                      hintText: '9:00 AM - 5:00 PM / 9 صباحاً - 5 مساءً',
                      prefixIcon: Icon(Icons.schedule_rounded),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Or "Open 24 hours" / "مفتوح 24 ساعة"',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _section(
              icon: Icons.confirmation_number_rounded,
              title: 'Tickets (EGP)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _priceLevelDropdown(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelBilingual(
                              'Egyptian (Local)',
                              isEn: true,
                              hint: '🇪🇬',
                            ),
                            TextFormField(
                              controller: _priceLocal,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'e.g. 10',
                                prefixIcon: Icon(Icons.local_offer_rounded),
                              ),
                              validator: _validateNumber,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelBilingual(
                              'Tourist (Foreigner)',
                              isEn: true,
                              hint: '🌍',
                            ),
                            TextFormField(
                              controller: _priceForeigner,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'e.g. 60',
                                prefixIcon: Icon(Icons.local_offer_rounded),
                              ),
                              validator: _validateNumber,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Leave empty for free entry. Local price applies to Egyptian/resident ID holders.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _labelBilingual('Price note', isEn: true),
                  TextFormField(
                    controller: _priceNote,
                    decoration: const InputDecoration(
                      hintText: 'EGP 100 adults, EGP 50 students',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            _section(
              icon: Icons.local_offer_rounded,
              title: 'Tags',
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: _isHiddenGem,
                    onChanged: (v) => setState(() => _isHiddenGem = v),
                    title: const Text('Hidden gem'),
                    subtitle: const Text(
                      'Show only when filtering "Hidden Gems"',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile.adaptive(
                    value: _enableChat,
                    onChanged: (v) => setState(() => _enableChat = v),
                    title: const Text('Enable Community Chat'),
                    subtitle: const Text(
                      'Show the chat section on this place details page',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile.adaptive(
                    value: _enableGallery,
                    onChanged: (v) => setState(() => _enableGallery = v),
                    title: const Text('Enable Photo Gallery'),
                    subtitle: const Text(
                      'Show the visitor photo gallery on this place details page',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),
            if (_isEditing && (widget.place?.id ?? _id.text).isNotEmpty)
              _ModerationSection(placeId: widget.place?.id ?? _id.text),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Update Place' : 'Create Place',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _labelBilingual(String text, {required bool isEn, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isEn
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                  : const Color(0xFF22C55E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isEn ? 'EN' : 'AR/EN',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: isEn ? const Color(0xFF3B82F6) : const Color(0xFF22C55E),
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(width: 6),
            Text(hint, style: const TextStyle(fontSize: 14)),
          ],
        ],
      ),
    );
  }

  void _addOfficialUrlRow() {
    setState(() {
      _imageUrls.add(TextEditingController());
    });
  }

  void _removeOfficialUrlRow(int index) {
    setState(() {
      _imageUrls.removeAt(index).dispose();
      _imageUrl.text = _imageUrls
          .map((controller) => controller.text.trim())
          .firstWhere((url) => url.isNotEmpty, orElse: () => '');
    });
  }

  void _moveOfficialUrlRow(int index, int delta) {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _imageUrls.length) return;
    setState(() {
      final c = _imageUrls.removeAt(index);
      _imageUrls.insert(newIndex, c);
      _imageUrl.text = _imageUrls
          .map((controller) => controller.text.trim())
          .firstWhere((url) => url.isNotEmpty, orElse: () => '');
    });
  }

  Widget _buildOfficialUrlRow(int index, TextEditingController controller) {
    final url = controller.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Position badge / reorder
          Container(
            width: 30,
            margin: const EdgeInsets.only(top: 6),
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? AppTheme.primary
                        : AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: index == 0 ? Colors.white : AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (index == 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Cover',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Thumbnail + text field column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: url.isEmpty
                            ? Container(
                                color: AppTheme.border,
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 18,
                                  color: AppTheme.textSecondary,
                                ),
                              )
                            : Image.network(
                                url,
                                cacheWidth: 96,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                errorBuilder: (_, _, _) => Container(
                                  color: AppTheme.border,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 18,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        onChanged: (value) {
                          if (index == 0) _imageUrl.text = value.trim();
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'https://.../image.jpg',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Reorder + delete row
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                        visualDensity: VisualDensity.compact,
                        onPressed: index == 0
                            ? null
                            : () => _moveOfficialUrlRow(index, -1),
                        tooltip: 'Move up',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 16,
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: index == _imageUrls.length - 1
                            ? null
                            : () => _moveOfficialUrlRow(index, 1),
                        tooltip: 'Move down',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _removeOfficialUrlRow(index),
                        tooltip: 'Remove',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    final hasCover = _imageUrl.text.isNotEmpty;
    final children = <Widget>[];

    if (hasCover) {
      children.add(_buildCoverTile());
    } else if (_primaryImageDrafts.isEmpty) {
      children.add(
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: AppTheme.textSecondary,
                ),
                SizedBox(height: 6),
                Text(
                  'Add at least one image',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    for (var i = 0; i < _primaryImageDrafts.length; i++) {
      final isFirst = !hasCover && i == 0;
      children.add(_buildPrimaryDraftTile(i, isFirst));
    }

    if (children.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.4,
      children: children,
    );
  }

  Widget _buildCoverTile() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.bg,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_imageUrl.text.isNotEmpty)
              Image.network(
                _imageUrl.text,
                cacheWidth: 480,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Loading cover image…',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (_, error, _) => Container(
                  color: AppTheme.bg,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Image failed to load',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _imageUrl.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'No cover image',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            const Positioned(top: 8, left: 8, child: _CoverBadge()),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.55),
                  padding: const EdgeInsets.all(6),
                ),
                onPressed: _removeExistingCover,
                tooltip: 'Remove cover',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryDraftTile(int index, bool isCover) {
    final draft = _primaryImageDrafts[index];
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: draft.bytes != null
                ? Image.memory(
                    draft.bytes!,
                    cacheWidth: 320,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) => Container(
                      color: AppTheme.bg,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppTheme.textSecondary,
                          size: 32,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppTheme.bg,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
          ),
        ),
        if (isCover) const Positioned(top: 6, left: 6, child: _CoverBadge()),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(4),
            ),
            onPressed: () => _removePrimaryImage(index),
            tooltip: 'Remove',
          ),
        ),
      ],
    );
  }

  Widget _mapPicker() {
    final point = _coordinatesFromFields() ?? _selectedPoint;
    final lat = point.latitude;
    final lng = point.longitude;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pick location on map',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.touch_app_rounded,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'tap the map or drag the pin',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _lat,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Latitude (lat)',
                  hintText: '31.200100',
                  prefixIcon: Icon(Icons.north_rounded),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _lng,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Longitude (lng)',
                  hintText: '29.918700',
                  prefixIcon: Icon(Icons.east_rounded),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            key: _mapKey,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: point,
                initialZoom: 13,
                onMapReady: () => _mapReady = true,
                onTap: (tapPosition, latLng) {
                  _setCoordinatesFromMap(latLng);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.streetlore.admin',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (_) => _isDraggingPin = true,
                        onPanUpdate: _updatePinFromDrag,
                        onPanEnd: (_) => _isDraggingPin = false,
                        onPanCancel: () => _isDraggingPin = false,
                        child: Icon(
                          Icons.location_on_rounded,
                          color: AppTheme.danger,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _centerMapOnPin,
              icon: const Icon(Icons.my_location_rounded, size: 16),
              label: const Text('Center on Pin'),
            ),
            if (_isOffshoreNorthwestOfAlexandria)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'This pin may be offshore in the Mediterranean Sea. '
                        'Check that it is on land.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _priceLevelDropdown() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _labelBilingual('Price level', isEn: true),
      DropdownButtonFormField<PriceLevel>(
        initialValue: _priceLevel,
        items: const [
          DropdownMenuItem(value: PriceLevel.free, child: Text('Free')),
          DropdownMenuItem(value: PriceLevel.cheap, child: Text('Cheap')),
          DropdownMenuItem(value: PriceLevel.moderate, child: Text('Moderate')),
          DropdownMenuItem(
            value: PriceLevel.expensive,
            child: Text('Expensive'),
          ),
        ],
        onChanged: (v) {
          if (v != null) {
            setState(() => _priceLevel = v);
          }
        },
        decoration: const InputDecoration(),
      ),
    ],
  );

  String? _validateNumber(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return double.tryParse(v) == null ? 'Invalid number' : null;
  }

  @override
  void dispose() {
    _lat.removeListener(_onCoordFieldChanged);
    _lng.removeListener(_onCoordFieldChanged);
    _lat.dispose();
    _lng.dispose();
    _mapController.dispose();
    for (final c in _imageUrls) {
      c.dispose();
    }
    super.dispose();
  }
}

class _ModerationSection extends StatefulWidget {
  final String placeId;
  const _ModerationSection({required this.placeId});

  @override
  State<_ModerationSection> createState() => _ModerationSectionState();
}

class _ModerationSectionState extends State<_ModerationSection> {
  bool _loading = false;
  List<ChatMessage> _messages = const <ChatMessage>[];
  List<PlacePhoto> _photos = const <PlacePhoto>[];
  String? _error;
  DateTime? _lastFetched;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = AdminService.instance;
      debugPrint(
        '_ModerationSection._refresh: placeId=${widget.placeId} '
        '(runtime type=${widget.placeId.runtimeType})',
      );
      final msgs = await svc.fetchChatMessages(widget.placeId);
      final photos = await svc.fetchPhotos(placeId: widget.placeId);
      debugPrint(
        '_ModerationSection._refresh: fetched '
        '${msgs.length} chat messages, ${photos.length} photos for '
        'placeId=${widget.placeId}',
      );
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _photos = photos;
        _loading = false;
        _lastFetched = DateTime.now();
      });
    } catch (e) {
      debugPrint('_ModerationSection._refresh error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _deleteMessage(ChatMessage m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: Text(
          'This will permanently remove the message from "${m.userName}".\n\n'
          '"${m.text}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppTheme.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    try {
      await AdminService.instance.deleteChatMessage(m.id);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete message: $e')));
    }
  }

  Future<void> _deletePhoto(PlacePhoto p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete photo?'),
        content: Text(
          'This will permanently remove the photo uploaded by '
          '"${p.userName}".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppTheme.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    try {
      await AdminService.instance.deletePhoto(p.id);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete photo: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.danger.withValues(alpha: 0.4),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.danger, size: 18),
              const SizedBox(width: 8),
              Text(
                'Moderation',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : _refresh,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Granular per-room moderation. Delete any chat message or user-uploaded photo from this place.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          if (_lastFetched != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Last refreshed ${_lastFetched!.hour.toString().padLeft(2, '0')}:'
                '${_lastFetched!.minute.toString().padLeft(2, '0')}:'
                '${_lastFetched!.second.toString().padLeft(2, '0')}'
                ' • id=${widget.placeId}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          const SizedBox(height: 14),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppTheme.danger, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppTheme.danger, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          _Subsection(
            title: 'Chat messages',
            count: _messages.length,
            icon: Icons.chat_bubble_outline_rounded,
            child: _messages.isEmpty
                ? _EmptyHint(text: 'No chat messages yet for this place.')
                : Column(
                    children: [
                      for (final m in _messages)
                        _MessageRow(
                          key: ValueKey('msg_${m.id}'),
                          message: m,
                          onDelete: () => _deleteMessage(m),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          _Subsection(
            title: 'User photos',
            count: _photos.length,
            icon: Icons.photo_library_outlined,
            child: _photos.isEmpty
                ? _EmptyHint(
                    text: 'No user-uploaded photos yet for this place.',
                  )
                : Column(
                    children: [
                      for (final p in _photos)
                        _PhotoRow(
                          key: ValueKey('photo_${p.id}'),
                          photo: p,
                          onDelete: () => _deletePhoto(p),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Subsection extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Widget child;
  const _Subsection({
    required this.title,
    required this.count,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onDelete;
  const _MessageRow({super.key, required this.message, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.userName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fmtTime(message.sentAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message.text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Delete message',
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.danger,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

class _PhotoRow extends StatelessWidget {
  final PlacePhoto photo;
  final VoidCallback onDelete;
  const _PhotoRow({super.key, required this.photo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: photo.imageUrl.startsWith('data:')
                  ? Image.memory(
                      _decodeDataUri(photo.imageUrl),
                      cacheWidth: 128,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (context, _, _) => _brokenThumb(context),
                    )
                  : Image.network(
                      photo.imageUrl,
                      cacheWidth: 128,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (context, _, _) => _brokenThumb(context),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.userName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (photo.captionEn.isNotEmpty || photo.captionAr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      photo.captionEn.isNotEmpty
                          ? photo.captionEn
                          : photo.captionAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  '${photo.likes} ❤',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Delete photo',
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.danger,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _brokenThumb(BuildContext context) => Container(
    color: const Color(0xFF1C2433),
    child: Icon(
      Icons.image_not_supported_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      size: 24,
    ),
  );

  Uint8List _decodeDataUri(String uri) {
    try {
      final comma = uri.indexOf(',');
      final b64 = comma >= 0 ? uri.substring(comma + 1) : uri;
      return Uint8List.fromList(base64Decode(b64));
    } catch (_) {
      return Uint8List(0);
    }
  }
}
