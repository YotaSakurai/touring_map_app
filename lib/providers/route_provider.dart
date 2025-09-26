import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/route.dart';
import '../services/api_service.dart';

/// APIサービスのプロバイダー
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// ルート一覧のプロバイダー
final routesProvider = FutureProvider<List<Route>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getRoutes();
});

/// 特定ユーザーのルート一覧プロバイダー
final userRoutesProvider = FutureProvider.family<List<Route>, String>((ref, userId) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getRoutes(ownerId: userId);
});

/// 公開ルート一覧プロバイダー
final publicRoutesProvider = FutureProvider<List<Route>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getRoutes(visibility: Route.visibilityPublic);
});

/// 特定ルートの詳細プロバイダー
final routeProvider = FutureProvider.family<Route, String>((ref, routeId) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getRoute(routeId);
});

/// タグでフィルタされたルート一覧プロバイダー
final routesByTagProvider = FutureProvider.family<List<Route>, String>((ref, tag) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getRoutes(tags: tag);
});
