import 'package:dio/dio.dart';

import '../constants/api_config.dart';

typedef TokenGetter = String? Function();

class ApiClient {
  ApiClient({required this.tokenGetter}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final t = tokenGetter();
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
          return handler.next(options);
        },
      ),
    );
  }

  final TokenGetter tokenGetter;
  late final Dio _dio;

  Dio get dio => _dio;
}
