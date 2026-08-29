import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Sends the branded password-reset email via the CampusTwin Cloudflare
/// Worker (logo + "CampusTwin Team" sender + pretty HTML).
/// The worker mints the official reset link server-side (Identity Toolkit
/// REST) so no secret ever lives in the app.
/// Falls back to Firebase's built-in reset email when the worker is not yet
/// configured or unreachable.
class PasswordResetEmailService {
  /// Base URL of the deployed worker, e.g.
  /// `https://campustwin-mailer.tazbiswas734.workers.dev`.
  static String get _workerBase =>
      dotenv.env['RESET_EMAIL_WORKER_URL']?.trim() ?? '';

  static String get _workerEndpoint => '$_workerBase/send-password-reset';

  static Future<void> send(String email) async {
    if (_workerBase.isEmpty) {
      debugPrint('[ResetEmail] RESET_EMAIL_WORKER_URL missing in .env -> '
          'Firebase fallback');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return;
    }

    debugPrint('[ResetEmail] worker: $_workerEndpoint');

    try {
      final res = await http
          .post(
            Uri.parse(_workerEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        debugPrint('[ResetEmail] worker error ${res.statusCode}: ${res.body}');
        throw Exception('Email service error ${res.statusCode}: ${res.body}');
      }
      debugPrint('[ResetEmail] worker success: branded email sent');
    } catch (e) {
      debugPrint('[ResetEmail] exception -> Firebase fallback: $e');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    }
  }
}