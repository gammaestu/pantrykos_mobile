/// Typed request/response DTOs and JSON schemas for Google AI Studio's
/// unified Gemini Interactions API (`POST /v1beta/interactions`).
class GeminiInteractionSchemas {
  GeminiInteractionSchemas._();

  /// Structured JSON Schema for pantry ingredient visual detection.
  static const Map<String, dynamic> ingredientDetectionSchema =
      <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'ingredients': <String, dynamic>{
            'type': 'array',
            'items': <String, dynamic>{
              'type': 'object',
              'properties': <String, dynamic>{
                'id': <String, dynamic>{'type': 'string'},
                'name': <String, dynamic>{'type': 'string'},
                'confidence': <String, dynamic>{'type': 'number'},
              },
              'required': <String>['id', 'name', 'confidence'],
            },
          },
        },
        'required': <String>['ingredients'],
      };

  /// Minimal structured JSON Schema for instant connectivity checks.
  static const Map<String, dynamic> connectionPingSchema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'status': <String, dynamic>{'type': 'string'},
    },
    'required': <String>['status'],
  };
}

/// Request payload builder for `POST https://generativelanguage.googleapis.com/v1beta/interactions`.
class GeminiInteractionRequest {
  const GeminiInteractionRequest({
    required this.model,
    required this.input,
    this.systemInstruction,
    this.thinkingLevel = 'low',
    this.maxOutputTokens = 2048,
    this.responseSchema,
  });

  /// Builds a multimodal image + text vision scan interaction request.
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
      input: <Map<String, dynamic>>[
        <String, dynamic>{'type': 'text', 'text': prompt},
        <String, dynamic>{
          'type': 'image',
          'data': base64Image,
          'mime_type': mimeType,
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
      input: 'Return ONLY this exact JSON: {"status":"ok"}',
      thinkingLevel: thinkingLevel,
      maxOutputTokens: maxOutputTokens,
      responseSchema: GeminiInteractionSchemas.connectionPingSchema,
    );
  }

  final String model;
  final Object input;
  final String? systemInstruction;
  final String thinkingLevel;
  final int maxOutputTokens;
  final Map<String, dynamic>? responseSchema;

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'model': model,
      'input': input,
      'generation_config': <String, dynamic>{
        'thinking_level': thinkingLevel,
        'max_output_tokens': maxOutputTokens,
      },
    };

    if (systemInstruction != null && systemInstruction!.trim().isNotEmpty) {
      body['system_instruction'] = systemInstruction!.trim();
    }

    if (responseSchema != null) {
      body['response_format'] = <String, dynamic>{
        'type': 'text',
        'mime_type': 'application/json',
        'schema': responseSchema,
      };
    }

    return body;
  }
}

/// Parsed response model from `POST /v1beta/interactions`.
///
/// Extracts text strictly from `model_output` steps (skipping internal
/// `thought` steps), with defensive fallbacks for `outputs` and `output_text`.
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

  bool get isIncomplete => status.toLowerCase() == 'incomplete';

  factory GeminiInteractionResponse.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    final status = (json['status'] ?? 'completed').toString();
    final model = (json['model'] ?? '').toString();

    String? errorMsg;
    final rawError = json['error'];
    if (rawError is Map) {
      errorMsg = rawError['message']?.toString().trim() ??
          rawError['code']?.toString().trim();
    } else if (rawError != null) {
      errorMsg = rawError.toString().trim();
    }

    final outputText = _extractOutputText(json);

    return GeminiInteractionResponse(
      id: id,
      status: status,
      model: model,
      outputText: outputText,
      errorMessage: errorMsg,
    );
  }

  static String _extractOutputText(Map<String, dynamic> json) {
    final buffer = StringBuffer();

    // 1. Primary Interactions API schema: `steps` array with `type: "model_output"`.
    final steps = json['steps'];
    if (steps is List) {
      for (final step in steps) {
        if (step is! Map) continue;
        final stepType = step['type']?.toString();
        if (stepType != 'model_output') continue;

        final content = step['content'];
        if (content is List) {
          for (final block in content) {
            if (block is! Map) continue;
            final blockType = block['type']?.toString();
            if (blockType == null || blockType == 'text') {
              final text = block['text']?.toString();
              if (text != null) {
                buffer.write(text);
              }
            }
          }
        } else if (content is String) {
          buffer.write(content);
        }
      }
      if (buffer.isNotEmpty) {
        return buffer.toString();
      }
    }

    // 2. Fallback schema: top-level `outputs` array.
    final outputs = json['outputs'];
    if (outputs is List) {
      for (final item in outputs) {
        if (item is! Map) continue;
        final itemType = item['type']?.toString();
        if (itemType == null || itemType == 'text') {
          final text = item['text']?.toString();
          if (text != null) {
            buffer.write(text);
          }
        }
      }
      if (buffer.isNotEmpty) {
        return buffer.toString();
      }
    }

    // 3. Fallback convenience property: `output_text`.
    final directText = json['output_text'];
    if (directText is String && directText.trim().isNotEmpty) {
      return directText;
    }

    return '';
  }
}
