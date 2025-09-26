import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/yae_event.dart';
import '../services/api_service.dart';
import '../services/background_location_service.dart';

/// ヤエー処理サービス
class YaeService {
  final ApiService _apiService;
  final BackgroundLocationService _locationService;

  YaeService({
    required ApiService apiService,
    required BackgroundLocationService locationService,
  }) : _apiService = apiService,
       _locationService = locationService;

  /// ヤエー記録を開始
  Future<bool> startYaeRecording() async {
    try {
      final success = await _locationService.startTracking();
      if (success) {
        debugPrint('ヤエー記録を開始しました');
      }
      return success;
    } catch (e) {
      debugPrint('ヤエー記録開始エラー: $e');
      return false;
    }
  }

  /// ヤエー記録を停止
  Future<void> stopYaeRecording() async {
    try {
      await _locationService.stopTracking();
      debugPrint('ヤエー記録を停止しました');
    } catch (e) {
      debugPrint('ヤエー記録停止エラー: $e');
    }
  }

  /// ヤエーイベント一覧を取得
  Future<List<YaeEvent>> getYaeEvents({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      // TODO: 実際のAPI呼び出しに置き換え
      // 現在はモックデータを返す
      return _getMockYaeEvents();
    } catch (e) {
      debugPrint('ヤエーイベント取得エラー: $e');
      return [];
    }
  }

  /// ヤエー統計情報を取得
  Future<YaeStatistics> getYaeStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final events = await getYaeEvents(
        startDate: startDate,
        endDate: endDate,
      );

      return YaeStatistics(
        totalYaeCount: events.length,
        thisMonthCount: _getThisMonthCount(events),
        thisYearCount: _getThisYearCount(events),
        averageConfidence: _getAverageConfidence(events),
        topAreas: _getTopAreas(events),
        recentEvents: events.take(10).toList(),
      );
    } catch (e) {
      debugPrint('ヤエー統計取得エラー: $e');
      return YaeStatistics.empty();
    }
  }

  /// ヤエーイベントを削除
  Future<bool> deleteYaeEvent(String eventId) async {
    try {
      // TODO: API呼び出し
      debugPrint('ヤエーイベントを削除: $eventId');
      return true;
    } catch (e) {
      debugPrint('ヤエーイベント削除エラー: $e');
      return false;
    }
  }

  /// ヤエーイベントにいいね
  Future<bool> likeYaeEvent(String eventId) async {
    try {
      // TODO: API呼び出し
      debugPrint('ヤエーイベントにいいね: $eventId');
      return true;
    } catch (e) {
      debugPrint('ヤエーイベントいいねエラー: $e');
      return false;
    }
  }

  /// ヤエーイベントを共有
  Future<String?> shareYaeEvent(String eventId) async {
    try {
      // TODO: API呼び出し
      debugPrint('ヤエーイベントを共有: $eventId');
      return 'https://example.com/yae/$eventId';
    } catch (e) {
      debugPrint('ヤエーイベント共有エラー: $e');
      return null;
    }
  }

  /// 追跡状態を取得
  bool get isTracking => _locationService.isTracking;

  /// 最後の位置情報を取得
  Position? get lastPosition => _locationService.lastPosition;

  // プライベートメソッド

  /// モックヤエーイベントデータを生成
  List<YaeEvent> _getMockYaeEvents() {
    final now = DateTime.now();
    final events = <YaeEvent>[];

    // 過去30日分のモックデータを生成
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final eventCount = (i % 7 == 0) ? 3 : (i % 3 == 0) ? 1 : 0;

      for (int j = 0; j < eventCount; j++) {
        final event = YaeEvent(
          id: 'yae_${date.millisecondsSinceEpoch}_$j',
          userA: 'current_user',
          userB: 'user_${1000 + j}',
          geom: {
            'type': 'Point',
            'coordinates': [
              139.6503 + (j * 0.01), // 東京周辺
              35.6762 + (j * 0.01),
            ],
          },
          happenedAt: date.add(Duration(hours: j * 2)),
          confidence: 70 + (j * 10),
          createdAt: date,
        );
        events.add(event);
      }
    }

    // 日時順でソート（新しい順）
    events.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    return events;
  }

  /// 今月のヤエー数を取得
  int _getThisMonthCount(List<YaeEvent> events) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    
    return events.where((event) {
      return event.happenedAt.isAfter(thisMonth);
    }).length;
  }

  /// 今年のヤエー数を取得
  int _getThisYearCount(List<YaeEvent> events) {
    final now = DateTime.now();
    final thisYear = DateTime(now.year);
    
    return events.where((event) {
      return event.happenedAt.isAfter(thisYear);
    }).length;
  }

  /// 平均信頼度を取得
  double _getAverageConfidence(List<YaeEvent> events) {
    if (events.isEmpty) return 0.0;
    
    final totalConfidence = events.fold<int>(
      0,
      (sum, event) => sum + event.confidence,
    );
    
    return totalConfidence / events.length;
  }

  /// 人気エリアを取得
  List<YaeArea> _getTopAreas(List<YaeEvent> events) {
    final areaCounts = <String, int>{};
    
    for (final event in events) {
      final coords = event.geom['coordinates'] as List;
      final lat = (coords[1] as num).toDouble();
      final lng = (coords[0] as num).toDouble();
      
      // 地域を特定（簡易版）
      final area = _getAreaName(lat, lng);
      areaCounts[area] = (areaCounts[area] ?? 0) + 1;
    }
    
    final sortedAreas = areaCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedAreas.take(5).map((entry) {
      return YaeArea(
        name: entry.key,
        count: entry.value,
      );
    }).toList();
  }

  /// 座標から地域名を取得（簡易版）
  String _getAreaName(double lat, double lng) {
    // 簡易的な地域判定
    if (lat >= 35.5 && lat <= 35.8 && lng >= 139.5 && lng <= 139.8) {
      return '東京';
    } else if (lat >= 34.5 && lat <= 35.0 && lng >= 135.0 && lng <= 135.5) {
      return '大阪';
    } else if (lat >= 35.0 && lat <= 35.5 && lng >= 136.0 && lng <= 136.5) {
      return '名古屋';
    } else {
      return 'その他';
    }
  }
}

/// ヤエー統計情報
class YaeStatistics {
  final int totalYaeCount;
  final int thisMonthCount;
  final int thisYearCount;
  final double averageConfidence;
  final List<YaeArea> topAreas;
  final List<YaeEvent> recentEvents;

  YaeStatistics({
    required this.totalYaeCount,
    required this.thisMonthCount,
    required this.thisYearCount,
    required this.averageConfidence,
    required this.topAreas,
    required this.recentEvents,
  });

  factory YaeStatistics.empty() {
    return YaeStatistics(
      totalYaeCount: 0,
      thisMonthCount: 0,
      thisYearCount: 0,
      averageConfidence: 0.0,
      topAreas: [],
      recentEvents: [],
    );
  }
}

/// ヤエーエリア情報
class YaeArea {
  final String name;
  final int count;

  YaeArea({
    required this.name,
    required this.count,
  });
}

/// ヤエーサービスのプロバイダー
final yaeServiceProvider = Provider<YaeService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final locationService = ref.read(backgroundLocationServiceProvider);
  
  return YaeService(
    apiService: apiService,
    locationService: locationService,
  );
});

/// ヤエーイベント一覧のプロバイダー
final yaeEventsProvider = FutureProvider<List<YaeEvent>>((ref) async {
  final yaeService = ref.read(yaeServiceProvider);
  return await yaeService.getYaeEvents();
});

/// ヤエー統計のプロバイダー
final yaeStatisticsProvider = FutureProvider<YaeStatistics>((ref) async {
  final yaeService = ref.read(yaeServiceProvider);
  return await yaeService.getYaeStatistics();
});

/// ヤエー追跡状態のプロバイダー
final yaeTrackingProvider = StateProvider<bool>((ref) {
  final yaeService = ref.read(yaeServiceProvider);
  return yaeService.isTracking;
});
