import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/yae_event.dart';
import '../../services/yae_service.dart';

class YaeDetailScreen extends ConsumerStatefulWidget {
  final YaeEvent event;

  const YaeDetailScreen({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<YaeDetailScreen> createState() => _YaeDetailScreenState();
}

class _YaeDetailScreenState extends ConsumerState<YaeDetailScreen> {
  MapboxMapController? _mapController;
  bool _isMapReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ヤエー詳細'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareYaeEvent,
            tooltip: '共有',
          ),
          PopupMenuButton<String>(
            onSelected: _handleAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'like',
                child: ListTile(
                  leading: Icon(Icons.favorite_border),
                  title: Text('いいね'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: ListTile(
                  leading: Icon(Icons.report),
                  title: Text('報告'),
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
      body: Column(
        children: [
          // 地図エリア
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                MapboxMap(
                  accessToken: 'YOUR_MAPBOX_ACCESS_TOKEN', // TODO: 実際のトークンに置き換え
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: _getInitialCameraPosition(),
                  styleString: MapboxStyles.MAPBOX_STREETS,
                ),
                // 地図操作ボタン
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: _centerOnEvent,
                    tooltip: 'ヤエー地点に移動',
                    child: const Icon(Icons.my_location),
                  ),
                ),
                // 信頼度表示
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildConfidenceBadge(),
                ),
              ],
            ),
          ),
          // 詳細情報エリア
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventHeader(),
                  const SizedBox(height: 20),
                  _buildEventDetails(),
                  const SizedBox(height: 20),
                  _buildLocationInfo(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    Color color;
    String text;
    IconData icon;
    
    if (widget.event.confidence >= 90) {
      color = Colors.green;
      text = '確実なヤエー';
      icon = Icons.check_circle;
    } else if (widget.event.confidence >= 70) {
      color = Colors.orange;
      text = 'ヤエーの可能性高';
      icon = Icons.help;
    } else {
      color = Colors.grey;
      text = 'ヤエーの可能性低';
      icon = Icons.help_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '${widget.event.confidence}% $text',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.waving_hand,
                    size: 32,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ヤエーイベント',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '他のライダーとの遭遇記録',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                'ID: ${widget.event.id}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'イベント詳細',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.access_time,
              '発生日時',
              DateFormat('yyyy年M月d日 (E) HH:mm:ss', 'ja_JP').format(widget.event.happenedAt),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.percent,
              '信頼度',
              '${widget.event.confidence}% ${_getConfidenceDescription(widget.event.confidence)}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.people,
              '参加者',
              '2人（あなた + 1人）',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.schedule,
              '記録日時',
              DateFormat('yyyy年M月d日 HH:mm', 'ja_JP').format(widget.event.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    final coords = widget.event.geom['coordinates'] as List;
    final lat = (coords[1] as num).toDouble();
    final lng = (coords[0] as num).toDouble();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '位置情報',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.location_on,
              '発生地点',
              _getLocationDescription(lat, lng),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.gps_fixed,
              '座標',
              '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.map,
              '地域',
              _getAreaName(lat, lng),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareYaeEvent,
                icon: const Icon(Icons.share),
                label: const Text('共有'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _likeYaeEvent,
                icon: const Icon(Icons.favorite_border),
                label: const Text('いいね'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _viewOnMaps,
            icon: const Icon(Icons.map),
            label: const Text('外部マップで表示'),
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
    
    // ヤエー地点にマーカーを追加
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addYaeMarker();
    });
  }

  void _addYaeMarker() {
    if (!_isMapReady) return;
    
    final coords = widget.event.geom['coordinates'] as List;
    final lat = (coords[1] as num).toDouble();
    final lng = (coords[0] as num).toDouble();
    
    _mapController?.addSymbol(
      SymbolOptions(
        geometry: LatLng(lat, lng),
        iconImage: 'custom-marker',
        iconSize: 1.5,
        textField: 'ヤエー!',
        textSize: 14.0,
        textColor: '#FFFFFF',
        textHaloColor: '#FF6B35',
        textHaloWidth: 2.0,
        textOffset: const Offset(0, 2),
      ),
    );
  }

  CameraPosition _getInitialCameraPosition() {
    final coords = widget.event.geom['coordinates'] as List;
    final lat = (coords[1] as num).toDouble();
    final lng = (coords[0] as num).toDouble();
    
    return CameraPosition(
      target: LatLng(lat, lng),
      zoom: 15.0,
    );
  }

  void _centerOnEvent() {
    if (!_isMapReady) return;
    
    final coords = widget.event.geom['coordinates'] as List;
    final lat = (coords[1] as num).toDouble();
    final lng = (coords[0] as num).toDouble();
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15.0),
    );
  }

  String _getConfidenceDescription(int confidence) {
    if (confidence >= 90) return '（非常に確実）';
    if (confidence >= 80) return '（確実）';
    if (confidence >= 70) return '（可能性高）';
    if (confidence >= 50) return '（可能性中）';
    return '（可能性低）';
  }

  String _getLocationDescription(double lat, double lng) {
    // 簡易的な地域判定
    if (lat >= 35.5 && lat <= 35.8 && lng >= 139.5 && lng <= 139.8) {
      return '東京都内の道路';
    } else if (lat >= 34.5 && lat <= 35.0 && lng >= 135.0 && lng <= 135.5) {
      return '大阪府内の道路';
    } else if (lat >= 35.0 && lat <= 35.5 && lng >= 136.0 && lng <= 136.5) {
      return '愛知県内の道路';
    } else {
      return '道路上';
    }
  }

  String _getAreaName(double lat, double lng) {
    // 簡易的な地域判定
    if (lat >= 35.5 && lat <= 35.8 && lng >= 139.5 && lng <= 139.8) {
      return '東京都';
    } else if (lat >= 34.5 && lat <= 35.0 && lng >= 135.0 && lng <= 135.5) {
      return '大阪府';
    } else if (lat >= 35.0 && lat <= 35.5 && lng >= 136.0 && lng <= 136.5) {
      return '愛知県';
    } else {
      return '日本';
    }
  }

  void _shareYaeEvent() async {
    final coords = widget.event.geom['coordinates'] as List;
    final lat = (coords[1] as num).toDouble();
    final lng = (coords[0] as num).toDouble();
    
    final shareText = '''
🏍️ ヤエーイベント！

📅 日時: ${DateFormat('yyyy年M月d日 HH:mm', 'ja_JP').format(widget.event.happenedAt)}
📍 場所: ${_getLocationDescription(lat, lng)}
🎯 信頼度: ${widget.event.confidence}%

他のライダーとのすれ違いを記録しました！
#ヤエー #バイク #ツーリング
    ''';
    
    try {
      await Share.share(shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('共有エラー: $e')),
        );
      }
    }
  }

  void _likeYaeEvent() async {
    final yaeService = ref.read(yaeServiceProvider);
    final success = await yaeService.likeYaeEvent(widget.event.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('いいねしました！'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('いいねに失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewOnMaps() {
    final coords = widget.event.geom['coordinates'] as List;
    final lat = (coords[1] as num).toDouble();
    final lng = (coords[0] as num).toDouble();
    
    // TODO: 外部マップアプリで開く機能を実装
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('座標: $lat, $lng\n外部マップ機能（実装予定）'),
      ),
    );
  }

  void _handleAction(String action) async {
    switch (action) {
      case 'like':
        _likeYaeEvent();
        break;
      case 'report':
        _showReportDialog();
        break;
      case 'delete':
        _showDeleteDialog();
        break;
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ヤエーイベントを報告'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('このヤエーイベントに問題がある場合は報告してください。'),
            SizedBox(height: 16),
            Text('報告理由:'),
            SizedBox(height: 8),
            Text('• 不正確な記録'),
            Text('• スパム・偽情報'),
            Text('• プライバシー侵害'),
            Text('• その他の問題'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('報告を送信しました')),
              );
            },
            child: const Text('報告'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ヤエーイベントを削除'),
        content: Text(
          '${DateFormat('yyyy/MM/dd HH:mm').format(widget.event.happenedAt)}のヤエーイベントを削除しますか？\nこの操作は取り消せません。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteYaeEvent();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteYaeEvent() async {
    final yaeService = ref.read(yaeServiceProvider);
    final success = await yaeService.deleteYaeEvent(widget.event.id);
    
    if (success) {
      ref.invalidate(yaeEventsProvider);
      if (mounted) {
        Navigator.of(context).pop(); // 詳細画面を閉じる
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ヤエーイベントを削除しました')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('削除に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
