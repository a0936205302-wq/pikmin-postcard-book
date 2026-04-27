import 'package:flutter/material.dart';

import '../models/postcard.dart';
import '../services/postcard_service.dart';
import '../widgets/postcard_grid_item.dart';
import 'add_postcard_page.dart';
import 'detail_page.dart';

enum _SearchMode { name, tag }

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.postcardService});

  final PostcardService postcardService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<String> _selectedIds = <String>{};

  bool _hideOwned = false;
  _SearchMode _searchMode = _SearchMode.name;
  String _searchKeyword = '';
  List<String> _searchTags = <String>[];

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    if (_selectedIds.isEmpty) {
      return;
    }

    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _confirmDelete() async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('刪除明信片'),
          content: Text('確定要刪除 ${_selectedIds.length} 張明信片嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('刪除'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final ids = _selectedIds.toList(growable: false);
    try {
      await widget.postcardService.deletePostcards(ids);
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedIds.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已刪除選取的明信片')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('刪除失敗：$error')));
    }
  }

  List<Postcard> _applyFilters(
    List<Postcard> postcards,
    PostcardCategory? tab,
  ) {
    var results = postcards;

    if (_hideOwned) {
      results = results.where((item) => !item.owned).toList(growable: false);
    }

    if (tab != null) {
      results = results
          .where((item) => item.category == tab)
          .toList(growable: false);
    }

    if (_searchKeyword.trim().isNotEmpty) {
      final keyword = _searchKeyword.trim().toLowerCase();
      results = results
          .where((item) => item.name.toLowerCase().contains(keyword))
          .toList(growable: false);
    } else if (_searchTags.isNotEmpty) {
      results = results
          .where((item) => _searchTags.every(item.tags.contains))
          .toList(growable: false);
    }

    return results;
  }

  String _emptyTextForTab(PostcardCategory? tab) {
    if (_searchKeyword.trim().isNotEmpty) {
      return '找不到名稱包含「$_searchKeyword」的明信片';
    }

    if (_searchTags.isNotEmpty) {
      final displayTags = _searchTags.map(Postcard.displayTag).join('、');
      return '找不到同時包含 $displayTags 的明信片';
    }

    if (_hideOwned) {
      return '目前沒有未擁有的明信片';
    }

    switch (tab) {
      case PostcardCategory.mushroom:
        return '目前沒有菇點明信片';
      case PostcardCategory.flower:
        return '目前沒有花點明信片';
      case PostcardCategory.unknown:
        return '目前沒有未分類明信片';
      case null:
        return '目前還沒有明信片，先新增一張吧';
    }
  }

  void _openDetail(Postcard postcard) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailPage(
          postcard: postcard,
          postcardService: widget.postcardService,
        ),
      ),
    );
  }

  Future<void> _openSearchDialog(List<String> availableTags) async {
    final result = await showDialog<_SearchResult>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: _SearchDialogContent(
            initialMode: _searchMode,
            initialKeyword: _searchKeyword,
            initialTags: _searchTags,
            suggestedTags: availableTags,
          ),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _searchMode = result.mode;
      _searchKeyword = result.keyword;
      _searchTags = result.tags;
    });
  }

  Widget _buildTopActions(List<String> availableTags) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeSearchText = _searchKeyword.trim().isNotEmpty
        ? '名稱：$_searchKeyword'
        : _searchTags.isNotEmpty
        ? '標籤：${_searchTags.map(Postcard.displayTag).join('、')}'
        : '未啟用';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    backgroundColor: _hideOwned
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    foregroundColor: _hideOwned
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _hideOwned = !_hideOwned;
                    });
                  },
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_off_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('隱藏已擁有明信片', style: TextStyle(fontSize: 10.8)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _openSearchDialog(availableTags),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, size: 16),
                        SizedBox(width: 6),
                        Text('搜尋', style: TextStyle(fontSize: 11.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '目前搜尋：$activeSearchText',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                if (_searchKeyword.isNotEmpty || _searchTags.isNotEmpty)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _searchKeyword = '';
                        _searchTags = <String>[];
                        _searchMode = _SearchMode.name;
                      });
                    },
                    borderRadius: BorderRadius.circular(99),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: PopScope(
        canPop: !_isSelectionMode,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _isSelectionMode) {
            _clearSelection();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              _isSelectionMode ? '已選取 ${_selectedIds.length} 張' : '皮克敏明信片',
            ),
            leading: _isSelectionMode
                ? IconButton(
                    onPressed: _clearSelection,
                    icon: const Icon(Icons.close),
                  )
                : null,
            actions: [
              if (_isSelectionMode)
                IconButton(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: '全部'),
                Tab(text: '菇點'),
                Tab(text: '花點'),
              ],
            ),
          ),
          body: StreamBuilder<List<Postcard>>(
            stream: widget.postcardService.watchPostcards(),
            builder: (context, postcardSnapshot) {
              if (postcardSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '讀取資料失敗：${postcardSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (postcardSnapshot.connectionState == ConnectionState.waiting &&
                  !postcardSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final postcards = postcardSnapshot.data ?? const <Postcard>[];

              return StreamBuilder<List<String>>(
                stream: widget.postcardService.watchAvailableTags(),
                builder: (context, tagSnapshot) {
                  final availableTags =
                      tagSnapshot.data ?? kBuiltInPostcardTags;

                  return Column(
                    children: [
                      _buildTopActions(availableTags),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _PostcardGrid(
                              postcards: _applyFilters(postcards, null),
                              emptyText: _emptyTextForTab(null),
                              selectedIds: _selectedIds,
                              onTapPostcard: (postcard) {
                                if (_isSelectionMode) {
                                  _toggleSelection(postcard.id);
                                } else {
                                  _openDetail(postcard);
                                }
                              },
                              onLongPressPostcard: (postcard) {
                                _toggleSelection(postcard.id);
                              },
                            ),
                            _PostcardGrid(
                              postcards: _applyFilters(
                                postcards,
                                PostcardCategory.mushroom,
                              ),
                              emptyText: _emptyTextForTab(
                                PostcardCategory.mushroom,
                              ),
                              selectedIds: _selectedIds,
                              onTapPostcard: (postcard) {
                                if (_isSelectionMode) {
                                  _toggleSelection(postcard.id);
                                } else {
                                  _openDetail(postcard);
                                }
                              },
                              onLongPressPostcard: (postcard) {
                                _toggleSelection(postcard.id);
                              },
                            ),
                            _PostcardGrid(
                              postcards: _applyFilters(
                                postcards,
                                PostcardCategory.flower,
                              ),
                              emptyText: _emptyTextForTab(
                                PostcardCategory.flower,
                              ),
                              selectedIds: _selectedIds,
                              onTapPostcard: (postcard) {
                                if (_isSelectionMode) {
                                  _toggleSelection(postcard.id);
                                } else {
                                  _openDetail(postcard);
                                }
                              },
                              onLongPressPostcard: (postcard) {
                                _toggleSelection(postcard.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          floatingActionButton: _isSelectionMode
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddPostcardPage(
                          postcardService: widget.postcardService,
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
        ),
      ),
    );
  }
}

class _PostcardGrid extends StatelessWidget {
  const _PostcardGrid({
    required this.postcards,
    required this.emptyText,
    required this.selectedIds,
    required this.onTapPostcard,
    required this.onLongPressPostcard,
  });

  final List<Postcard> postcards;
  final String emptyText;
  final Set<String> selectedIds;
  final ValueChanged<Postcard> onTapPostcard;
  final ValueChanged<Postcard> onLongPressPostcard;

  @override
  Widget build(BuildContext context) {
    if (postcards.isEmpty) {
      return Center(child: Text(emptyText, textAlign: TextAlign.center));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: postcards.length,
      itemBuilder: (context, index) {
        final postcard = postcards[index];
        return PostcardGridItem(
          postcard: postcard,
          selected: selectedIds.contains(postcard.id),
          onTap: () => onTapPostcard(postcard),
          onLongPress: () => onLongPressPostcard(postcard),
        );
      },
    );
  }
}

class _SearchResult {
  const _SearchResult({
    required this.mode,
    required this.keyword,
    required this.tags,
  });

  final _SearchMode mode;
  final String keyword;
  final List<String> tags;
}

class _SearchDialogContent extends StatefulWidget {
  const _SearchDialogContent({
    required this.initialMode,
    required this.initialKeyword,
    required this.initialTags,
    required this.suggestedTags,
  });

  final _SearchMode initialMode;
  final String initialKeyword;
  final List<String> initialTags;
  final List<String> suggestedTags;

  @override
  State<_SearchDialogContent> createState() => _SearchDialogContentState();
}

class _SearchDialogContentState extends State<_SearchDialogContent> {
  late _SearchMode _mode;
  late final TextEditingController _nameController;
  late final TextEditingController _tagController;
  late List<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _nameController = TextEditingController(text: widget.initialKeyword);
    _tagController = TextEditingController();
    _selectedTags = Postcard.normalizeTags(widget.initialTags);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    final normalized = Postcard.normalizeTag(tag);
    if (normalized.isEmpty) {
      return;
    }

    setState(() {
      if (_selectedTags.contains(normalized)) {
        _selectedTags = List<String>.from(_selectedTags)..remove(normalized);
      } else {
        _selectedTags = List<String>.from(_selectedTags)..add(normalized);
      }
    });
  }

  void _commitTypedTag() {
    final normalized = Postcard.normalizeTag(_tagController.text);
    if (normalized.isEmpty) {
      return;
    }

    setState(() {
      _selectedTags = Postcard.normalizeTags([..._selectedTags, normalized]);
      _tagController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final allTags = Postcard.normalizeTags([
      ...widget.suggestedTags,
      ..._selectedTags,
    ]);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('搜尋', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('名稱關鍵字'),
                  selected: _mode == _SearchMode.name,
                  onSelected: (_) {
                    setState(() {
                      _mode = _SearchMode.name;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('hashtag'),
                  selected: _mode == _SearchMode.tag,
                  onSelected: (_) {
                    setState(() {
                      _mode = _SearchMode.tag;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_mode == _SearchMode.name)
              TextField(
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: '輸入名稱關鍵字',
                  prefixIcon: Icon(Icons.search),
                ),
              )
            else ...[
              Text(
                '可複選多個 hashtag',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (_selectedTags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in _selectedTags)
                      InputChip(
                        label: Text(Postcard.displayTag(tag)),
                        onDeleted: () => _toggleTag(tag),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in allTags)
                    FilterChip(
                      label: Text(Postcard.displayTag(tag)),
                      selected: _selectedTags.contains(tag),
                      onSelected: (_) => _toggleTag(tag),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: '加入搜尋 hashtag',
                        prefixText: '#',
                      ),
                      onSubmitted: (_) => _commitTypedTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _commitTypedTag,
                    child: const Text('加入'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        const _SearchResult(
                          mode: _SearchMode.name,
                          keyword: '',
                          tags: <String>[],
                        ),
                      );
                    },
                    child: const Text('清除搜尋'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      if (_mode == _SearchMode.tag) {
                        _commitTypedTag();
                      }
                      Navigator.of(context).pop(
                        _SearchResult(
                          mode: _mode,
                          keyword: _mode == _SearchMode.name
                              ? _nameController.text.trim()
                              : '',
                          tags: _mode == _SearchMode.tag
                              ? Postcard.normalizeTags(_selectedTags)
                              : const <String>[],
                        ),
                      );
                    },
                    child: const Text('套用'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
