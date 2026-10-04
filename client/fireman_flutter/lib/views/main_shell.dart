import 'package:flutter/material.dart';
import 'gameplay_screen.dart';
import 'character_screen.dart';
import 'missions_screen.dart';
import 'lobby_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    GameplayScreen(),
    CharacterScreen(),
    MissionsScreen(),
    LobbyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department),
            label: 'Oyun',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Karakter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Görevler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Lobi',
          ),
        ],
      ),
    );
  }
}
