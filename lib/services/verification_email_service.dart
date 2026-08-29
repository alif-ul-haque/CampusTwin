import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Sends the branded email-verification email via the CampusTwin Cloudflare
/// Worker (logo + "CampusTwin Team" sender + pretty HTML).
/// The worker mints the official verification link server-side (Identity
/// Toolkit REST) using the signed-in user's ID token.
/// Falls back to Firebase's built-in verification email when the worker is
/// not yet configured or unreachable.
class VerificationEmailService {
  static String get _workerBase =>
      dotenv.env['RESET_EMAIL_WORKER_URL']?.trim() ?? '';

  static Future<void> send() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Sign in is required to verify your email.',
      );
    }

    if (_workerBase.isEmpty) {
      debugPrint('[VerifyEmail] RESET_EMAIL_WORKER_URL missing in .env -> '
          'built-in fallback');
      await user.sendEmailVerification();
      return;
    }

    debugPrint('[VerifyEmail] worker: $_workerBase/send-verification');

    try {
      final idToken = await user.getIdToken();
      final res = await http
          .post(
            Uri.parse('$_workerBase/send-verification'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': user.email, 'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        debugPrint('[VerifyEmail] worker error ${res.statusCode}: ${res.body}');
        throw Exception('Email service error ${res.statusCode}: ${res.body}');
      }
      debugPrint('[VerifyEmail] worker success: branded verification sent');
    } catch (e) {
      debugPrint('[VerifyEmail] exception -> built-in fallback: $e');
      await user.sendEmailVerification();
    }
  }
}