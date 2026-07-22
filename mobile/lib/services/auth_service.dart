import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class AuthService {
  static Future<void> signUpWithEmail(String email, String password, String username) async {
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
    if (res.user == null) throw 'Signup failed. Try again.';
  }

  static Future<void> signInWithEmail(String email, String password) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) throw 'Invalid email or password.';
  }

  static Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
