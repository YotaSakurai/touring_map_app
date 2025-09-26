import 'package:geolocator/geolocator.dart';

/// 位置情報サービスクラス
class LocationService {
  /// 現在位置を取得
  /// 
  /// 位置情報の許可を確認し、許可されていない場合は例外を投げる
  /// 高精度での位置情報を取得する
  Future<Position> getCurrentLocation() async {
    // 位置情報サービスが有効かチェック
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('位置情報サービスが無効です。設定で有効にしてください。');
    }

    // 位置情報の許可状態をチェック
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 許可をリクエスト
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('位置情報の許可が拒否されました。');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('位置情報の許可が永続的に拒否されました。設定から許可してください。');
    }

    // 高精度で現在位置を取得
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      throw Exception('位置情報の取得に失敗しました: $e');
    }
  }

  /// 位置情報の許可状態をチェック
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// 位置情報サービスが有効かチェック
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 2点間の距離を計算（メートル）
  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// 位置情報の精度をチェック
  bool isLocationAccurate(Position position) {
    // 精度が10メートル以内の場合を高精度とみなす
    return position.accuracy <= 10.0;
  }

  /// 位置情報をGeoJSON Point形式に変換
  Map<String, dynamic> positionToGeoJson(Position position) {
    return {
      'type': 'Point',
      'coordinates': [position.longitude, position.latitude],
    };
  }

  /// GeoJSON Pointから緯度経度を取得
  Map<String, double> geoJsonToLatLng(Map<String, dynamic> geoJson) {
    final coordinates = geoJson['coordinates'] as List<dynamic>;
    return {
      'latitude': coordinates[1].toDouble(),
      'longitude': coordinates[0].toDouble(),
    };
  }
}
