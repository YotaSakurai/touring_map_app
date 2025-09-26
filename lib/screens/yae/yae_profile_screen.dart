import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/yae_service.dart';
import '../../models/yae_event.dart';

class YaeProfileScreen extends ConsumerStatefulWidget {
  const YaeProfileScreen({super.key});

  @override
  ConsumerState<YaeProfileScreen> createState() => _YaeProfileScreenState();
}

class _YaeProfileScreenState extends ConsumerState<YaeProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ヤエー統計'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: '統計'),
            Tab(icon: Icon(Icons.map), text: 'エリア'),
            Tab(icon: Icon(Icons.history), text: '履歴'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatisticsTab(),
          _buildAreasTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final statisticsAsync = ref.watch(yaeStatisticsProvider);
        
        return statisticsAsync.when(
          data: (statistics) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCards(statistics),
                const SizedBox(height: 24),
                _buildProgressSection(statistics),
                const SizedBox(height: 24),
                _buildAchievementsSection(statistics),
                const SizedBox(height: 24),
                _buildMonthlyChart(statistics),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64),
                const SizedBox(height: 16),
                Text('エラー: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(yaeStatisticsProvider),
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAreasTab() {
    return Consumer(
      builder: (context, ref, child) {
        final statisticsAsync = ref.watch(yaeStatisticsProvider);
        
        return statisticsAsync.when(
          data: (statistics) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '人気エリア',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...statistics.topAreas.asMap().entries.map((entry) {
                final index = entry.key;
                final area = entry.value;
                return _buildAreaCard(area, index + 1);
              }),
              if (statistics.topAreas.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('まだヤエーエリアのデータがありません'),
                    ),
                  ),
                ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('エラー: $error')),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer(
      builder: (context, ref, child) {
        final statisticsAsync = ref.watch(yaeStatisticsProvider);
        
        return statisticsAsync.when(
          data: (statistics) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '最近のヤエー',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...statistics.recentEvents.map((event) => _buildRecentEventCard(event)),
              if (statistics.recentEvents.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('まだヤエーイベントがありません'),
                    ),
                  ),
                ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('エラー: $error')),
        );
      },
    );
  }

  Widget _buildOverviewCards(YaeStatistics statistics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '総ヤエー数',
                statistics.totalYaeCount.toString(),
                Icons.waving_hand,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '今月',
                statistics.thisMonthCount.toString(),
                Icons.calendar_today,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '今年',
                statistics.thisYearCount.toString(),
                Icons.event_note,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '平均信頼度',
                '${statistics.averageConfidence.toStringAsFixed(1)}%',
                Icons.percent,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(YaeStatistics statistics) {
    final nextMilestone = _getNextMilestone(statistics.totalYaeCount);
    final progress = statistics.totalYaeCount / nextMilestone;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '次の目標まで',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${nextMilestone}回ヤエー',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'あと${nextMilestone - statistics.totalYaeCount}回',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(YaeStatistics statistics) {
    final achievements = _getAchievements(statistics);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '実績',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: achievements.map((achievement) => _buildAchievementChip(achievement)).toList(),
            ),
            if (achievements.isEmpty)
              Text(
                'まだ実績がありません。ヤエーを記録して実績を獲得しましょう！',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementChip(Achievement achievement) {
    return Chip(
      avatar: Icon(
        achievement.icon,
        color: achievement.unlocked ? Colors.white : Colors.grey,
        size: 16,
      ),
      label: Text(
        achievement.name,
        style: TextStyle(
          color: achievement.unlocked ? Colors.white : Colors.grey[600],
          fontSize: 12,
        ),
      ),
      backgroundColor: achievement.unlocked 
          ? achievement.color 
          : Colors.grey[300],
    );
  }

  Widget _buildMonthlyChart(YaeStatistics statistics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '月間ヤエー数',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildSimpleChart(statistics),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart(YaeStatistics statistics) {
    // 簡易的な棒グラフを作成
    final monthlyData = _getMonthlyData(statistics);
    final maxValue = monthlyData.values.isNotEmpty 
        ? monthlyData.values.reduce((a, b) => a > b ? a : b)
        : 1;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: monthlyData.entries.map((entry) {
        final month = entry.key;
        final count = entry.value;
        final height = maxValue > 0 ? (count / maxValue) * 160 : 0.0;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (count > 0)
                  Text(
                    count.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                const SizedBox(height: 4),
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  month,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAreaCard(YaeArea area, int rank) {
    final rankColors = [Colors.amber, Colors.grey, Colors.orange];
    final rankColor = rank <= 3 ? rankColors[rank - 1] : Colors.blue;
    
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rankColor,
          child: Text(
            rank.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          area.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${area.count}回のヤエー'),
        trailing: const Icon(Icons.location_on),
      ),
    );
  }

  Widget _buildRecentEventCard(YaeEvent event) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getConfidenceColor(event.confidence),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.waving_hand,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          DateFormat('M月d日 HH:mm').format(event.happenedAt),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '信頼度: ${event.confidence}%',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          _getRelativeTime(event.happenedAt),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ヘルパーメソッド

  int _getNextMilestone(int current) {
    final milestones = [10, 25, 50, 100, 250, 500, 1000];
    return milestones.firstWhere(
      (milestone) => milestone > current,
      orElse: () => ((current / 1000).ceil() + 1) * 1000,
    );
  }

  List<Achievement> _getAchievements(YaeStatistics statistics) {
    final achievements = <Achievement>[];
    
    // 基本実績
    achievements.add(Achievement(
      name: '初回ヤエー',
      icon: Icons.waving_hand,
      color: Colors.green,
      unlocked: statistics.totalYaeCount >= 1,
    ));
    
    achievements.add(Achievement(
      name: 'ヤエー10回',
      icon: Icons.star,
      color: Colors.blue,
      unlocked: statistics.totalYaeCount >= 10,
    ));
    
    achievements.add(Achievement(
      name: 'ヤエー50回',
      icon: Icons.local_fire_department,
      color: Colors.orange,
      unlocked: statistics.totalYaeCount >= 50,
    ));
    
    achievements.add(Achievement(
      name: 'ヤエー100回',
      icon: Icons.emoji_events,
      color: Colors.amber,
      unlocked: statistics.totalYaeCount >= 100,
    ));
    
    // 月間実績
    achievements.add(Achievement(
      name: '月間10回',
      icon: Icons.calendar_month,
      color: Colors.purple,
      unlocked: statistics.thisMonthCount >= 10,
    ));
    
    // 信頼度実績
    achievements.add(Achievement(
      name: '高精度マスター',
      icon: Icons.precision_manufacturing,
      color: Colors.teal,
      unlocked: statistics.averageConfidence >= 80,
    ));
    
    return achievements;
  }

  Map<String, int> _getMonthlyData(YaeStatistics statistics) {
    final now = DateTime.now();
    final monthlyData = <String, int>{};
    
    // 過去6ヶ月のデータを初期化
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthKey = DateFormat('M月').format(month);
      monthlyData[monthKey] = 0;
    }
    
    // 実際のデータを設定（モック）
    final months = monthlyData.keys.toList();
    for (int i = 0; i < months.length; i++) {
      monthlyData[months[i]] = (statistics.totalYaeCount / 6 * (i + 1) / 6).round();
    }
    
    return monthlyData;
  }

  Color _getConfidenceColor(int confidence) {
    if (confidence >= 90) return Colors.green;
    if (confidence >= 70) return Colors.orange;
    return Colors.grey;
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }
}

class Achievement {
  final String name;
  final IconData icon;
  final Color color;
  final bool unlocked;

  Achievement({
    required this.name,
    required this.icon,
    required this.color,
    required this.unlocked,
  });
}
