import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'my_tournaments_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0, _unread = 0;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadUnread();
    _channel = NotificationService.subscribe((n) {
      if (!mounted) return;
      setState(() => _unread += 1);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${n.title}  ${n.body}'), duration: const Duration(seconds: 3)));
    });
  }

  Future<void> _loadUnread() async {
    final count = await NotificationService.unreadCount();
    if (mounted) setState(() => _unread = count);
  }

  @override
  void dispose() { _channel?.unsubscribe(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(), const MyTournamentsScreen(), const LeaderboardScreen(),
      NotificationsScreen(onRead: () => setState(() => _unread = 0)), const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'My Matches'),
          const BottomNavigationBarItem(icon: Icon(Icons.leaderboard_rounded), label: 'Ranks'),
          BottomNavigationBarItem(
            icon: Badge(isLabelVisible: _unread > 0, label: Text('$_unread'), backgroundColor: NeonColors.pink, child: const Icon(Icons.notifications_rounded)),
            label: 'Alerts',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
