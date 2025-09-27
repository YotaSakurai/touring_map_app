import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import '../models/route.dart';
import '../providers/route_provider.dart';
import 'export_screen.dart';

class RouteDetailScreen extends ConsumerStatefulWidget {
  final String routeId;

  const RouteDetailScreen({
    super.key,
    required this.routeId,
  });

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen> {
  MapboxMapController? _mapController;
  bool _isMapReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ルート詳細'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              _handleAction(value);
            },
            itemBuilder: (context) => [
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
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final routeAsync = ref.watch(routeProvider(widget.routeId));
          
          return routeAsync.when(
            data: (route) => _buildRouteDetail(route),
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
                      ref.invalidate(routeProvider(widget.routeId));
                    },
                    child: const Text('再試行'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRouteDetail(TouringRoute route) {
    return Column(
      children: [
        // 地図エリア
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              MapboxMap(
                accessToken: 'YOUR_MAPBOX_ACCESS_TOKEN', // TODO: 実際のトークンに置き換え
                onMapCreated: _onMapCreated,
                initialCameraPosition: _getInitialCameraPosition(route),
                styleString: MapboxStyles.MAPBOX_STREETS,
              ),
              // 地図操作ボタン
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _fitRouteToView,
                  tooltip: 'ルート全体を表示',
                  child: const Icon(Icons.fit_screen),
                ),
              ),
            ],
          ),
        ),
        // ルート情報エリア
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ルートタイトルと可視性
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        route.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildVisibilityChip(route.visibility),
                  ],
                ),
                const SizedBox(height: 8),
                
                // 説明
                if (route.description != null && route.description!.isNotEmpty)
                  Text(
                    route.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 16),
                
                // ルート統計情報
                _buildRouteStats(route),
                const SizedBox(height: 16),
                
                // タグ
                if (route.tags.isNotEmpty) ...[
                  Text(
                    'タグ',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: route.tags.map((tag) => Chip(
                      label: Text(_getTagDisplayName(tag)),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // 作成・更新日時
                _buildDateInfo(route),
                const SizedBox(height: 24),
                
                // アクションボタン
                _buildActionButtons(route),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityChip(String visibility) {
    Color color;
    IconData icon;
    String text;
    
    switch (visibility) {
      case RouteVisibility.public:
        color = Colors.green;
        icon = Icons.public;
        text = '公開';
        break;
      case RouteVisibility.unlisted:
        color = Colors.orange;
        icon = Icons.link;
        text = '限定公開';
        break;
      case RouteVisibility.private:
        color = Colors.grey;
        icon = Icons.lock;
        text = '非公開';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        text = '不明';
    }
    
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildRouteStats(TouringRoute route) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ルート情報',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.straighten,
                    '距離',
                    route.distanceM != null 
                      ? '${(route.distanceM! / 1000).toStringAsFixed(1)}km'
                      : '計算中...',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.trending_up,
                    '標高差',
                    route.elevGainM != null 
                      ? '${route.elevGainM}m'
                      : '計算中...',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.flag,
                    'ポイント数',
                    _getPointCount(route).toString(),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.label,
                    'タグ数',
                    '${route.tags.length}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfo(TouringRoute route) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '作成・更新情報',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '作成日: ${_formatDate(route.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    '更新日: ${_formatDate(route.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(TouringRoute route) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleAction('share'),
            icon: const Icon(Icons.share),
            label: const Text('共有'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleAction('export'),
            icon: const Icon(Icons.download),
            label: const Text('エクスポート'),
          ),
        ),
      ],
    );
  }

  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });
    
    // ルートを地図に描画
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drawRouteOnMap();
    });
  }

  void _drawRouteOnMap() {
    if (!_isMapReady) return;
    
    final routeAsync = ref.read(routeProvider(widget.routeId));
    routeAsync.whenData((route) {
      final coordinates = _extractCoordinates(route.geom);
      if (coordinates.isNotEmpty) {
        _mapController?.addLine(
          LineOptions(
            geometry: coordinates,
            lineColor: '#FF6B35',
            lineWidth: 4.0,
            lineOpacity: 0.8,
          ),
        );
        
        // スタート・エンドポイントをマーカーで表示
        if (coordinates.length >= 2) {
          _mapController?.addSymbol(
            SymbolOptions(
              geometry: coordinates.first,
              iconImage: 'start-marker',
              iconSize: 1.0,
              textField: 'START',
              textSize: 12.0,
              textColor: '#FFFFFF',
              textHaloColor: '#000000',
              textHaloWidth: 1.0,
            ),
          );
          
          _mapController?.addSymbol(
            SymbolOptions(
              geometry: coordinates.last,
              iconImage: 'end-marker',
              iconSize: 1.0,
              textField: 'END',
              textSize: 12.0,
              textColor: '#FFFFFF',
              textHaloColor: '#000000',
              textHaloWidth: 1.0,
            ),
          );
        }
      }
    });
  }

  List<LatLng> _extractCoordinates(Map<String, dynamic> geom) {
    try {
      if (geom['type'] == 'MultiLineString') {
        final coordinates = geom['coordinates'] as List;
        if (coordinates.isNotEmpty) {
          final firstLine = coordinates[0] as List;
          return firstLine.map((coord) => LatLng(
            (coord[1] as num).toDouble(),
            (coord[0] as num).toDouble(),
          )).toList();
        }
      } else if (geom['type'] == 'LineString') {
        final coordinates = geom['coordinates'] as List;
        return coordinates.map((coord) => LatLng(
          (coord[1] as num).toDouble(),
          (coord[0] as num).toDouble(),
        )).toList();
      }
    } catch (e) {
      debugPrint('座標抽出エラー: $e');
    }
    return [];
  }

  CameraPosition _getInitialCameraPosition(TouringRoute route) {
    final coordinates = _extractCoordinates(route.geom);
    if (coordinates.isNotEmpty) {
      return CameraPosition(
        target: coordinates.first,
        zoom: 12.0,
      );
    }
    return const CameraPosition(
      target: LatLng(35.6762, 139.6503), // 東京
      zoom: 10.0,
    );
  }

  void _fitRouteToView() {
    if (!_isMapReady) return;
    
    final routeAsync = ref.read(routeProvider(widget.routeId));
    routeAsync.whenData((route) {
      final coordinates = _extractCoordinates(route.geom);
      if (coordinates.length >= 2) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                coordinates.map((c) => c.latitude).reduce((a, b) => a < b ? a : b),
                coordinates.map((c) => c.longitude).reduce((a, b) => a < b ? a : b),
              ),
              northeast: LatLng(
                coordinates.map((c) => c.latitude).reduce((a, b) => a > b ? a : b),
                coordinates.map((c) => c.longitude).reduce((a, b) => a > b ? a : b),
              ),
            ),
            left: 50,
            right: 50,
            top: 50,
            bottom: 50,
          ),
        );
      }
    });
  }

  int _getPointCount(TouringRoute route) {
    final coordinates = _extractCoordinates(route.geom);
    return coordinates.length;
  }

  String _getTagDisplayName(String tag) {
    switch (tag) {
      case RouteTags.night:
        return '夜間営業';
      case RouteTags.onsen:
        return '温泉';
      case RouteTags.parking2w:
        return '二輪駐車場';
      case RouteTags.riderWelcome:
        return 'ライダー歓迎';
      case RouteTags.scenic:
        return '景色';
      case RouteTags.food:
        return 'グルメ';
      default:
        return tag;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  void _handleAction(String action) {
    final routeAsync = ref.read(routeProvider(widget.routeId));
    routeAsync.whenData((route) {
      switch (action) {
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
              builder: (context) => ExportScreen(routeId: route.id),
            ),
          );
          break;
        case 'delete':
          _showDeleteDialog(route);
          break;
      }
    });
  }

  void _showDeleteDialog(TouringRoute route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ルートを削除'),
        content: Text('「${route.title}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteRoute(route);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoute(TouringRoute route) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.deleteRoute(route.id);
      
      // ルート一覧を更新
      ref.invalidate(routesProvider);
      
      if (mounted) {
        Navigator.of(context).pop(); // 詳細画面を閉じる
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
