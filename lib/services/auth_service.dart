import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status == LoginStatus.success && result.accessToken != null) {
      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );
      return await _auth.signInWithCredential(credential);
    }

    throw FirebaseAuthException(
      code: result.status.name,
      message: result.message ?? 'Facebook login was cancelled or failed.',
    );
  }

  Future<void> logOut() async {
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
  }

  /// Prepares for future phone linking by exposing Firebase's link API.
  Future<UserCredential> linkPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user available to link credentials.',
      );
    }
    return user.linkWithCredential(credential);
  }
}
