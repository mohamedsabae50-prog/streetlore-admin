import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class PlaceFormScreen extends StatefulWidget {
  final Place? place;
  const PlaceFormScreen({super.key, this.place});
  @override
  State<PlaceFormScreen> createState() => _PlaceFormScreenState();
}

class _PlaceFormScreenState extends State<PlaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _id;
  late TextEditingController _name;
  late TextEditingController _description;
  late TextEditingController _imageUrl;
  late TextEditingController _category;
  late TextEditingController _lat;
  late TextEditingController _lng;
  late TextEditingController _address;
  late TextEditingController _openHours;
  late TextEditingController _reviewCount;
  late TextEditingController _priceNote;
  late TextEditingController _priceLocal;
  late TextEditingController _priceForeigner;
  late TextEditingController _rating;
  PriceLevel _priceLevel = PriceLevel.free;
  bool _isHiddenGem = false;
  bool _isFeatured = false;
  bool _saving = false;
  Uint8List? _pickedBytes;
  String _pickedExt = 'jpg';

  Uint8List? _photoBytes;
  String _photoExt = 'jpg';
  late TextEditingController _photoUserName;
  late TextEditingController _photoCaptionAr;
  late TextEditingController _photoCaptionEn;

  bool get _isEditing => widget.place != null;

  @override
  void initState() {
    super.initState();
    final p = widget.place;
    _id = TextEditingController(text: p?.id ?? _suggestId());
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _imageUrl = TextEditingController(text: p?.imageUrl ?? '');
    _category = TextEditingController(text: p?.category ?? 'Historical');
    _lat = TextEditingController(text: (p?.lat ?? 31.2).toString());
    _lng = TextEditingController(text: (p?.lng ?? 29.9).toString());
    _address = TextEditingController(text: p?.address ?? 'Alexandria, Egypt');
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
    _priceLevel = p?.priceLevel ?? PriceLevel.free;
    _isHiddenGem = p?.isHiddenGem ?? false;
    _isFeatured = p?.isFeatured ?? false;
    _photoUserName = TextEditingController(text: 'Streetlore');
    _photoCaptionAr = TextEditingController();
    _photoCaptionEn = TextEditingController();
    // typing coordinates manually also moves the map marker
    _lat.addListener(_onCoordFieldChanged);
    _lng.addListener(_onCoordFieldChanged);
  }

  void _onCoordFieldChanged() {
    if (mounted) setState(() {});
  }

  String _suggestId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    return 'p_$ts';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_camera_rounded,
                color: AppTheme.primary,
              ),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppTheme.success,
              ),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, maxWidth: 1600);
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

  Future<void> _pickCommunityPhoto() async {
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
      _photoBytes = bytes;
      _photoExt = ext;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final wantsPhoto =
        _photoBytes != null ||
        _photoCaptionAr.text.trim().isNotEmpty ||
        _photoCaptionEn.text.trim().isNotEmpty;
    if (wantsPhoto && _photoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload the community photo from your device first'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      String imageUrl = _imageUrl.text.trim();
      if (_pickedBytes != null) {
        final fileName = '${_id.text.trim()}.$_pickedExt';
        imageUrl = await AdminService.instance.uploadImageBytes(
          _pickedBytes!,
          'places',
          fileName,
          contentType: _pickedExt == 'png' ? 'image/png' : 'image/jpeg',
        );
      }
      final place = Place(
        id: _id.text.trim(),
        name: _name.text.trim(),
        description: _description.text.trim(),
        imageUrl: imageUrl,
        rating: double.tryParse(_rating.text) ?? 0,
        category: _category.text.trim(),
        lat: double.tryParse(_lat.text) ?? 0,
        lng: double.tryParse(_lng.text) ?? 0,
        address: _address.text.trim(),
        openHours: _openHours.text.trim(),
        reviewCount: int.tryParse(_reviewCount.text) ?? 0,
        priceLevel: _priceLevel,
        priceNote: _priceNote.text.trim(),
        priceLocalEgp: int.tryParse(_priceLocal.text.trim()),
        priceForeignerEgp: int.tryParse(_priceForeigner.text.trim()),
        isHiddenGem: _isHiddenGem,
        isFeatured: _isFeatured,
      );
      if (_isEditing) {
        await AdminService.instance.updatePlace(place);
      } else {
        await AdminService.instance.createPlace(place);
      }

      // Optional community photo -> place_photos table
      String? photoError;
      if (wantsPhoto) {
        try {
          final photoId = 'ph_${DateTime.now().millisecondsSinceEpoch}';
          final photoImageUrl = await AdminService.instance.uploadImageBytes(
            _photoBytes!,
            'place-photos',
            '$photoId.$_photoExt',
            contentType: _photoExt == 'png' ? 'image/png' : 'image/jpeg',
          );
          await AdminService.instance.createPhoto(
            PlacePhoto(
              id: photoId,
              placeId: place.id,
              userName: _photoUserName.text.trim().isEmpty
                  ? 'Streetlore'
                  : _photoUserName.text.trim(),
              imageUrl: photoImageUrl,
              captionAr: _photoCaptionAr.text.trim(),
              captionEn: _photoCaptionEn.text.trim(),
            ),
          );
        } catch (e) {
          photoError = '$e';
        }
      }

      if (!mounted) return;
      if (photoError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Place saved, but the photo failed: $photoError'),
          ),
        );
      }
      Navigator.pop(context, place);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Place' : 'New Place',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
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
            _imagePreview(),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_a_photo_rounded, size: 18),
              label: Text(
                _pickedBytes == null
                    ? 'Upload image (optional)'
                    : 'Replace image',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surface,
                foregroundColor: AppTheme.primary,
                elevation: 0,
                side: const BorderSide(color: AppTheme.border),
              ),
            ),
            const SizedBox(height: 22),
            _label('ID'),
            TextFormField(
              controller: _id,
              enabled: !_isEditing,
              decoration: const InputDecoration(hintText: 'p_unique_id'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'ID is required' : null,
            ),
            const SizedBox(height: 14),
            _label('Name'),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(hintText: 'Qaitbay Citadel'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            _label('Description'),
            TextFormField(
              controller: _description,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Full description in Arabic or English...',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 14),
            _label('Image URL (if not uploading)'),
            TextFormField(
              controller: _imageUrl,
              decoration: const InputDecoration(
                hintText: 'https://images.unsplash.com/...',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _categoryDropdown()),
                const SizedBox(width: 12),
                Expanded(child: _priceLevelDropdown()),
              ],
            ),
            const SizedBox(height: 14),
            _mapPicker(),
            const SizedBox(height: 14),
            _label('Address'),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                hintText: 'Corniche, Anfushi, Alexandria',
              ),
            ),
            const SizedBox(height: 14),
            _label('Open Hours'),
            TextFormField(
              controller: _openHours,
              decoration: const InputDecoration(hintText: '9:00 AM - 5:00 PM'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Rating (0-5)'),
                      TextFormField(
                        controller: _rating,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
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
                      _label('Review count'),
                      TextFormField(
                        controller: _reviewCount,
                        keyboardType: TextInputType.number,
                        validator: _validateNumber,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _label('Price note'),
            TextFormField(
              controller: _priceNote,
              decoration: const InputDecoration(
                hintText: 'EGP 100 adults, EGP 50 students',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Price — local (EGP)'),
                      TextFormField(
                        controller: _priceLocal,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'e.g. 10'),
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
                      _label('Price — foreigner (EGP)'),
                      TextFormField(
                        controller: _priceForeigner,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'e.g. 60'),
                        validator: _validateNumber,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 32),
            const Row(
              children: [
                Icon(
                  Icons.photo_library_rounded,
                  size: 18,
                  color: AppTheme.warning,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Community photo (optional)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Saved to the place's gallery (place_photos) with Arabic & English captions.",
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            _photoPreview(),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickCommunityPhoto,
              icon: const Icon(Icons.add_a_photo_rounded, size: 18),
              label: Text(
                _photoBytes == null ? 'Upload photo' : 'Replace photo',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surface,
                foregroundColor: AppTheme.warning,
                elevation: 0,
                side: const BorderSide(color: AppTheme.border),
              ),
            ),
            const SizedBox(height: 14),
            _label('Username'),
            TextFormField(
              controller: _photoUserName,
              decoration: const InputDecoration(
                hintText: 'e.g. Sara the Cartographer',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            _label('Caption — Arabic'),
            TextFormField(
              controller: _photoCaptionAr,
              maxLines: 2,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'اكتب الكابشن بالعربي...',
              ),
            ),
            const SizedBox(height: 14),
            _label('Caption — English'),
            TextFormField(
              controller: _photoCaptionEn,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Write the caption in English...',
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              value: _isHiddenGem,
              onChanged: (v) => setState(() => _isHiddenGem = v),
              title: const Text('Hidden gem'),
              subtitle: const Text('Show only when filtering "Hidden Gems"'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile.adaptive(
              value: _isFeatured,
              onChanged: (v) => setState(() => _isFeatured = v),
              title: const Text('Featured'),
              subtitle: const Text('Show on the home carousel'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Update Place' : 'Create Place'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview() {
    String? url;
    if (_pickedBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_pickedBytes!, height: 180, fit: BoxFit.cover),
      );
    }
    if (_imageUrl.text.isNotEmpty) {
      url = _imageUrl.text;
    }
    if (url == null) {
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
              Icon(
                Icons.image_outlined,
                size: 56,
                color: AppTheme.textSecondary,
              ),
              SizedBox(height: 6),
              Text('No image', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 180,
          color: AppTheme.bg,
          child: const Center(
            child: Text(
              'Image failed to load',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoPreview() {
    if (_photoBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_photoBytes!, height: 140, fit: BoxFit.cover),
      );
    }
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 6),
            Text(
              'No photo selected',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapPicker() {
    final lat = double.tryParse(_lat.text.trim()) ?? 31.2001;
    final lng = double.tryParse(_lng.text.trim()) ?? 29.9187;
    final point = LatLng(lat, lng);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _label('Pick location on map'),
            const Spacer(),
            const Icon(Icons.touch_app_rounded,
                size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            const Text(
              'tap to set coordinates',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 13,
                onTap: (tapPosition, latLng) {
                  setState(() {
                    _lat.text = latLng.latitude.toStringAsFixed(6);
                    _lng.text = latLng.longitude.toStringAsFixed(6);
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.streetlore.admin',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.danger,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.my_location_rounded,
                size: 13, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
              style: const TextStyle(
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

  Widget _categoryDropdown() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('Category'),
      DropdownButtonFormField<String>(
        value: _category.text,
        items: const [
          DropdownMenuItem(value: 'Historical', child: Text('Historical')),
          DropdownMenuItem(value: 'Culture', child: Text('Culture')),
          DropdownMenuItem(value: 'Nature', child: Text('Nature')),
          DropdownMenuItem(value: 'Food', child: Text('Food')),
        ],
        onChanged: (v) {
          if (v != null) {
            setState(() => _category.text = v);
          }
        },
        decoration: const InputDecoration(),
      ),
    ],
  );

  Widget _priceLevelDropdown() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('Price level'),
      DropdownButtonFormField<PriceLevel>(
        value: _priceLevel,
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
}
