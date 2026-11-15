import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../models/recipe_model.dart';

/// Exception thrown when fetching or parsing remote PantryKos catalog data fails.
class RemoteDataSourceException implements Exception {
  final String message;
  final int? statusCode;

  const RemoteDataSourceException(this.message, {this.statusCode});

  @override
  String toString() =>
      'RemoteDataSourceException(statusCode: $statusCode, message: $message)';
}

/// Contract for fetching the remote PantryKos ingredients & recipes JSON catalog.
abstract class RecipeRemoteDataSource {
  Future<PantryCatalogBundle> fetchCatalog({String? overrideUrl});
}

/// `Dio`-backed remote datasource with 8-second connect/receive timeouts.
class RecipeRemoteDataSourceImpl implements RecipeRemoteDataSource {
  RecipeRemoteDataSourceImpl({
    Dio? dio,
    ApiConfig? apiConfig,
  })  : _apiConfig = apiConfig ?? ApiConfig(),
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: ApiConfig.connectTimeout,
                receiveTimeout: ApiConfig.receiveTimeout,
                responseType: ResponseType.plain,
                headers: const <String, String>{
                  'Accept': 'application/json',
                },
              ),
            );

  final Dio _dio;
  final ApiConfig _apiConfig;

  @override
  Future<PantryCatalogBundle> fetchCatalog({String? overrideUrl}) async {
    final targetUrl = (overrideUrl != null && overrideUrl.trim().isNotEmpty)
        ? overrideUrl.trim()
        : _apiConfig.remoteJsonUrl;

    try {
      final response = await _dio.get<dynamic>(
        targetUrl,
        options: Options(
          sendTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          responseType: ResponseType.plain,
        ),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw RemoteDataSourceException(
          'Server returned HTTP $statusCode',
          statusCode: statusCode,
        );
      }

      final payload = response.data;
      final String rawJson;
      if (payload is String) {
        rawJson = payload;
      } else if (payload is Map<String, dynamic>) {
        rawJson = jsonEncode(payload);
      } else {
        throw const RemoteDataSourceException(
          'Unexpected response payload format from remote catalog.',
        );
      }

      return PantryCatalogBundle.fromRawJson(rawJson);
    } on DioException catch (e) {
      throw RemoteDataSourceException(
        e.message ?? 'Network request failed (${e.type.name}).',
        statusCode: e.response?.statusCode,
      );
    } on FormatException catch (e) {
      throw RemoteDataSourceException('Invalid catalog JSON: ${e.message}');
    }
  }
}
