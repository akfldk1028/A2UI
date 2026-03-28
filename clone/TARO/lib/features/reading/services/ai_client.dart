import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:http/http.dart' as http;

import '../../../core/config/ai_config.dart';
import '../../../core/services/api_key_service.dart';

abstract interface class AiClient {
  Stream<String> sendStream(
    String prompt, {
    required List<dartantic.ChatMessage> history,
  });
  void dispose();
}

/// Calls Supabase Edge Function `ai-tarot` via SSE streaming.
class EdgeFunctionAiClient implements AiClient {
  EdgeFunctionAiClient({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;
  bool _isCancelled = false;

  /// Cancels an in-progress stream request.
  void cancel() {
    _isCancelled = true;
  }

  @override
  Stream<String> sendStream(
    String prompt, {
    required List<dartantic.ChatMessage> history,
  }) async* {
    final messages = <Map<String, String>>[];

    // Convert dartantic history to simple {role, content} messages
    for (final msg in history) {
      final role = switch (msg) {
        dartantic.SystemMessage() => 'system',
        dartantic.UserMessage() => 'user',
        dartantic.ModelMessage() => 'assistant',
        _ => 'user',
      };
      messages.add({'role': role, 'content': msg.content});
    }
    messages.add({'role': 'user', 'content': prompt});

    final url = Uri.parse(
      '${AiConfig.supabaseUrl}/functions/v1/ai-tarot',
    );

    final request = http.Request('POST', url)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'apikey': AiConfig.supabaseAnonKey,
      })
      ..body = jsonEncode({
        'messages': messages,
        'model': AiConfig.defaultModel,
        'temperature': 0.9,
      });

    _isCancelled = false;

    final response = await _client.send(request).timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Edge Function error ${response.statusCode}: $body');
    }

    // Parse SSE stream: lines starting with "data: "
    final buffer = StringBuffer();

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      if (_isCancelled) return;
      buffer.write(chunk);
      final raw = buffer.toString();
      final lines = raw.split('\n');
      // Keep last potentially incomplete line in buffer
      buffer.clear();
      buffer.write(lines.removeLast());

      for (final line in lines) {
        if (!line.startsWith('data: ')) continue;
        final jsonStr = line.substring(6).trim();
        if (jsonStr.isEmpty) continue;

        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final text = data['text'] as String? ?? '';
          final done = data['done'] as bool? ?? false;
          if (text.isNotEmpty) yield text;
          if (done) return;
        } catch (e) {
          log('Malformed SSE line: $jsonStr', name: 'EdgeFunctionAiClient', error: e);
        }
      }
    }
  }

  @override
  void dispose() {
    _client.close();
  }
}

/// Direct Gemini API client (legacy, for local development/fallback).
class GeminiAiClient implements AiClient {
  GeminiAiClient({String? modelName}) {
    final apiKey = getApiKey();
    _provider = dartantic.GoogleProvider(apiKey: apiKey);
    _agent = dartantic.Agent.forProvider(
      _provider,
      chatModelName: modelName ?? AiConfig.defaultModel,
    );
  }

  late final dartantic.GoogleProvider _provider;
  late final dartantic.Agent _agent;

  @override
  Stream<String> sendStream(
    String prompt, {
    required List<dartantic.ChatMessage> history,
  }) async* {
    final stream = _agent.sendStream(prompt, history: history);
    await for (final result in stream) {
      if (result.output.isNotEmpty) yield result.output;
    }
  }

  @override
  void dispose() {}
}
