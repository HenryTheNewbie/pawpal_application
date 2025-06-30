import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../firebase_options.dart';
import '../../theme/theme.dart';
import '../../routes/routes.dart';

class SanctuaryEmailVerificationScreen extends StatelessWidget {
  const SanctuaryEmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            const Text(
              'Check your inbox',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'The password reset link has been sent to your email address. Please check your inbox and follow the instructions to reset your password.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.sanctuaryLogin,
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                child: const Text('Return to Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}