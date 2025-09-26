import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../models/route.dart';
import '../providers/route_provider.dart';
import '../services/file_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final String routeId;

  const ExportScreen({
    super.key,
    required this.routeId,
  });

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final List<String> _selectedFormats = [];
  bool _isExporting = false;
  String? _exportJobId;

  final List<ExportFormat> _availableFormats = [
    ExportFormat(
      id: 'gpx_route',
      name: 'GPX Route',
      description: 'ルート計画用（推奨）',
      icon: Icons.route,
    ),
    ExportFormat(
      id: 'gpx_track',
      name: 'GPX Track',
      description: '実走ログ用',
      icon: Icons.timeline,
    ),
    ExportFormat(
      id: 'gpx_waypoints',
      name: 'GPX Waypoints',
      description: 'ウェイポイントのみ',
      icon: Icons.place,
    ),
    ExportFormat(
      id: 'kml',
      name: 'KML',
      description: 'Google Earth用',
      icon: Icons.public,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ルートエクスポート'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final routeAsync = ref.watch(routeProvider(widget.routeId));
          
          return routeAsync.when(
            data: (route) => _buildExportContent(route),
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

  Widget _buildExportContent(Route route) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ルート情報カード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'エクスポート対象',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.route,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (route.description != null && route.description!.isNotEmpty)
                              Text(
                                route.description!,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (route.distanceM != null)
                        _buildInfoChip(
                          Icons.straighten,
                          '${(route.distanceM! / 1000).toStringAsFixed(1)}km',
                        ),
                      if (route.elevGainM != null)
                        _buildInfoChip(
                          Icons.trending_up,
                          '${route.elevGainM}m',
                        ),
                      _buildInfoChip(
                        Icons.label,
                        '${route.tags.length}タグ',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // フォーマット選択
          Text(
            'エクスポート形式',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            '出力したい形式を選択してください（複数選択可能）',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          // フォーマットリスト
          ..._availableFormats.map((format) => _buildFormatCard(format)),
          const SizedBox(height: 24),
          
          // エクスポートボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedFormats.isNotEmpty && !_isExporting
                  ? _startExport
                  : null,
              icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_isExporting ? 'エクスポート中...' : 'エクスポート開始'),
            ),
          ),
          
          // エクスポート結果表示
          if (_exportJobId != null) ...[
            const SizedBox(height: 24),
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Text(
                          'エクスポート開始',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ジョブID: $_exportJobId',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'エクスポートが完了すると通知されます。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormatCard(ExportFormat format) {
    final isSelected = _selectedFormats.contains(format.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedFormats.add(format.id);
            } else {
              _selectedFormats.remove(format.id);
            }
          });
        },
        title: Row(
          children: [
            Icon(format.icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    format.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        secondary: _buildFormatIcon(format.id),
      ),
    );
  }

  Widget _buildFormatIcon(String formatId) {
    switch (formatId) {
      case 'gpx_route':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'GPX',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        );
      case 'gpx_track':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'GPX',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        );
      case 'gpx_waypoints':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'GPX',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        );
      case 'kml':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'KML',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
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

  Future<void> _startExport() async {
    if (_selectedFormats.isEmpty) return;

    setState(() {
      _isExporting = true;
      _exportJobId = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final jobId = await apiService.exportRoute(widget.routeId, _selectedFormats);
      
      setState(() {
        _exportJobId = jobId;
        _isExporting = false;
      });

      // 成功メッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エクスポートを開始しました（ジョブID: $jobId）'),
            action: SnackBarAction(
              label: '共有',
              onPressed: () => _shareExportInfo(jobId),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エクスポートエラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareExportInfo(String jobId) {
    final routeAsync = ref.read(routeProvider(widget.routeId));
    routeAsync.whenData((route) {
      final shareText = '''
ルート「${route.title}」のエクスポートを開始しました。

エクスポート形式: ${_selectedFormats.join(', ')}
ジョブID: $jobId

完了後、ダウンロードリンクをお知らせします。
''';
      
      Share.share(shareText);
    });
  }
}

class ExportFormat {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  ExportFormat({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}
