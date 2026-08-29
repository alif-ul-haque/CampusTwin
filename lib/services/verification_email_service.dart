import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerificationEmailService {
  static Future<void> send() async {
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    try {
      await functions.httpsCallable('sendVerificationEmail').call();
    } on FirebaseFunctionsException {
      // Fallback to Firebase's built-in email if the custom sender fails.
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      rethrow;
    }
  }
}
