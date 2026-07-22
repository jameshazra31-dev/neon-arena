import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../main.dart';
import '../services/admin_service.dart';
import 'shell.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false, _obscure = true;

  Future<void> _login() async {
    setState(() => _busy = true);
    try {
      await supabase.auth.signInWithPassword(
          email: _email.text.trim(), password: _password.text);
      final ok = await AdminService.isAdmin();
      if (!ok) {
        await supabase.auth.signOut();
        throw 'This account is not an admin.';
      }
      if (mounted) Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminShell()), (_) => false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: NeonColors.red));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Icon(Icons.shield_moon_rounded, size: 64, color: NeonColors.pink),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (r) => NeonColors.neonGradient.createShader(r),
                child: const Text('NEONARENA ADMIN', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 4, color: Colors.white)),
              ),
              const SizedBox(height: 8),
              const Text('Admin access only', textAlign: TextAlign.center,
                  style: TextStyle(color: NeonColors.textMuted)),
              const SizedBox(height: 32),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Admin email', prefixIcon: Icon(Icons.mail_outline)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: NeonColors.pink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: _busy ? null : _login,
                child: _busy
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                    : const Text('SIGN IN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
