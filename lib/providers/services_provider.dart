import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/file_service.dart';

/// APIサービスのプロバイダー
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// 位置情報サービスのプロバイダー
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// ファイルサービスのプロバイダー
final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});
