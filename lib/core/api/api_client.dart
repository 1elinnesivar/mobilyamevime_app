import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'api_response.dart';

const _phpUrl =
    'https://www.mobilyamevime.com/furnituresnzk/php/mobilyamevimeapp/index.php';
const _proxyUrl = 'https://mobilyamevime-app.vercel.app/api/proxy';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    dio: Dio(
      BaseOptions(
        baseUrl: kIsWeb ? _proxyUrl : _phpUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    ),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

class ApiClient {
  ApiClient({required Dio dio, required TokenStorage tokenStorage})
      : _dio = dio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<ApiResponse<Map<String, dynamic>>> post(
    String action, {
    Map<String, dynamic> payload = const {},
    bool auth = true,
  }) async {
    try {
      final token = auth ? await _tokenStorage.read() : null;
      final response = await _dio.post<dynamic>(
        '',
        data: {
          'action': action,
          if (token != null && token.isNotEmpty) 'token': token,
          'payload': payload,
        },
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const ApiException('Sunucudan beklenmeyen cevap geldi.');
      }

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        body,
        (data) => data is Map<String, dynamic> ? data : <String, dynamic>{},
      );

      if (!apiResponse.success) {
        throw ApiException(
          apiResponse.message.isEmpty ? 'Islem basarisiz.' : apiResponse.message,
          statusCode: response.statusCode,
        );
      }

      return apiResponse;
    } on DioException catch (error) {
      final data = error.response?.data;
      var message = 'Baglanti kurulamadı. Internet baglantinizi kontrol edin.';
      if (data is Map<String, dynamic> && data['message'] != null) {
        message = data['message'].toString();
      }
      throw ApiException(message, statusCode: error.response?.statusCode);
    }
  }
}
