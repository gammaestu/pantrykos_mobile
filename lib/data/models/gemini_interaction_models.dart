/// Typed request/response DTOs and JSON schemas for Google AI Studio's
/// standard Gemini API (`POST /v1beta/models/{model}:generateContent`).
class GeminiInteractionSchemas {
  GeminiInteractionSchemas._();

  /// Structured JSON Schema for pantry ingredient visual detection.
  static const Map<String, dynamic> ingredientDetectionSchema = {
    'type': 'OBJECT',
    'properties': {
      'ingredients': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'id': {'type': 'STRING'},
            'name': {'type': 'STRING'},
            'confidence': {'type': 'NUMBER'},
          },
          'required': ['id', 'name', 'confidence'],
        },
      },
    },
    'required': ['ingredients'],
  };

  /// Minimal structured JSON Schema for instant connectivity checks.
  static const Map<String, dynamic> connectionPingSchema = {
    'type': 'OBJECT',
    'properties': {
      'status': {'type': 'STRING'},
    },
    'required': ['status'],
  };
}

/// Request payload builder for `POST /v1beta/models/{model}:generateContent`.
class GeminiInteractionRequest {
  const GeminiInteractionRequest({
    required this.model,
    required this.parts,
    this.systemInstruction,
    this.thinkingLevel = 'low',
    this.maxOutputTokens = 2048,
    this.responseSchema,
  });

  /// Builds a multimodal image + text vision scan request.
  factory GeminiInteractionRequest.visionScan({
    required String model,
    required String systemInstruction,
    required String prompt,
    required String base64Image,
    required String mimeType,
    String thinkingLevel = 'low',
    int maxOutputTokens = 2048,
  }) {
    return GeminiInteractionRequest(
      model: model,
      systemInstruction: systemInstruction,
      parts: [
        {'text': prompt},
        {
          'inline_data': {
            'mime_type': mimeType,
            'data': base64Image,
          },
        },
      ],
      thinkingLevel: thinkingLevel,
      maxOutputTokens: maxOutputTokens,
      responseSchema: GeminiInteractionSchemas.ingredientDetectionSchema,
    );
  }

  /// Builds a lightweight structured JSON ping request for connection testing.
  factory GeminiInteractionRequest.connectionPing({
    required String model,
    String thinkingLevel = 'low',
    int maxOutputTokens = 256,
  }) {
    return GeminiInteractionRequest(
      model: model,
      parts: const [
        {'text': 'Return ONLY this exact JSON: {"status":"ok"}'},
      ],
      thinkingLevel: thinkingLevel,
      maxOutputTokens: maxOutputTokens,
      responseSchema: GeminiInteractionSchemas.connectionPingSchema,
    );
  }

  final String model;
  final List<dynamic> parts;
  final String? systemInstruction;
  final String thinkingLevel;
  final int maxOutputTokens;
  final Map<String, dynamic>? responseSchema;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> generationConfig = {
      'maxOutputTokens': maxOutputTokens,
      'temperature': 0.2,
      
    };

    if (responseSchema != null) {
      generationConfig['responseMimeType'] = 'application/json';
      generationConfig['responseSchema'] = responseSchema;
    }

    final Map<String, dynamic> body = {
      'contents': [
        {
          'role': 'user',
          'parts': parts,
        },
      ],
      'generationConfig': generationConfig,
    };

    if (systemInstruction != null && systemInstruction!.trim().isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [
          {'text': systemInstruction!.trim()},
        ],
      };
    }

    return body;
  }
}

/// Parsed response model from `POST /v1beta/models/{model}:generateContent`.
class GeminiInteractionResponse {
  const GeminiInteractionResponse({
    required this.id,
    required this.status,
    required this.model,
    required this.outputText,
    this.errorMessage,
  });

  final String id;
  final String status;
  final String model;
  final String outputText;
  final String? errorMessage;

  bool get isFailed =>
      status.toLowerCase() == 'failed' ||
      (errorMessage != null && errorMessage!.trim().isNotEmpty);

  bool get isIncomplete =>
      status.toUpperCase() == 'MAX_TOKENS' ||
      status.toLowerCase() == 'incomplete';

  factory GeminiInteractionResponse.fromJson(Map<String, dynamic> json) {
    String? errorMsg;
    final rawError = json['error'];
    if (rawError is Map) {
      errorMsg = rawError['message']?.toString().trim() ??
          rawError['status']?.toString().trim();
    } else if (rawError != null) {
      errorMsg = rawError.toString().trim();
    }

    final candidates = json['candidates'];
    String finishReason = 'STOP';
    final buffer = StringBuffer();

    if (candidates is List && candidates.isNotEmpty) {
      final first = candidates.first;
      if (first is Map) {
        finishReason = (first['finishReason'] ?? 'STOP').toString();
        final content = first['content'];
        if (content is Map) {
          final parts = content['parts'];
          if (parts is List) {
            for (final part in parts) {
              if (part is Map && part['thought'] != true) {
                final text = part['text']?.toString();
                if (text != null) {
                  buffer.write(text);
                }
              }
            }
          }
        }
      }
    }

    return GeminiInteractionResponse(
      id: (json['responseId'] ?? '').toString(),
      status: errorMsg != null ? 'failed' : finishReason,
      model: (json['modelVersion'] ?? '').toString(),
      outputText: buffer.toString(),
      errorMessage: errorMsg,
    );
  }
}