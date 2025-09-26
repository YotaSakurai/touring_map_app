import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/spot.dart';
import '../../services/spot_service.dart';
import '../../providers/location_provider.dart';
import 'spot_detail_screen.dart';
import 'spot_creation_screen.dart';

class SpotListScreen extends ConsumerStatefulWidget {
  const SpotListScreen({super.key});

  @override
  ConsumerState<SpotListScreen> createState() => _SpotListScreenState();
}

class _SpotListScreenState extends ConsumerState<SpotListScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _sortBy = 'distance';
  bool _showMap = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final positionAsync = ref.read(currentPositionProvider);
    positionAsync.whenData((position) {
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スポット'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
            tooltip: _showMap ? 'リスト表示' : 'マップ表示',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SpotCreationScreen(),
                ),
              );
            },
            tooltip: 'スポットを投稿',
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索・フィルターエリア
          _buildSearchAndFilters(),
          
          // スポット一覧/マップ
          Expanded(
            child: _showMap ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SpotCreationScreen(),
            ),
          );
        },
        tooltip: 'スポットを投稿',
        child: const Icon(Icons.add_location),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 検索バー
          TextField(
            decoration: InputDecoration(
              hintText: 'スポット名で検索...',
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
          
          // カテゴリフィルター
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('all', 'すべて', Icons.all_inclusive),
                ..._buildCategoryChips(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // ソート・位置情報
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'ソート',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'distance', child: Text('距離順')),
                    DropdownMenuItem(value: 'name', child: Text('名前順')),
                    DropdownMenuItem(value: 'rating', child: Text('評価順')),
                    DropdownMenuItem(value: 'newest', child: Text('新着順')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('現在地取得'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryChips() {
    return ref.watch(spotCategoriesProvider).map((category) {
      return _buildCategoryChip(
        category.id,
        category.name,
        _getIconData(category.icon),
      );
    }).toList();
  }

  Widget _buildCategoryChip(String categoryId, String label, IconData icon) {
    final isSelected = _selectedCategory == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = categoryId;
          });
        },
      ),
    );
  }

  Widget _buildListView() {
    return Consumer(
      builder: (context, ref, child) {
        final spotsAsync = ref.watch(spotsProvider);
        
        return spotsAsync.when(
          data: (spots) {
            final filteredSpots = _filterAndSortSpots(spots);
            
            if (filteredSpots.isEmpty) {
              return _buildEmptyState();
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(spotsProvider);
              },
              child: ListView.builder(
                itemCount: filteredSpots.length,
                itemBuilder: (context, index) {
                  final spot = filteredSpots[index];
                  return _buildSpotCard(spot);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error),
        );
      },
    );
  }

  Widget _buildMapView() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('マップ表示（実装予定）'),
            SizedBox(height: 8),
            Text('Mapbox GL統合が必要です'),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotCard(Spot spot) {
    final categories = ref.watch(spotCategoriesProvider);
    final category = categories.firstWhere(
      (cat) => spot.tags.contains(cat.id),
      orElse: () => categories.first,
    );

    final distance = _currentPosition != null
        ? ref.read(spotServiceProvider).calculateDistance(
            spot,
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          )
        : null;

    final isOpen = ref.read(spotServiceProvider).isSpotOpen(spot);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(category.color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconData(category.icon),
            color: Color(category.color),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                spot.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (spot.verified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '認証済み',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (spot.description != null && spot.description!.isNotEmpty)
              Text(
                spot.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (distance != null) ...[
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 2),
                  Text(
                    _formatDistance(distance),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isOpen ? '営業中' : '営業時間外',
                    style: TextStyle(
                      fontSize: 10,
                      color: isOpen ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ...spot.tags.take(2).map((tag) {
                  final tagCategory = categories.firstWhere(
                    (cat) => cat.id == tag,
                    orElse: () => categories.first,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                      label: Text(
                        tagCategory.name,
                        style: const TextStyle(fontSize: 10),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Color(tagCategory.color).withOpacity(0.1),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleSpotAction(value, spot),
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
              value: 'directions',
              child: ListTile(
                leading: Icon(Icons.directions),
                title: Text('ルート案内'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'favorite',
              child: ListTile(
                leading: Icon(Icons.favorite_border),
                title: Text('お気に入り'),
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
              value: 'report',
              child: ListTile(
                leading: Icon(Icons.report, color: Colors.red),
                title: Text('報告', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SpotDetailScreen(spotId: spot.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? '検索結果が見つかりませんでした' : 'スポットがありません',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? '別のキーワードで検索してみてください'
                : '新しいスポットを投稿してみましょう',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SpotCreationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_location),
            label: const Text('スポットを投稿'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
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
              ref.invalidate(spotsProvider);
            },
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  // ヘルパーメソッド

  List<Spot> _filterAndSortSpots(List<Spot> spots) {
    var filteredSpots = spots.where((spot) {
      // 検索クエリフィルター
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!spot.name.toLowerCase().contains(query) &&
            !(spot.description?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // カテゴリフィルター
      if (_selectedCategory != 'all') {
        if (!spot.tags.contains(_selectedCategory)) {
          return false;
        }
      }

      return true;
    }).toList();

    // ソート
    switch (_sortBy) {
      case 'distance':
        if (_currentPosition != null) {
          filteredSpots.sort((a, b) {
            final distanceA = ref.read(spotServiceProvider).calculateDistance(
              a,
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            );
            final distanceB = ref.read(spotServiceProvider).calculateDistance(
              b,
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            );
            return distanceA.compareTo(distanceB);
          });
        }
        break;
      case 'name':
        filteredSpots.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'newest':
        filteredSpots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'rating':
        // TODO: 評価機能実装後にソート
        break;
    }

    return filteredSpots;
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'motorcycle':
        return Icons.motorcycle;
      case 'hot_tub':
        return Icons.hot_tub;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'landscape':
        return Icons.landscape;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'build':
        return Icons.build;
      case 'shopping_cart':
        return Icons.shopping_cart;
      default:
        return Icons.place;
    }
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  void _handleSpotAction(String action, Spot spot) async {
    final spotService = ref.read(spotServiceProvider);
    
    switch (action) {
      case 'view':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SpotDetailScreen(spotId: spot.id),
          ),
        );
        break;
      
      case 'directions':
        // TODO: ルート案内機能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ルート案内機能（実装予定）')),
        );
        break;
      
      case 'favorite':
        final success = await spotService.toggleFavoriteSpot(spot.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('お気に入りに追加しました')),
          );
        }
        break;
      
      case 'share':
        // TODO: 共有機能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('共有機能（実装予定）')),
        );
        break;
      
      case 'report':
        _showReportDialog(spot);
        break;
    }
  }

  void _showReportDialog(Spot spot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スポットを報告'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${spot.name}」を報告しますか？'),
            const SizedBox(height: 16),
            const Text('報告理由:'),
            const SizedBox(height: 8),
            const Text('• 不正確な情報'),
            const Text('• 存在しない場所'),
            const Text('• 不適切な内容'),
            const Text('• スパム・重複'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final spotService = ref.read(spotServiceProvider);
              final success = await spotService.reportSpot(spot.id, 'inappropriate', null);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('報告を送信しました')),
                );
              }
            },
            child: const Text('報告'),
          ),
        ],
      ),
    );
  }
}
