import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/route.dart';
import '../providers/route_provider.dart';
import 'route_detail_screen.dart';
import 'route_creation_screen.dart';
import 'export_screen.dart';
import 'import_screen.dart';

class RouteListScreen extends ConsumerStatefulWidget {
  const RouteListScreen({super.key});

  @override
  ConsumerState<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends ConsumerState<RouteListScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ルート一覧'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ImportScreen(),
                ),
              );
            },
            tooltip: 'ファイルをインポート',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RouteCreationScreen(),
                ),
              );
            },
            tooltip: '新しいルートを作成',
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索・フィルターエリア
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 検索バー
                TextField(
                  decoration: InputDecoration(
                    hintText: 'ルート名で検索...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // フィルターチップ
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'すべて'),
                      _buildFilterChip('public', '公開'),
                      _buildFilterChip('private', '非公開'),
                      _buildFilterChip('night', '夜間営業'),
                      _buildFilterChip('onsen', '温泉'),
                      _buildFilterChip('parking2w', '二輪駐車場'),
                      _buildFilterChip('scenic', '景色'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ルート一覧
          Expanded(
            child: _buildRouteList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
      ),
    );
  }

  Widget _buildRouteList() {
    // フィルターに応じてプロバイダーを選択
    final routeProvider = _getRouteProvider();
    
    return Consumer(
      builder: (context, ref, child) {
        final routesAsync = ref.watch(routeProvider);
        
        return routesAsync.when(
          data: (routes) {
            // 検索クエリでフィルタリング
            final filteredRoutes = routes.where((touringRoute) {
              if (_searchQuery.isNotEmpty) {
                return touringRoute.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                       (touringRoute.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
              }
              return true;
            }).toList();

            if (filteredRoutes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.route,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty 
                        ? '検索結果が見つかりませんでした'
                        : 'ルートがありません',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty
                        ? '別のキーワードで検索してみてください'
                        : '新しいルートを作成してみましょう',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(routeProvider);
              },
              child: ListView.builder(
                itemCount: filteredRoutes.length,
                itemBuilder: (context, index) {
                  final touringRoute = filteredRoutes[index];
                  return _buildRouteCard(touringRoute);
                },
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'エラーが発生しました',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(routeProvider);
                  },
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  FutureProvider<List<TouringRoute>> _getRouteProvider() {
    switch (_selectedFilter) {
      case 'public':
        return publicRoutesProvider;
      case 'night':
        return routesByTagProvider(RouteTags.night);
      case 'onsen':
        return routesByTagProvider(RouteTags.onsen);
      case 'parking2w':
        return routesByTagProvider(RouteTags.parking2w);
      case 'scenic':
        return routesByTagProvider(RouteTags.scenic);
      default:
        return routesProvider;
    }
  }

  Widget _buildRouteCard(TouringRoute touringRoute) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getVisibilityColor(touringRoute.visibility),
          child: Icon(
            _getVisibilityIcon(touringRoute.visibility),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          touringRoute.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (touringRoute.description != null && touringRoute.description!.isNotEmpty)
              Text(
                touringRoute.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (touringRoute.distanceM != null)
                  _buildInfoChip(
                    Icons.straighten,
                    '${(touringRoute.distanceM! / 1000).toStringAsFixed(1)}km',
                  ),
                if (touringRoute.elevGainM != null)
                  _buildInfoChip(
                    Icons.trending_up,
                    '${touringRoute.elevGainM}m',
                  ),
                if (touringRoute.tags.isNotEmpty)
                  _buildInfoChip(
                    Icons.label,
                    '${touringRoute.tags.length}タグ',
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '作成日: ${_formatDate(touringRoute.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            _handleRouteAction(value, touringRoute);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('詳細表示'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('編集'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('共有'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('エクスポート'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('削除', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RouteDetailScreen(routeId: touringRoute.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        avatar: Icon(icon, size: 16),
        label: Text(text, style: const TextStyle(fontSize: 12)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Color _getVisibilityColor(String visibility) {
    switch (visibility) {
      case RouteVisibility.public:
        return Colors.green;
      case RouteVisibility.unlisted:
        return Colors.orange;
      case RouteVisibility.private:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getVisibilityIcon(String visibility) {
    switch (visibility) {
      case RouteVisibility.public:
        return Icons.public;
      case RouteVisibility.unlisted:
        return Icons.link;
      case RouteVisibility.private:
        return Icons.lock;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '今日';
    } else if (difference.inDays == 1) {
      return '昨日';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }

  void _handleRouteAction(String action, TouringRoute touringRoute) {
    switch (action) {
      case 'view':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RouteDetailScreen(routeId: touringRoute.id),
          ),
        );
        break;
      case 'edit':
        // TODO: ルート編集画面を実装
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ルート編集機能（実装予定）')),
        );
        break;
      case 'share':
        // TODO: 共有機能を実装
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('共有機能（実装予定）')),
        );
        break;
      case 'export':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExportScreen(routeId: touringRoute.id),
          ),
        );
        break;
      case 'delete':
        _showDeleteDialog(touringRoute);
        break;
    }
  }

  void _showDeleteDialog(TouringRoute touringRoute) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ルートを削除'),
        content: Text('「${touringRoute.title}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteRoute(touringRoute);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoute(TouringRoute touringRoute) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.deleteRoute(touringRoute.id);
      
      // ルート一覧を更新
      ref.invalidate(routesProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ルートが削除されました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除エラー: $e')),
        );
      }
    }
  }
}
