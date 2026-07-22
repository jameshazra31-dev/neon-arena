import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'payments_screen.dart';
import 'players_screen.dart';
import 'rooms_screen.dart';
import 'tournaments_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    const pages = [DashboardScreen(), TournamentsScreen(), PaymentsScreen(), RoomsScreen(), PlayersScreen()];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_rounded), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room_rounded), label: 'Rooms'),
          BottomNavigationBarItem(icon: Icon(Icons.group_rounded), label: 'Players'),
        ],
      ),
    );
  }
}
