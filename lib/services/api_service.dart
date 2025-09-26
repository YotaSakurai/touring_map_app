import 'package:dio/dio.dart';
import '../models/route.dart';
import '../models/yae_event.dart';
import '../models/share.dart';

/// APIクライアントサービス
class ApiService {
  late final Dio _dio;
  String? _authToken;

  ApiService({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? 'https://api.example.com/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // 認証トークンを自動で追加
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        handler.next(options);
      },
    ));
  }

  /// 認証トークンを設定
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// 認証トークンをクリア
  void clearAuthToken() {
    _authToken = null;
  }

  // ===== ルート関連API =====

  /// ルートを作成
  Future<Route> createRoute(Map<String, dynamic> routeData) async {
    try {
      final response = await _dio.post('/routes', data: routeData);
      return Route.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// ルート一覧を取得
  Future<List<Route>> getRoutes({
    String? ownerId,
    String? tags,
    String? visibility,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (ownerId != null) queryParams['owner_id'] = ownerId;
      if (tags != null) queryParams['tags'] = tags;
      if (visibility != null) queryParams['visibility'] = visibility;

      final response = await _dio.get('/routes', queryParameters: queryParams);
      return (response.data as List)
          .map((json) => Route.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// ルート詳細を取得
  Future<Route> getRoute(String id) async {
    try {
      final response = await _dio.get('/routes/$id');
      return Route.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// ルートを更新
  Future<Route> updateRoute(String id, Map<String, dynamic> updateData) async {
    try {
      final response = await _dio.patch('/routes/$id', data: updateData);
      return Route.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// ルートを削除
  Future<void> deleteRoute(String id) async {
    try {
      await _dio.delete('/routes/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// ルートをエクスポート
  Future<String> exportRoute(String id, List<String> formats) async {
    try {
      final response = await _dio.post('/routes/$id/export', data: {
        'formats': formats,
      });
      return response.data['job_id'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ===== インポート関連API =====

  /// GPX/KMLファイルをインポート
  Future<String> importFile(String filePath, {
    double simplifyToleranceM = 5.0,
    bool addElevation = true,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'simplify_tolerance_m': simplifyToleranceM,
        'add_elevation': addElevation,
      });

      final response = await _dio.post('/imports', data: formData);
      return response.data['job_id'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ===== 共有関連API =====

  /// 共有トークンを作成
  Future<Share> createShare(String routeId, {DateTime? expiresAt}) async {
    try {
      final response = await _dio.post('/shares', data: {
        'route_id': routeId,
        if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      });
      return Share.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ===== ヤエー関連API =====

  /// ヤエーイベント一覧を取得
  Future<List<YaeEvent>> getYaeEvents() async {
    try {
      final response = await _dio.get('/yae/events');
      return (response.data as List)
          .map((json) => YaeEvent.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ===== エラーハンドリング =====

  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('ネットワーク接続がタイムアウトしました');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'サーバーエラーが発生しました';
        return Exception('エラー ($statusCode): $message');
      case DioExceptionType.cancel:
        return Exception('リクエストがキャンセルされました');
      case DioExceptionType.connectionError:
        return Exception('ネットワーク接続エラーが発生しました');
      default:
        return Exception('予期しないエラーが発生しました: ${e.message}');
    }
  }
}
