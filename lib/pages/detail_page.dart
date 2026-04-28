import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/postcard.dart';
import '../services/map_launcher_service.dart';
import '../services/postcard_service.dart';
import '../widgets/postcard_image_widget.dart';
import '../widgets/postcard_tag_editor.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({
    super.key,
    required this.postcard,
    required this.postcardService,
  });

  final Postcard postcard;
  final PostcardService postcardService;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Postcard _postcard;
  late TextEditingController _nameController;
  late TextEditingController _coordinatesController;
  PostcardCategory? _editingCategory;
  List<String> _editingTags = <String>[];
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUpdatingOwned = false;

  @override
  void initState() {
    super.initState();
    _postcard = widget.postcard;
    _nameController = TextEditingController(text: _postcard.name);
    _coordinatesController = TextEditingController(
      text: _postcard.coordinatesText,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _coordinatesController.dispose();
    super.dispose();
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

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _nameController.text = _postcard.name;
      _coordinatesController.text = _postcard.coordinatesText;
      _editingCategory = _postcard.category == PostcardCategory.unknown
          ? null
          : _postcard.category;
      _editingTags = List<String>.from(_postcard.tags);
    });
  }

  void _cancelEditing() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isEditing = false;
      _nameController.text = _postcard.name;
      _coordinatesController.text = _postcard.coordinatesText;
      _editingCategory = null;
      _editingTags = <String>[];
    });
  }

  Future<void> _saveEditing() async {
    final parsedCoordinates = _parseCoordinates(_coordinatesController.text);
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('名稱不能空白')));
      return;
    }

    if (parsedCoordinates == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請輸入正確座標，格式為 lat, lng')));
      return;
    }

    if (_editingCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請選擇分類')));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
    });

    try {
      await widget.postcardService.updatePostcard(
        id: _postcard.id,
        name: _nameController.text.trim(),
        category: _editingCategory!,
        lat: parsedCoordinates.lat,
        lng: parsedCoordinates.lng,
        tags: _editingTags,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _postcard = _postcard.copyWith(
          name: _nameController.text.trim(),
          category: _editingCategory!,
          lat: parsedCoordinates.lat,
          lng: parsedCoordinates.lng,
          tags: List<String>.from(_editingTags),
        );
        _isEditing = false;
        _editingCategory = null;
        _editingTags = <String>[];
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('明信片已更新')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新失敗：$error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _toggleOwned(bool value) async {
    if (_isUpdatingOwned) {
      return;
    }

    setState(() {
      _isUpdatingOwned = true;
    });

    try {
      await widget.postcardService.setOwned(id: _postcard.id, owned: value);
      if (!mounted) {
        return;
      }

      setState(() {
        _postcard = _postcard.copyWith(owned: value);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新已擁有狀態失敗：$error')));
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingOwned = false;
        });
      }
    }
  }

  Future<void> _openGoogleMaps() async {
    try {
      await const MapLauncherService().openGoogleMaps(
        lat: _postcard.lat,
        lng: _postcard.lng,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _openBlueMap() async {
    try {
      await const MapLauncherService().openBlueMap(
        lat: _postcard.lat,
        lng: _postcard.lng,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Widget _buildCategoryEditor() {
    if (!_isEditing) {
      return Text(
        _postcard.category.label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return DropdownButtonFormField<PostcardCategory>(
      initialValue: _editingCategory,
      items: const [
        DropdownMenuItem(value: PostcardCategory.mushroom, child: Text('菇點')),
        DropdownMenuItem(value: PostcardCategory.flower, child: Text('花點')),
      ],
      onChanged: _isSaving
          ? null
          : (value) {
              setState(() {
                _editingCategory = value;
              });
            },
      decoration: const InputDecoration(labelText: '分類'),
    );
  }

  Widget _buildNameEditor() {
    if (!_isEditing) {
      return Text(
        _postcard.name,
        style: Theme.of(context).textTheme.headlineSmall,
      );
    }

    return TextField(
      controller: _nameController,
      enabled: !_isSaving,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(labelText: '名稱'),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('標籤', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (_postcard.tags.isEmpty)
          Text('目前沒有標籤', style: Theme.of(context).textTheme.bodyMedium)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _postcard.tags)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(Postcard.displayTag(tag)),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildCoordinatesEditor() {
    if (!_isEditing) {
      return SelectableText(
        '座標：${_postcard.coordinatesText}',
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }

    return TextField(
      controller: _coordinatesController,
      enabled: !_isSaving,
      textInputAction: TextInputAction.done,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: const InputDecoration(labelText: '座標'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final imageHeight = _isEditing ? 150.0 : 280.0;

    return Scaffold(
      appBar: AppBar(title: const Text('明信片詳情')),
      body: SafeArea(
        child: StreamBuilder<List<String>>(
          stream: widget.postcardService.watchAvailableTags(),
          builder: (context, snapshot) {
            final availableTags = snapshot.data ?? kBuiltInPostcardTags;

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: imageHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Center(
                            child: PostcardImageWidget(
                              imageBytes: _postcard.imageBytes,
                              thumbnailBytes: _postcard.thumbnailBytes,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (_isEditing) ...[
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _saveEditing,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(_isSaving ? '儲存中' : '儲存'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _isSaving ? null : _cancelEditing,
                            child: const Text('取消'),
                          ),
                        ] else
                          OutlinedButton.icon(
                            onPressed: _startEditing,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('編輯'),
                          ),
                        const Spacer(),
                        Checkbox(
                          value: _postcard.owned,
                          onChanged: _isUpdatingOwned
                              ? null
                              : (value) {
                                  if (value != null) {
                                    _toggleOwned(value);
                                  }
                                },
                        ),
                        const Text('已擁有'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildNameEditor(),
                    const SizedBox(height: 12),
                    _buildCategoryEditor(),
                    const SizedBox(height: 12),
                    if (_isEditing)
                      PostcardTagEditor(
                        selectedTags: _editingTags,
                        availableTags: availableTags,
                        enabled: !_isSaving,
                        onChanged: (tags) {
                          setState(() {
                            _editingTags = tags;
                          });
                        },
                        labelText: '標籤',
                      )
                    else
                      _buildTagsSection(),
                    const SizedBox(height: 12),
                    _buildCoordinatesEditor(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(
                            ClipboardData(text: _postcard.coordinatesText),
                          );
                          if (!mounted) {
                            return;
                          }

                          messenger.showSnackBar(
                            const SnackBar(content: Text('已複製座標')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('複製座標'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openGoogleMaps,
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Google Maps'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openBlueMap,
                            icon: const Icon(Icons.navigation_outlined),
                            label: const Text('藍色地圖'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
