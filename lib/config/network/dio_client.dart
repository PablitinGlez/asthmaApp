import 'package:dio/dio.dart';

/// Cliente HTTP personalizado usando Dio.
class DioClient {
  final Dio _dio;

  String get baseUrl => _dio.options.baseUrl;

  DioClient({
    required String baseUrl,
    int connectTimeout = 90000,
    int receiveTimeout = 90000,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: Duration(milliseconds: connectTimeout),
           receiveTimeout: Duration(milliseconds: receiveTimeout),
           headers: {
             'Content-Type': 'application/json',
             'Accept': 'application/json',
           },
         ),
       ) {
    _dio.interceptors.addAll([
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('🌐 DIO: $obj'),
      ),
      InterceptorsWrapper(
        onError: (error, handler) {
          if (error.response?.statusCode != 404) {
            print(
              '❌ DIO Error: ${error.message} - Status: ${error.response?.statusCode}',
            );
          }

          if (error.response?.statusCode == 401) {
            // Este es el guardia de seguridad que mata sesiones
            // Lanza una excepción específica que nuestra UI o Notifier pueda atrapar
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: DioExceptionType.badResponse,
                error: 'SESSION_EXPIRED',
                message:
                    'Tu sesión ha expirado por seguridad. Por favor, vuelve a iniciar sesión.',
              ),
            );
          }

          return handler.next(error);
        },
      ),
    ]);
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  void addHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  void removeHeader(String key) {
    _dio.options.headers.remove(key);
  }
}
