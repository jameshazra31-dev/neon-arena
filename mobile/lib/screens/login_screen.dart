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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _busy = false, _obscure = true;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: NeonColors.red));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goHome() => Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootShell()), (_) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              ShaderMask(
                shaderCallback: (r) => NeonColors.neonGradient.createShader(r),
                child: const Text('NEONARENA', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 5, color: Colors.white)),
              ),
              const SizedBox(height: 6),
              const Text('Play. Compete. Win.', textAlign: TextAlign.center,
                  style: TextStyle(color: NeonColors.textMuted)),
              const SizedBox(height: 32),
              TabBar(
                controller: _tabs,
                indicatorColor: NeonColors.blue,
                labelColor: NeonColors.blue,
                unselectedLabelColor: NeonColors.textMuted,
                tabs: const [Tab(text: 'LOGIN'), Tab(text: 'SIGN UP')],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 320,
                child: TabBarView(controller: _tabs, children: [
                  // LOGIN TAB
                  GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('Welcome back!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'Email address', prefixIcon: Icon(Icons.mail_outline)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _run(() => AuthService.resetPassword(_email.text.trim())
                            .then((_) => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reset link sent to your email!'))))),
                        child: const Text('Forgot password?', style: TextStyle(color: NeonColors.textMuted, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    NeonButton(
                      label: 'LOGIN',
                      loading: _busy,
                      onPressed: () => _run(() async {
                        await AuthService.signInWithEmail(_email.text.trim(), _password.text);
                        _goHome();
                      }),
                    ),
                  ])),
                  // SIGNUP TAB
                  GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('Create account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _username,
                      decoration: const InputDecoration(hintText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'Email address', prefixIcon: Icon(Icons.mail_outline)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'Password (min 6 chars)',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    NeonButton(
                      label: 'CREATE ACCOUNT',
                      loading: _busy,
                      onPressed: () => _run(() async {
                        if (_username.text.trim().isEmpty) throw 'Username required!';
                        if (_password.text.length < 6) throw 'Password too short (min 6)!';
                        await AuthService.signUpWithEmail(
                          _email.text.trim(), _password.text, _username.text.trim());
                        _goHome();
                      }),
                    ),
                  ])),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
