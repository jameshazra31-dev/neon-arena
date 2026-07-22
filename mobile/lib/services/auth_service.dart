import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class AuthService {
  static User? get currentUser => supabase.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static Future<void> sendOtp(String phone) async {
    await supabase.auth.signInWithOtp(phone: phone);
  }

  static Future<AuthResponse> verifyOtp(String phone, String token) {
    return supabase.auth.verifyOTP(type: OtpType.sms, phone: phone, token: token);
  }

  static Future<AuthResponse> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      clientId: dotenv.env['GOOGLE_IOS_CLIENT_ID'],
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw const AuthException('Sign-in cancelled');
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) throw const AuthException('No Google ID token');
    return supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  static Future<void> signOut() => supabase.auth.signOut();
}
