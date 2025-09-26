import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/yae_event.dart';
import '../../services/yae_service.dart';
import 'yae_detail_screen.dart';
import 'yae_profile_screen.dart';

class YaeHistoryScreen extends ConsumerStatefulWidget {
  const YaeHistoryScreen({super.key});

  @override
  ConsumerState<YaeHistoryScreen> createState() => _YaeHistoryScreenState();
}

class _YaeHistoryScreenState extends ConsumerState<YaeHistoryScreen> {
  String _selectedFilter = 'all';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ヤエー履歴'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const YaeProfileScreen(),
                ),
              );
            },
            tooltip: 'ヤエー統計',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showTrackingSettings();
            },
            tooltip: 'ヤエー設定',
          ),
        ],
      ),
      body: Column(
        children: [
          // ヤエー追跡状態表示
          _buildTrackingStatus(),
          
          // フィルター
          _buildFilterChips(),
          
          // ヤエー履歴一覧
          Expanded(
            child: _buildYaeHistory(),
          ),
        ],
      ),
      floatingActionButton: _buildTrackingFAB(),
    );
  }

  Widget _buildTrackingStatus() {
    return Consumer(
      builder: (context, ref, child) {
        final isTracking = ref.watch(yaeTrackingProvider);
        
        if (!isTracking) return const SizedBox.shrink();
        
        return Container(
          width: double.infinity,
          color: Colors.green[50],
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ヤエー記録中...',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '他のライダーとの遭遇を自動記録中',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'すべて'),
            _buildFilterChip('today', '今日'),
            _buildFilterChip('week', '今週'),
            _buildFilterChip('month', '今月'),
            _buildFilterChip('high_confidence', '高信頼度'),
          ],
        ),
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

  Widget _buildYaeHistory() {
    return Consumer(
      builder: (context, ref, child) {
        final yaeEventsAsync = ref.watch(yaeEventsProvider);
        
        return yaeEventsAsync.when(
          data: (events) {
            final filteredEvents = _filterEvents(events);
            
            if (filteredEvents.isEmpty) {
              return _buildEmptyState();
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(yaeEventsProvider);
              },
              child: ListView.builder(
                controller: _scrollController,
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  final isFirstOfDay = index == 0 || 
                      !_isSameDay(event.happenedAt, filteredEvents[index - 1].happenedAt);
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isFirstOfDay) _buildDateHeader(event.happenedAt),
                      _buildYaeEventCard(event),
                    ],
                  );
                },
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => _buildErrorState(error),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isTrackingEnabled = ref.watch(yaeTrackingProvider);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.waving_hand,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isTrackingEnabled ? 'まだヤエーがありません' : 'ヤエー記録が無効です',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isTrackingEnabled 
                ? 'ツーリングに出かけて他のライダーと出会ってみましょう！'
                : 'ヤエー記録を有効にして、他のライダーとの遭遇を記録しましょう',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (!isTrackingEnabled) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startTracking,
              icon: const Icon(Icons.play_arrow),
              label: const Text('ヤエー記録を開始'),
            ),
          ],
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
              ref.invalidate(yaeEventsProvider);
            },
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Text(
        DateFormat('yyyy年M月d日 (E)', 'ja_JP').format(date),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildYaeEventCard(YaeEvent event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getConfidenceColor(event.confidence),
          child: const Icon(
            Icons.waving_hand,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.access_time, size: 16),
            const SizedBox(width: 4),
            Text(
              DateFormat('HH:mm').format(event.happenedAt),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            _buildConfidenceBadge(event.confidence),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getLocationText(event.geom),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            if (event.confidence >= 80) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '高信頼度',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleEventAction(value, event),
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
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('共有'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'like',
              child: ListTile(
                leading: Icon(Icons.favorite_border),
                title: Text('いいね'),
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
              builder: (context) => YaeDetailScreen(event: event),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfidenceBadge(int confidence) {
    Color color;
    String text;
    
    if (confidence >= 90) {
      color = Colors.green;
      text = '確実';
    } else if (confidence >= 70) {
      color = Colors.orange;
      text = '可能性高';
    } else {
      color = Colors.grey;
      text = '可能性低';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$confidence% $text',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTrackingFAB() {
    return Consumer(
      builder: (context, ref, child) {
        final isTracking = ref.watch(yaeTrackingProvider);
        
        return FloatingActionButton.extended(
          onPressed: isTracking ? _stopTracking : _startTracking,
          icon: Icon(isTracking ? Icons.stop : Icons.play_arrow),
          label: Text(isTracking ? '記録停止' : '記録開始'),
          backgroundColor: isTracking ? Colors.red : Colors.green,
        );
      },
    );
  }

  // プライベートメソッド

  List<YaeEvent> _filterEvents(List<YaeEvent> events) {
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case 'today':
        final today = DateTime(now.year, now.month, now.day);
        return events.where((e) => e.happenedAt.isAfter(today)).toList();
      
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return events.where((e) => e.happenedAt.isAfter(weekAgo)).toList();
      
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return events.where((e) => e.happenedAt.isAfter(monthAgo)).toList();
      
      case 'high_confidence':
        return events.where((e) => e.confidence >= 80).toList();
      
      default:
        return events;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Color _getConfidenceColor(int confidence) {
    if (confidence >= 90) return Colors.green;
    if (confidence >= 70) return Colors.orange;
    return Colors.grey;
  }

  String _getLocationText(Map<String, dynamic> geom) {
    try {
      final coords = geom['coordinates'] as List;
      final lat = (coords[1] as num).toDouble();
      final lng = (coords[0] as num).toDouble();
      
      // 簡易的な地域判定
      if (lat >= 35.5 && lat <= 35.8 && lng >= 139.5 && lng <= 139.8) {
        return '東京都内';
      } else if (lat >= 34.5 && lat <= 35.0 && lng >= 135.0 && lng <= 135.5) {
        return '大阪府内';
      } else {
        return '${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}';
      }
    } catch (e) {
      return '位置情報不明';
    }
  }

  Future<void> _startTracking() async {
    final yaeService = ref.read(yaeServiceProvider);
    final success = await yaeService.startYaeRecording();
    
    if (success) {
      ref.read(yaeTrackingProvider.notifier).state = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ヤエー記録を開始しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ヤエー記録の開始に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopTracking() async {
    final yaeService = ref.read(yaeServiceProvider);
    await yaeService.stopYaeRecording();
    
    ref.read(yaeTrackingProvider.notifier).state = false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ヤエー記録を停止しました'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showTrackingSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ヤエー記録設定',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('位置情報の精度'),
              subtitle: const Text('高精度（推奨）'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 精度設定画面
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('検出間隔'),
              subtitle: const Text('30秒'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 間隔設定画面
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('プライバシー設定'),
              subtitle: const Text('位置情報の匿名化'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: プライバシー設定画面
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleEventAction(String action, YaeEvent event) async {
    final yaeService = ref.read(yaeServiceProvider);
    
    switch (action) {
      case 'view':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => YaeDetailScreen(event: event),
          ),
        );
        break;
      
      case 'share':
        final shareUrl = await yaeService.shareYaeEvent(event.id);
        if (shareUrl != null && mounted) {
          // TODO: 共有機能の実装
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('共有機能（実装予定）')),
          );
        }
        break;
      
      case 'like':
        final success = await yaeService.likeYaeEvent(event.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('いいねしました！')),
          );
        }
        break;
      
      case 'delete':
        _showDeleteDialog(event);
        break;
    }
  }

  void _showDeleteDialog(YaeEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ヤエーイベントを削除'),
        content: Text(
          '${DateFormat('yyyy/MM/dd HH:mm').format(event.happenedAt)}のヤエーイベントを削除しますか？\nこの操作は取り消せません。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteEvent(event);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(YaeEvent event) async {
    final yaeService = ref.read(yaeServiceProvider);
    final success = await yaeService.deleteYaeEvent(event.id);
    
    if (success) {
      ref.invalidate(yaeEventsProvider);
      if (mounted) {
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
