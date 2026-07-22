import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';
import 'services/admin_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(url: dotenv.env['SUPABASE_URL']!, anonKey: dotenv.env['SUPABASE_ANON_KEY']!);
  runApp(const NeonArenaAdminApp());
}

final supabase = Supabase.instance.client;

class NeonArenaAdminApp extends StatelessWidget {
  const NeonArenaAdminApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'NeonArena Admin', debugShowCheckedModeBanner: false, theme: NeonTheme.dark, home: const _Gate());
  }
}

class _Gate extends StatelessWidget {
  const _Gate();
  @override
  Widget build(BuildContext context) {
    if (supabase.auth.currentSession == null) return const AdminLoginScreen();
    return FutureBuilder<bool>(
      future: AdminService.isAdmin(),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return snap.data! ? const AdminShell() : const AdminLoginScreen();
      },
    );
  }
}
