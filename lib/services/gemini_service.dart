import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  // TODO: Inject via .env or --dart-define. Never hardcode the key client-side.
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-2.5-flash';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static String get _key =>
      _apiKey.isNotEmpty ? _apiKey : dotenv.env['GEMINI_API_KEY'] ?? '';

  final List<Map<String, dynamic>> _history = [];

  void reset() => _history.clear();

  Future<String> sendMessage(String userText, {String? systemPrompt}) async {
    if (_key.isEmpty) {
      return 'Error: GEMINI_API_KEY not set. Add it to .env (full rebuild '
          'needed) or pass --dart-define=GEMINI_API_KEY=...';
    }

    _history.add({
      'role': 'user',
      'parts': [
        {'text': userText},
      ],
    });

    final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_key');

    final body = {
      if (systemPrompt != null)
        'system_instruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
      'contents': _history,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 512,
      },
    };

    try {
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      if (res.statusCode != 200) {
        throw Exception('Gemini error ${res.statusCode}: ${res.body}');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final parts = data['candidates']?[0]?['content']?['parts'] as List? ?? [];
      String? text;
      for (final part in parts) {
        if (part is Map && part['text'] is String) {
          text = part['text'] as String;
          break;
        }
      }
      final reply =
          text?.trim() ?? 'Error: empty response from Gemini';

      _history.add({
        'role': 'model',
        'parts': [
          {'text': reply},
        ],
      });
      return reply;
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// One-shot JSON generation — no conversation history, forces JSON output.
  Future<String?> generateJson(String prompt, {String? systemPrompt}) async {
    if (_key.isEmpty) return null;

    final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_key');
    final body = {
      if (systemPrompt != null)
        'system_instruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 1024,
        'responseMimeType': 'application/json',
      },
    };

    try {
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final parts = data['candidates']?[0]?['content']?['parts'] as List? ?? [];
      for (final part in parts) {
        if (part is Map && part['text'] is String) return part['text'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
