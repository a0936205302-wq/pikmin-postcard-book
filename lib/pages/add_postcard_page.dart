import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/postcard.dart';
import '../services/postcard_service.dart';

class AddPostcardPage extends StatefulWidget {
  const AddPostcardPage({super.key, required this.postcardService});

  final PostcardService postcardService;

  @override
  State<AddPostcardPage> createState() => _AddPostcardPageState();
}

class _AddPostcardPageState extends State<AddPostcardPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _coordinatesController = TextEditingController();
  final _imagePicker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  PostcardCategory _selectedCategory = PostcardCategory.mushroom;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _coordinatesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImage = image;
      _selectedImageBytes = bytes;
    });
  }

  ({double lat, double lng})? _parseCoordinates(String input) {
    final normalized = input.replaceAll('，', ',').trim();
    final parts = normalized.split(',');
    if (parts.length != 2) {
      return null;
    }

    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());

    if (lat == null || lng == null) {
      return null;
    }

    return (lat: lat, lng: lng);
  }

  Future<void> _save() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先選擇圖片')));
      return;
    }

    final coordinates = _parseCoordinates(_coordinatesController.text);
    if (coordinates == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請輸入正確的座標格式')));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
    });

    try {
      await widget.postcardService.addPostcard(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        lat: coordinates.lat,
        lng: coordinates.lng,
        imageFile: _selectedImage!,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('儲存失敗：$error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新增明信片')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _selectedImageBytes == null
                          ? const Center(child: Text('尚未選擇圖片'))
                          : Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('選擇圖片'),
                ),
                const SizedBox(height: 20),
                Text(
                  '免費版會先自動壓縮大圖，並另外產生縮圖。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SegmentedButton<PostcardCategory>(
                  segments: const [
                    ButtonSegment(
                      value: PostcardCategory.mushroom,
                      label: Text('菇點'),
                    ),
                    ButtonSegment(
                      value: PostcardCategory.flower,
                      label: Text('花點'),
                    ),
                  ],
                  selected: {_selectedCategory},
                  onSelectionChanged: _isSaving
                      ? null
                      : (selection) {
                          setState(() {
                            _selectedCategory = selection.first;
                          });
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(labelText: '名稱'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '請輸入名稱';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _coordinatesController,
                  enabled: !_isSaving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: '座標'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '請輸入座標';
                    }
                    if (_parseCoordinates(value) == null) {
                      return '格式請使用：24.1677864409, 120.7028962299';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('儲存'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
