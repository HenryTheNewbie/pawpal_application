import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../firebase_options.dart';
import '../../theme/theme.dart';
import '../../routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

class SanctuaryAddAnimalScreen extends StatelessWidget {
  const SanctuaryAddAnimalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/pawpal_logo_full.png',
              height: size.height * 0.25,
            ),
            const SizedBox(height: 32),
            const Text(
              'Work in Progress!',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}