import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spot.dart';
import '../services/api_service.dart';

/// スポット処理サービス
class SpotService {
  final ApiService _apiService;

  SpotService({required ApiService apiService}) : _apiService = apiService;

  /// スポット一覧を取得
  Future<List<Spot>> getSpots({
    double? latitude,
    double? longitude,
    double? radiusKm,
    List<String>? tags,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      // TODO: 実際のAPI呼び出しに置き換え
      // 現在はモックデータを返す
      return _getMockSpots(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        tags: tags,
        searchQuery: searchQuery,
      );
    } catch (e) {
      debugPrint('スポット取得エラー: $e');
      return [];
    }
  }

  /// 近くのスポットを取得
  Future<List<Spot>> getNearbySpots({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    List<String>? tags,
  }) async {
    return await getSpots(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      tags: tags,
    );
  }

  /// スポットを検索
  Future<List<Spot>> searchSpots(String query, {
    double? latitude,
    double? longitude,
    List<String>? tags,
  }) async {
    return await getSpots(
      latitude: latitude,
      longitude: longitude,
      searchQuery: query,
      tags: tags,
    );
  }

  /// スポット詳細を取得
  Future<Spot?> getSpot(String spotId) async {
    try {
      // TODO: API呼び出し
      final spots = await getSpots();
      return spots.firstWhere(
        (spot) => spot.id == spotId,
        orElse: () => throw Exception('スポットが見つかりません'),
      );
    } catch (e) {
      debugPrint('スポット詳細取得エラー: $e');
      return null;
    }
  }

  /// スポットを作成
  Future<Spot?> createSpot({
    required String name,
    required double latitude,
    required double longitude,
    String? description,
    required List<String> tags,
    Map<String, dynamic>? openHours,
    List<String>? imageUrls,
  }) async {
    try {
      final spotData = {
        'name': name,
        'geom': {
          'type': 'Point',
          'coordinates': [longitude, latitude],
        },
        'description': description,
        'tags': tags,
        'open_hours_json': openHours,
        'image_urls': imageUrls,
      };

      // TODO: API呼び出し
      debugPrint('スポット作成: $name');
      
      // モックスポットを返す
      final spot = Spot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        geom: {
          'type': 'Point',
          'coordinates': [longitude, latitude],
        },
        name: name,
        description: description,
        tags: tags,
        openHoursJson: openHours,
        verified: false,
        createdBy: 'current_user', // TODO: 実際のユーザーIDに置き換え
        createdAt: DateTime.now(),
      );

      return spot;
    } catch (e) {
      debugPrint('スポット作成エラー: $e');
      return null;
    }
  }

  /// スポットを更新
  Future<Spot?> updateSpot(String spotId, Map<String, dynamic> updateData) async {
    try {
      // TODO: API呼び出し
      debugPrint('スポット更新: $spotId');
      
      final spot = await getSpot(spotId);
      return spot;
    } catch (e) {
      debugPrint('スポット更新エラー: $e');
      return null;
    }
  }

  /// スポットを削除
  Future<bool> deleteSpot(String spotId) async {
    try {
      // TODO: API呼び出し
      debugPrint('スポット削除: $spotId');
      return true;
    } catch (e) {
      debugPrint('スポット削除エラー: $e');
      return false;
    }
  }

  /// スポットに評価を投稿
  Future<bool> rateSpot(String spotId, int rating, String? comment) async {
    try {
      // TODO: API呼び出し
      debugPrint('スポット評価: $spotId, 評価: $rating');
      return true;
    } catch (e) {
      debugPrint('スポット評価エラー: $e');
      return false;
    }
  }

  /// スポットをお気に入りに追加/削除
  Future<bool> toggleFavoriteSpot(String spotId) async {
    try {
      // TODO: API呼び出し
      debugPrint('スポットお気に入り切り替え: $spotId');
      return true;
    } catch (e) {
      debugPrint('お気に入り切り替えエラー: $e');
      return false;
    }
  }

  /// スポットを報告
  Future<bool> reportSpot(String spotId, String reason, String? description) async {
    try {
      // TODO: API呼び出し
      debugPrint('スポット報告: $spotId, 理由: $reason');
      return true;
    } catch (e) {
      debugPrint('スポット報告エラー: $e');
      return false;
    }
  }

  /// スポットの営業時間を確認
  bool isSpotOpen(Spot spot, {DateTime? dateTime}) {
    final checkTime = dateTime ?? DateTime.now();
    final openHours = spot.openHoursJson;
    
    if (openHours == null || openHours.isEmpty) {
      return true; // 営業時間が設定されていない場合は営業中とみなす
    }

    try {
      final dayOfWeek = _getDayOfWeekKey(checkTime.weekday);
      final daySchedule = openHours[dayOfWeek] as List<dynamic>?;
      
      if (daySchedule == null || daySchedule.isEmpty) {
        return false; // その日は休業日
      }

      final currentTime = '${checkTime.hour.toString().padLeft(2, '0')}:${checkTime.minute.toString().padLeft(2, '0')}';
      
      for (final schedule in daySchedule) {
        final scheduleList = schedule as List<dynamic>;
        if (scheduleList.length >= 2) {
          final openTime = scheduleList[0] as String;
          final closeTime = scheduleList[1] as String;
          
          if (_isTimeInRange(currentTime, openTime, closeTime)) {
            return true;
          }
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('営業時間確認エラー: $e');
      return true; // エラーの場合は営業中とみなす
    }
  }

  /// スポットの距離を計算
  double calculateDistance(Spot spot, double latitude, double longitude) {
    final coords = spot.geom['coordinates'] as List;
    final spotLng = (coords[0] as num).toDouble();
    final spotLat = (coords[1] as num).toDouble();
    
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      spotLat,
      spotLng,
    );
  }

  /// スポットカテゴリ一覧を取得
  List<SpotCategory> getSpotCategories() {
    return [
      SpotCategory(
        id: 'parking2w',
        name: '二輪駐車場',
        icon: 'motorcycle',
        color: 0xFF2196F3,
        description: 'バイク専用・優先駐車場',
      ),
      SpotCategory(
        id: 'onsen',
        name: '温泉',
        icon: 'hot_tub',
        color: 0xFFFF9800,
        description: '温泉・入浴施設',
      ),
      SpotCategory(
        id: 'rider_welcome',
        name: 'ライダー歓迎',
        icon: 'restaurant',
        color: 0xFF4CAF50,
        description: 'ライダー歓迎の店舗',
      ),
      SpotCategory(
        id: 'gas_station',
        name: 'ガソリンスタンド',
        icon: 'local_gas_station',
        color: 0xFFF44336,
        description: 'ガソリンスタンド',
      ),
      SpotCategory(
        id: 'scenic',
        name: '景勝地',
        icon: 'landscape',
        color: 0xFF9C27B0,
        description: '絶景・観光スポット',
      ),
      SpotCategory(
        id: 'rest_area',
        name: '休憩所',
        icon: 'local_cafe',
        color: 0xFF795548,
        description: '道の駅・PA・SA',
      ),
      SpotCategory(
        id: 'repair',
        name: '修理・整備',
        icon: 'build',
        color: 0xFF607D8B,
        description: 'バイク店・修理工場',
      ),
      SpotCategory(
        id: 'gear_shop',
        name: 'ギアショップ',
        icon: 'shopping_cart',
        color: 0xFFE91E63,
        description: 'バイク用品店',
      ),
    ];
  }

  // プライベートメソッド

  /// モックスポットデータを生成
  List<Spot> _getMockSpots({
    double? latitude,
    double? longitude,
    double? radiusKm,
    List<String>? tags,
    String? searchQuery,
  }) {
    final spots = <Spot>[];
    final random = Random();
    final categories = getSpotCategories();

    // 基準位置（東京駅周辺）
    final baseLat = latitude ?? 35.6812;
    final baseLng = longitude ?? 139.7671;
    final radius = radiusKm ?? 50.0;

    // モックスポットを生成
    for (int i = 0; i < 50; i++) {
      // ランダムな位置を生成
      final distance = random.nextDouble() * radius;
      final bearing = random.nextDouble() * 360;
      
      final spotLat = baseLat + (distance / 111) * cos(bearing * pi / 180);
      final spotLng = baseLng + (distance / (111 * cos(baseLat * pi / 180))) * sin(bearing * pi / 180);

      // ランダムなカテゴリを選択
      final category = categories[random.nextInt(categories.length)];
      final spotTags = [category.id];
      
      // 複数タグの場合もある
      if (random.nextBool()) {
        final additionalCategory = categories[random.nextInt(categories.length)];
        if (!spotTags.contains(additionalCategory.id)) {
          spotTags.add(additionalCategory.id);
        }
      }

      // タグフィルターをチェック
      if (tags != null && tags.isNotEmpty) {
        if (!tags.any((tag) => spotTags.contains(tag))) {
          continue;
        }
      }

      final spotName = _generateSpotName(category, i);
      
      // 検索クエリをチェック
      if (searchQuery != null && searchQuery.isNotEmpty) {
        if (!spotName.toLowerCase().contains(searchQuery.toLowerCase())) {
          continue;
        }
      }

      final spot = Spot(
        id: 'spot_$i',
        geom: {
          'type': 'Point',
          'coordinates': [spotLng, spotLat],
        },
        name: spotName,
        description: _generateSpotDescription(category),
        tags: spotTags,
        openHoursJson: _generateOpenHours(),
        verified: random.nextDouble() > 0.3, // 70%の確率で認証済み
        createdBy: 'user_${random.nextInt(100)}',
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
      );

      spots.add(spot);
    }

    // 距離でソート（位置が指定されている場合）
    if (latitude != null && longitude != null) {
      spots.sort((a, b) {
        final distanceA = calculateDistance(a, latitude, longitude);
        final distanceB = calculateDistance(b, latitude, longitude);
        return distanceA.compareTo(distanceB);
      });
    }

    return spots;
  }

  String _generateSpotName(SpotCategory category, int index) {
    final prefixes = {
      'parking2w': ['バイクパーク', 'モトパーク', 'ライダーズパーク'],
      'onsen': ['温泉', '湯の里', 'スパ'],
      'rider_welcome': ['ライダーズカフェ', 'モトレストラン', 'バイカーズ'],
      'gas_station': ['GS', 'ガソリンスタンド', 'セルフ'],
      'scenic': ['展望台', '絶景スポット', '見晴らし'],
      'rest_area': ['道の駅', '休憩所', 'PA'],
      'repair': ['バイクショップ', '整備工場', 'モトガレージ'],
      'gear_shop': ['バイク用品店', 'ライダーズショップ', 'モトグッズ'],
    };

    final categoryPrefixes = prefixes[category.id] ?? ['スポット'];
    final prefix = categoryPrefixes[index % categoryPrefixes.length];
    
    return '$prefix${String.fromCharCode(65 + (index % 26))}';
  }

  String _generateSpotDescription(SpotCategory category) {
    final descriptions = {
      'parking2w': '二輪車専用の駐車場です。屋根付きで安心してバイクを駐車できます。',
      'onsen': '天然温泉でツーリングの疲れを癒やせます。露天風呂もあります。',
      'rider_welcome': 'ライダー歓迎のお店です。バイク談義ができる仲間が集まります。',
      'gas_station': '24時間営業のセルフサービスガソリンスタンドです。',
      'scenic': '素晴らしい景色を楽しめるスポットです。写真撮影におすすめ。',
      'rest_area': '地元の特産品やお土産が充実した休憩スポットです。',
      'repair': 'バイクの修理・整備を行っています。緊急時にも対応可能です。',
      'gear_shop': 'バイク用品・ウェア・ヘルメットなど幅広く取り扱っています。',
    };

    return descriptions[category.id] ?? 'ライダーにおすすめのスポットです。';
  }

  Map<String, dynamic>? _generateOpenHours() {
    final random = Random();
    
    // 30%の確率で営業時間なし（24時間営業など）
    if (random.nextDouble() < 0.3) {
      return null;
    }

    final openHours = <String, dynamic>{};
    final weekdays = ['mon', 'tue', 'wed', 'thu', 'fri'];
    final weekend = ['sat', 'sun'];

    // 平日の営業時間
    final weekdayOpen = '09:00';
    final weekdayClose = random.nextBool() ? '18:00' : '20:00';
    
    for (final day in weekdays) {
      openHours[day] = [[weekdayOpen, weekdayClose]];
    }

    // 週末の営業時間
    final weekendOpen = '08:00';
    final weekendClose = random.nextBool() ? '19:00' : '21:00';
    
    for (final day in weekend) {
      if (random.nextDouble() > 0.1) { // 90%の確率で営業
        openHours[day] = [[weekendOpen, weekendClose]];
      }
    }

    return openHours;
  }

  String _getDayOfWeekKey(int weekday) {
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return days[weekday - 1];
  }

  bool _isTimeInRange(String currentTime, String openTime, String closeTime) {
    final current = _timeToMinutes(currentTime);
    final open = _timeToMinutes(openTime);
    final close = _timeToMinutes(closeTime);

    if (close > open) {
      // 同日内（例: 09:00-18:00）
      return current >= open && current <= close;
    } else {
      // 日跨ぎ（例: 22:00-06:00）
      return current >= open || current <= close;
    }
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }
}

/// スポットカテゴリ
class SpotCategory {
  final String id;
  final String name;
  final String icon;
  final int color;
  final String description;

  SpotCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

/// スポットサービスのプロバイダー
final spotServiceProvider = Provider<SpotService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return SpotService(apiService: apiService);
});

/// スポット一覧のプロバイダー
final spotsProvider = FutureProvider<List<Spot>>((ref) async {
  final spotService = ref.read(spotServiceProvider);
  return await spotService.getSpots();
});

/// 近くのスポットのプロバイダー
final nearbySpotsProvider = FutureProvider.family<List<Spot>, Position>((ref, position) async {
  final spotService = ref.read(spotServiceProvider);
  return await spotService.getNearbySpots(
    latitude: position.latitude,
    longitude: position.longitude,
  );
});

/// スポット検索のプロバイダー
final spotSearchProvider = FutureProvider.family<List<Spot>, String>((ref, query) async {
  final spotService = ref.read(spotServiceProvider);
  return await spotService.searchSpots(query);
});

/// スポット詳細のプロバイダー
final spotProvider = FutureProvider.family<Spot?, String>((ref, spotId) async {
  final spotService = ref.read(spotServiceProvider);
  return await spotService.getSpot(spotId);
});

/// スポットカテゴリのプロバイダー
final spotCategoriesProvider = Provider<List<SpotCategory>>((ref) {
  final spotService = ref.read(spotServiceProvider);
  return spotService.getSpotCategories();
});
