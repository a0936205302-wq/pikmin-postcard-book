import 'package:flutter/material.dart';

import '../models/postcard.dart';
import '../services/postcard_service.dart';
import '../widgets/postcard_grid_item.dart';
import 'add_postcard_page.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.postcardService});

  final PostcardService postcardService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<String> _selectedIds = <String>{};
  bool _hideOwned = false;

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
          content: Text('確定要刪除已選取的 ${_selectedIds.length} 張明信片嗎？'),
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
      ).showSnackBar(const SnackBar(content: Text('已刪除明信片')));
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

    return results;
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
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '讀取資料失敗：${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final postcards = snapshot.data ?? const <Postcard>[];

              return Column(
                children: [
                  CheckboxListTile(
                    value: _hideOwned,
                    onChanged: (value) {
                      setState(() {
                        _hideOwned = value ?? false;
                      });
                    },
                    title: const Text('隱藏已擁有明信片'),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _PostcardGrid(
                          postcards: _applyFilters(postcards, null),
                          emptyText: _hideOwned
                              ? '目前沒有未擁有的明信片。'
                              : '還沒有明信片，點右下角開始新增吧。',
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
                          emptyText: '目前沒有菇點。',
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
                          emptyText: '目前沒有花點。',
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
      return Center(child: Text(emptyText));
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
