import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/widgets.dart';
import 'root_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _otpSent = false, _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try { await action(); } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  void _goHome() => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const RootShell()), (_) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              ShaderMask(
                shaderCallback: (r) => NeonColors.neonGradient.createShader(r),
                child: const Text('NEONARENA', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 5, color: Colors.white)),
              ),
              const SizedBox(height: 6),
              const Text('Join tournaments. Win real prizes.', textAlign: TextAlign.center, style: TextStyle(color: NeonColors.textMuted)),
              const SizedBox(height: 40),
              GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(_otpSent ? 'Enter OTP' : 'Login with Phone', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  if (!_otpSent)
                    TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '+91 98765 43210', prefixIcon: Icon(Icons.phone_android)))
                  else
                    TextField(controller: _otp, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(hintText: '6-digit code', prefixIcon: Icon(Icons.lock_outline))),
                  const SizedBox(height: 14),
                  NeonButton(
                    label: _otpSent ? 'VERIFY & LOGIN' : 'SEND OTP',
                    loading: _busy,
                    onPressed: () => _run(() async {
                      if (!_otpSent) { await AuthService.sendOtp(_phone.text.trim()); setState(() => _otpSent = true); }
                      else { await AuthService.verifyOtp(_phone.text.trim(), _otp.text.trim()); _goHome(); }
                    }),
                  ),
                  if (_otpSent) TextButton(onPressed: () => setState(() => _otpSent = false), child: const Text('Change number')),
                ]),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), side: BorderSide(color: NeonColors.blue.withOpacity(.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                icon: const Icon(Icons.g_mobiledata, size: 32),
                label: const Text('Continue with Google', style: TextStyle(fontSize: 16)),
                onPressed: _busy ? null : () => _run(() async { await AuthService.signInWithGoogle(); _goHome(); }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
