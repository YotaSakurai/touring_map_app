import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_service.dart';

/// 位置情報サービスのプロバイダー
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// 現在位置のプロバイダー
final currentPositionProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  try {
    return await locationService.getCurrentPosition();
  } catch (e) {
    return null;
  }
});

/// 位置情報の許可状態プロバイダー
final locationPermissionProvider = FutureProvider<LocationPermission>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return await locationService.checkPermission();
});
