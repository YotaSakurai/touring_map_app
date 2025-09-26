import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/yae_event.dart';
import '../services/api_service.dart';

/// バックグラウンド位置追跡サービス
class BackgroundLocationService {
  static final BackgroundLocationService _instance = BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _yaeDetectionTimer;
  bool _isTracking = false;
  Position? _lastPosition;
  DateTime? _lastYaeDetection;
  
  // 設定値
  static const double _proximityThreshold = 80.0; // 80m
  static const Duration _detectionInterval = Duration(seconds: 30);
  static const Duration _positionUpdateInterval = Duration(seconds: 20);
  static const Duration _timeWindow = Duration(seconds: 60); // ±60秒

  /// 位置追跡を開始
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    try {
      // 位置情報権限の確認
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied) {
          debugPrint('位置情報権限が拒否されました');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('位置情報権限が永続的に拒否されています');
        return false;
      }

      // 位置情報サービスが有効かチェック
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('位置情報サービスが無効です');
        return false;
      }

      // 位置追跡開始
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // 10m移動で更新
        ),
      ).listen(
        _onPositionUpdate,
        onError: _onPositionError,
      );

      // ヤエー検出タイマー開始
      _yaeDetectionTimer = Timer.periodic(_detectionInterval, (_) {
        _detectYaeEvents();
      });

      _isTracking = true;
      debugPrint('バックグラウンド位置追跡を開始しました');
      return true;
    } catch (e) {
      debugPrint('位置追跡開始エラー: $e');
      return false;
    }
  }

  /// 位置追跡を停止
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    await _positionSubscription?.cancel();
    _yaeDetectionTimer?.cancel();
    
    _positionSubscription = null;
    _yaeDetectionTimer = null;
    _isTracking = false;
    _lastPosition = null;
    _lastYaeDetection = null;

    debugPrint('バックグラウンド位置追跡を停止しました');
  }

  /// 位置情報更新時の処理
  void _onPositionUpdate(Position position) {
    _lastPosition = position;
    debugPrint('位置更新: ${position.latitude}, ${position.longitude}');
  }

  /// 位置情報エラー時の処理
  void _onPositionError(dynamic error) {
    debugPrint('位置情報エラー: $error');
  }

  /// ヤエーイベント検出
  Future<void> _detectYaeEvents() async {
    if (_lastPosition == null) return;

    try {
      // 最後の検出から一定時間経過しているかチェック
      if (_lastYaeDetection != null &&
          DateTime.now().difference(_lastYaeDetection!) < _detectionInterval) {
        return;
      }

      // 近接ユーザーを検索
      final nearbyUsers = await _findNearbyUsers(_lastPosition!);
      
      for (final user in nearbyUsers) {
        final confidence = _calculateConfidence(_lastPosition!, user);
        
        if (confidence >= 70) { // 信頼度70%以上
          await _createYaeEvent(_lastPosition!, user, confidence);
        }
      }

      _lastYaeDetection = DateTime.now();
    } catch (e) {
      debugPrint('ヤエー検出エラー: $e');
    }
  }

  /// 近接ユーザーを検索
  Future<List<NearbyUser>> _findNearbyUsers(Position currentPosition) async {
    // TODO: 実際のAPI呼び出しに置き換え
    // 現在はモックデータを返す
    return _getMockNearbyUsers(currentPosition);
  }

  /// モック近接ユーザーデータ
  List<NearbyUser> _getMockNearbyUsers(Position currentPosition) {
    // テスト用の近接ユーザーを生成
    final random = Random();
    final users = <NearbyUser>[];

    // ランダムに0-3人の近接ユーザーを生成
    final userCount = random.nextInt(4);
    for (int i = 0; i < userCount; i++) {
      // 現在位置から80m以内のランダムな位置を生成
      final distance = random.nextDouble() * _proximityThreshold;
      final bearing = random.nextDouble() * 360;
      
      final nearbyLat = currentPosition.latitude + 
          (distance / 111000) * cos(bearing * pi / 180);
      final nearbyLng = currentPosition.longitude + 
          (distance / (111000 * cos(currentPosition.latitude * pi / 180))) * 
          sin(bearing * pi / 180);

      users.add(NearbyUser(
        userId: 'user_${random.nextInt(1000)}',
        position: Position(
          latitude: nearbyLat,
          longitude: nearbyLng,
          timestamp: DateTime.now().subtract(Duration(seconds: random.nextInt(60))),
          accuracy: 10.0,
          altitude: 0.0,
          heading: random.nextDouble() * 360,
          speed: random.nextDouble() * 50,
          speedAccuracy: 1.0,
        ),
        speed: random.nextDouble() * 50,
        heading: random.nextDouble() * 360,
      ));
    }

    return users;
  }

  /// 信頼度を計算
  int _calculateConfidence(Position currentPos, NearbyUser nearbyUser) {
    int confidence = 50; // 基本信頼度

    // 距離による調整
    final distance = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      nearbyUser.position.latitude,
      nearbyUser.position.longitude,
    );

    if (distance <= 20) {
      confidence += 30; // 20m以内は高信頼度
    } else if (distance <= 50) {
      confidence += 20; // 50m以内は中信頼度
    } else if (distance <= 80) {
      confidence += 10; // 80m以内は低信頼度
    }

    // 速度による調整
    if (currentPos.speed > 10 && nearbyUser.speed > 10) {
      confidence += 10; // 両方とも移動中
    }

    // 方位による調整（逆向き・交差）
    final currentHeading = currentPos.heading ?? 0;
    final nearbyHeading = nearbyUser.heading;
    final headingDiff = (currentHeading - nearbyHeading).abs();
    
    if (headingDiff > 90 && headingDiff < 270) {
      confidence += 20; // 逆向き・交差は高信頼度
    }

    // 時間差による調整
    final timeDiff = DateTime.now().difference(nearbyUser.position.timestamp).inSeconds;
    if (timeDiff <= 30) {
      confidence += 10; // 30秒以内は高信頼度
    } else if (timeDiff <= 60) {
      confidence += 5; // 60秒以内は中信頼度
    }

    return confidence.clamp(0, 100);
  }

  /// ヤエーイベントを作成
  Future<void> _createYaeEvent(Position currentPos, NearbyUser nearbyUser, int confidence) async {
    try {
      // 中間地点を計算
      final midLat = (currentPos.latitude + nearbyUser.position.latitude) / 2;
      final midLng = (currentPos.longitude + nearbyUser.position.longitude) / 2;

      final yaeEvent = YaeEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userA: 'current_user', // TODO: 実際のユーザーIDに置き換え
        userB: nearbyUser.userId,
        geom: {
          'type': 'Point',
          'coordinates': [midLng, midLat],
        },
        happenedAt: DateTime.now(),
        confidence: confidence,
        createdAt: DateTime.now(),
      );

      // TODO: APIに送信
      debugPrint('ヤエーイベント作成: ${yaeEvent.id}, 信頼度: $confidence%');
      
      // ローカルに保存（後でAPIに送信）
      await _saveYaeEventLocally(yaeEvent);
      
    } catch (e) {
      debugPrint('ヤエーイベント作成エラー: $e');
    }
  }

  /// ヤエーイベントをローカルに保存
  Future<void> _saveYaeEventLocally(YaeEvent event) async {
    // TODO: ローカルデータベースに保存
    debugPrint('ヤエーイベントをローカルに保存: ${event.id}');
  }

  /// 追跡状態を取得
  bool get isTracking => _isTracking;

  /// 最後の位置情報を取得
  Position? get lastPosition => _lastPosition;
}

/// 近接ユーザー情報
class NearbyUser {
  final String userId;
  final Position position;
  final double speed;
  final double heading;

  NearbyUser({
    required this.userId,
    required this.position,
    required this.speed,
    required this.heading,
  });
}

/// バックグラウンド位置追跡サービスのプロバイダー
final backgroundLocationServiceProvider = Provider<BackgroundLocationService>((ref) {
  return BackgroundLocationService();
});

/// 位置追跡状態のプロバイダー
final locationTrackingProvider = StateProvider<bool>((ref) {
  return false;
});

/// 最後の位置情報のプロバイダー
final lastPositionProvider = StateProvider<Position?>((ref) {
  return null;
});
