import 'package:dio/dio.dart';

/// Factory for non-persistent [Dio] clients tuned for Gemini Interactions API
/// calls on Android Emulator and physical mobile devices.
///
/// Disabling persistent keep-alive (`Connection: close`) and gzip chunk
/// buffering (`Accept-Encoding: identity`) prevents Dart `HttpClient` receive
/// stalls while keeping clean standard TLS SNI handshakes intact.
class GeminiHttpClientFactory {
  GeminiHttpClientFactory._();

  static const Duration defaultConnectTimeout = Duration(seconds: 10);
  static const Duration defaultReceiveTimeout = Duration(seconds: 30);

  static Dio create({
    Duration connectTimeout = defaultConnectTimeout,
    Duration receiveTimeout = defaultReceiveTimeout,
  }) {
    return Dio(
      BaseOptions(
        connectTimeout: connectTimeout,
        sendTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        persistentConnection: false,
        responseType: ResponseType.json,
        headers: const <String, String>{
          'Content-Type': 'application/json',
          'Connection': 'close',
          'Accept-Encoding': 'identity',
        },
      ),
    );
  }

  static Options requestOptions({
    required String apiKey,
    Duration sendTimeout = defaultConnectTimeout,
    Duration receiveTimeout = defaultReceiveTimeout,
  }) {
    return Options(
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
      persistentConnection: false,
      responseType: ResponseType.json,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
        'Connection': 'close',
        'Accept-Encoding': 'identity',
      },
    );
  }
}
