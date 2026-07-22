import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../main.dart';
import 'login_screen.dart';
import 'root_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), _route);
  }

  void _route() {
    if (!mounted) return;
    final loggedIn = supabase.auth.currentSession != null;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => loggedIn ? const RootShell() : const LoginScreen()));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
          child: ScaleTransition(
            scale: Tween(begin: .85, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: NeonColors.neonGradient, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: NeonColors.purple.withOpacity(.55), blurRadius: 60)],
                ),
                child: const Icon(Icons.sports_esports, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (r) => NeonColors.neonGradient.createShader(r),
                child: const Text('NEONARENA', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 6, color: Colors.white)),
              ),
              const SizedBox(height: 8),
              const Text('PLAY - COMPETE - WIN', style: TextStyle(color: NeonColors.textMuted, letterSpacing: 3)),
            ]),
          ),
        ),
      ),
    );
  }
}
