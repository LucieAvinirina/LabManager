import 'package:dio/dio.dart';
import '../constants/app_endpoints.dart';
import '../storage/secure_storage.dart';
 
// ─── Client HTTP centralisé pour tous les appels API ─────────────────────────
class ApiClient {
  static final Dio _dio = Dio();
 
  static Dio get instance {
    _dio.options = BaseOptions(
      baseUrl:        AppEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    );
 
    // ─── Intercepteur : ajouter le token JWT automatiquement ──
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
 
        onError: (error, handler) {
          // Afficher les erreurs dans la console pour debug
          print('❌ API Error: ${error.response?.statusCode} - ${error.message}');
          return handler.next(error);
        },
      ),
    );
 
    return _dio;
  }
 
  // ─── Méthodes helper ──────────────────────────────────────
 
  static Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return await instance.get(path, queryParameters: params);
  }
 
  static Future<Response> post(String path, {dynamic data}) async {
    return await instance.post(path, data: data);
  }
 
  static Future<Response> put(String path, {dynamic data}) async {
    return await instance.put(path, data: data);
  }
 
  static Future<Response> patch(String path, {dynamic data}) async {
    return await instance.patch(path, data: data);
  }
 
  static Future<Response> delete(String path) async {
    return await instance.delete(path);
  }
}