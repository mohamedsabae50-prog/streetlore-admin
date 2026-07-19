import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class PhotoFormScreen extends StatefulWidget {
  final PlacePhoto? photo;
  final String? placeId;
  const PhotoFormScreen({super.key, this.photo, this.placeId});
  @override
  State<PhotoFormScreen> createState() => _PhotoFormScreenState();
}

class _PhotoFormScreenState extends State<PhotoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _id;
  late TextEditingController _userName;
  late TextEditingController _captionAr;
  late TextEditingController _captionEn;
  late TextEditingController _likes;
  List<Place> _places = [];
  String? _selectedPlaceId;
  bool _loading = true;
  bool _saving = false;
  Uint8List? _pickedBytes;
  String _pickedExt = 'jpg';

  bool get _isEditing => widget.photo != null;

  @override
  void initState() {
    super.initState();
    final ph = widget.photo;
    _id = TextEditingController(
        text: ph?.id ?? 'ph_${DateTime.now().millisecondsSinceEpoch}');
    _userName = TextEditingController(text: ph?.userName ?? 'Streetlore');
    _captionAr = TextEditingController(text: ph?.captionAr ?? '');
    _captionEn = TextEditingController(text: ph?.captionEn ?? '');
    _likes = TextEditingController(text: (ph?.likes ?? 0).toString());
    _selectedPlaceId = ph?.placeId ?? widget.placeId;
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final list = await AdminService.instance.fetchPlaces();
      if (!mounted) return;
      setState(() {
        _places = list;
        _loading = false;
        if (_selectedPlaceId != null &&
            !_places.any((p) => p.id == _selectedPlaceId)) {
          _selectedPlaceId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load places: $e')));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.contains('.')
        ? picked.name.split('.').last.toLowerCase()
        : 'jpg';
    setState(() {
      _pickedBytes = bytes;
      _pickedExt = ext;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final existingUrl = widget.photo?.imageUrl ?? '';
    if (_pickedBytes == null && existingUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Upload a photo from your device first')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      String imageUrl = existingUrl;
      if (_pickedBytes != null) {
        final fileName = '${_id.text.trim()}.$_pickedExt';
        imageUrl = await AdminService.instance.uploadImageBytes(
          _pickedBytes!,
          'place-photos',
          fileName,
          contentType: _pickedExt == 'png' ? 'image/png' : 'image/jpeg',
        );
      }
      final photo = PlacePhoto(
        id: _id.text.trim(),
        placeId: _selectedPlaceId!,
        userName: _userName.text.trim().isEmpty
            ? 'Streetlore'
            : _userName.text.trim(),
        imageUrl: imageUrl,
        captionAr: _captionAr.text.trim(),
        captionEn: _captionEn.text.trim(),
        likes: int.tryParse(_likes.text.trim()) ?? 0,
        createdAt: widget.photo?.createdAt,
      );
      if (_isEditing) {
        await AdminService.instance.updatePhoto(photo);
      } else {
        await AdminService.instance.createPhoto(photo);
      }
      if (!mounted) return;
      Navigator.pop(context, photo);
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
        title: Text(_isEditing ? 'Edit Photo' : 'New Photo',
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
                  _imagePreview(),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                    label: Text(_pickedBytes == null
                        ? 'Upload image'
                        : 'Replace image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surface,
                      foregroundColor: AppTheme.primary,
                      elevation: 0,
                      side: const BorderSide(color: AppTheme.border),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _label('Place'),
                  DropdownButtonFormField<String>(
                    value: _selectedPlaceId,
                    items: _places
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedPlaceId = v),
                    decoration:
                        const InputDecoration(hintText: 'Choose a place'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Place is required' : null,
                  ),
                  const SizedBox(height: 14),
                  _label('Username'),
                  TextFormField(
                    controller: _userName,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Sara the Cartographer',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Username is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _label('Caption — Arabic'),
                  TextFormField(
                    controller: _captionAr,
                    maxLines: 3,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: 'اكتب الكابشن بالعربي...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('Caption — English'),
                  TextFormField(
                    controller: _captionEn,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Write the caption in English...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('Likes'),
                  TextFormField(
                    controller: _likes,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '0'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return int.tryParse(v.trim()) == null
                          ? 'Invalid number'
                          : null;
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
                        : Text(_isEditing ? 'Update Photo' : 'Create Photo'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _imagePreview() {
    if (_pickedBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_pickedBytes!, height: 180, fit: BoxFit.cover),
      );
    }
    final existingUrl = widget.photo?.imageUrl ?? '';
    if (existingUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          existingUrl,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 180,
            color: AppTheme.bg,
            child: const Center(
              child: Text('Image failed to load',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ),
        ),
      );
    }
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined,
                size: 56, color: AppTheme.textSecondary),
            SizedBox(height: 6),
            Text('No image',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      );
}
