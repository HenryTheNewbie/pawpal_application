import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../firebase_options.dart';
import '../../theme/theme.dart';
import '../../routes/routes.dart';
import 'sanctuary_add_animal_screen.dart';
import 'sanctuary_chat_screen.dart';
import 'sanctuary_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

class SanctuaryMainScreen extends StatefulWidget {
  const SanctuaryMainScreen({super.key});

  @override
  State<SanctuaryMainScreen> createState() => _SanctuaryMainScreenState();
}

class _SanctuaryMainScreenState extends State<SanctuaryMainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    SanctuaryAddAnimalScreen(),
    SanctuaryChatScreen(),
    SanctuaryProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              offset: const Offset(0, -3),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: SizedBox(
          height: 60,
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.paw),
                label: 'Discover',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chat_bubble_2),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person_crop_circle),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}