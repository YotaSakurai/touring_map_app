import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/route.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../providers/route_provider.dart';

class RouteCreationScreen extends ConsumerStatefulWidget {
  const RouteCreationScreen({super.key});

  @override
  ConsumerState<RouteCreationScreen> createState() => _RouteCreationScreenState();
}

class _RouteCreationScreenState extends ConsumerState<RouteCreationScreen> {
  MapboxMapController? _mapController;
  final List<LatLng> _routePoints = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _visibility = RouteVisibility.private;
  final List<String> _selectedTags = [];
  
  bool _isCreating = false;
  bool _isMapReady = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });
    _centerMapOnCurrentLocation();
  }

  Future<void> _centerMapOnCurrentLocation() async {
    try {
      // TODO: 位置情報サービスを実装
      // final locationService = ref.read(locationServiceProvider);
      // final position = await locationService.getCurrentPosition();
      
      // 仮の位置（東京駅）
      const position = LatLng(35.6812, 139.7671);
      
      await _mapController?.animateCamera(
        CameraUpdate.newLatLng(position),
      );
    } catch (e) {
      // 位置情報取得に失敗した場合は東京を中心に
      await _mapController?.animateCamera(
        CameraUpdate.newLatLng(const LatLng(35.6762, 139.6503)),
      );
    }
  }

  void _onMapTap(TapUpDetails details, MapboxMapController controller) {
    if (_isCreating) return;
    
    final point = details.localPosition;
    
    // TODO: Mapboxの座標変換メソッドを実装
    // final latLng = controller.cameraForCoordinate(
    //   controller.pointForCoordinate(
    //     LatLng(0, 0), // ダミー座標
    //   ),
    // );
    
    // 実際の座標を取得するために、画面座標から地理座標に変換
    // final screenPoint = details.localPosition;
    // final coordinate = controller.coordinateForPoint(screenPoint);
    
    // 仮の座標（東京駅周辺）
    const coordinate = LatLng(35.6812, 139.7671);
    
    setState(() {
      _routePoints.add(coordinate);
    });
    
    _updateRouteLine();
  }

  void _updateRouteLine() {
    if (_routePoints.length < 2) return;
    
    _mapController?.addLine(
      LineOptions(
        geometry: _routePoints,
        lineColor: '#FF6B35',
        lineWidth: 4.0,
        lineOpacity: 0.8,
      ),
    );
    
    // ポイントをマーカーとして追加
    for (int i = 0; i < _routePoints.length; i++) {
      _mapController?.addSymbol(
        SymbolOptions(
          geometry: _routePoints[i],
          iconImage: i == 0 ? 'start-marker' : 
                    i == _routePoints.length - 1 ? 'end-marker' : 'waypoint-marker',
          iconSize: 1.0,
          textField: i == 0 ? 'START' : 
                    i == _routePoints.length - 1 ? 'END' : '${i}',
          textSize: 12.0,
          textColor: '#FFFFFF',
          textHaloColor: '#000000',
          textHaloWidth: 1.0,
        ),
      );
    }
  }

  void _clearRoute() {
    setState(() {
      _routePoints.clear();
    });
    _mapController?.clearLines();
    _mapController?.clearSymbols();
  }

  void _undoLastPoint() {
    if (_routePoints.isEmpty) return;
    
    setState(() {
      _routePoints.removeLast();
    });
    
    _mapController?.clearLines();
    _mapController?.clearSymbols();
    
    if (_routePoints.length >= 2) {
      _updateRouteLine();
    } else if (_routePoints.length == 1) {
      // 最後のポイントをマーカーとして表示
      _mapController?.addSymbol(
        SymbolOptions(
          geometry: _routePoints[0],
          iconImage: 'start-marker',
          iconSize: 1.0,
          textField: 'START',
          textSize: 12.0,
          textColor: '#FFFFFF',
          textHaloColor: '#000000',
          textHaloWidth: 1.0,
        ),
      );
    }
  }

  Future<void> _saveRoute() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ルート名を入力してください')),
      );
      return;
    }

    if (_routePoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ルートには最低2つのポイントが必要です')),
      );
      return;
    }

    try {
      // GeoJSON MultiLineString形式でルートデータを作成
      final routeData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'geom': {
          'type': 'MultiLineString',
          'coordinates': [_routePoints.map((p) => [p.longitude, p.latitude]).toList()],
        },
        'tags': _selectedTags,
        'visibility': _visibility,
      };

      final apiService = ref.read(apiServiceProvider);
      await apiService.createRoute(routeData);
      
      // ルート一覧を更新
      ref.invalidate(routesProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ルートが保存されました')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ルート作成'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_routePoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _undoLastPoint,
              tooltip: '最後のポイントを削除',
            ),
          if (_routePoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearRoute,
              tooltip: 'ルートをクリア',
            ),
        ],
      ),
      body: Column(
        children: [
          // 地図エリア
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MapboxMap(
                  accessToken: dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? 'YOUR_MAPBOX_ACCESS_TOKEN',
                  onMapCreated: _onMapCreated,
                  // onTap: _onMapTap, // TODO: MapboxのonTapパラメータを実装
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(35.6762, 139.6503), // 東京
                    zoom: 10.0,
                  ),
                  styleString: MapboxStyles.MAPBOX_STREETS,
                ),
                // 地図操作ボタン
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        onPressed: _centerMapOnCurrentLocation,
                        tooltip: '現在地に移動',
                        child: const Icon(Icons.my_location),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        onPressed: () {
                          setState(() {
                            _isCreating = !_isCreating;
                          });
                        },
                        tooltip: _isCreating ? 'ポイント追加を有効化' : 'ポイント追加を無効化',
                        backgroundColor: _isCreating ? Colors.red : Colors.blue,
                        child: Icon(_isCreating ? Icons.pause : Icons.add),
                      ),
                    ],
                  ),
                ),
                // ルート情報表示
                if (_routePoints.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ルート情報',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text('ポイント数: ${_routePoints.length}'),
                            if (_routePoints.length >= 2)
                              Text('距離: 計算中...'), // TODO: 距離計算を実装
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ルート詳細入力エリア
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'ルート名 *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: '説明',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // 可視性選択
                  Text(
                    '公開設定',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _visibility,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: RouteVisibility.private,
                        child: const Text('非公開'),
                      ),
                      DropdownMenuItem(
                        value: RouteVisibility.unlisted,
                        child: const Text('限定公開'),
                      ),
                      DropdownMenuItem(
                        value: RouteVisibility.public,
                        child: const Text('公開'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _visibility = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // タグ選択
                  Text(
                    'タグ',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      RouteTags.night,
                      RouteTags.onsen,
                      RouteTags.parking2w,
                      RouteTags.riderWelcome,
                      RouteTags.scenic,
                      RouteTags.food,
                    ].map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(_getTagDisplayName(tag)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // 保存ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _routePoints.length >= 2 ? _saveRoute : null,
                      child: const Text('ルートを保存'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
}
