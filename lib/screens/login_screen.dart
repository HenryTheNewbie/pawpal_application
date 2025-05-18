import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_options.dart';
import '../theme/theme.dart';
import '../routes/routes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset(
                  'assets/images/pawpal_logo_full.png',
                  height: size.height * 0.25,
                ),
                const SizedBox(height: 50),

                // Email Field
                TextField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Navigate to Forgot Password
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 16,
                        fontFamily: 'Quicksand', // Custom font
                        fontWeight: FontWeight.w500, // Medium weight
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50), // More rounded corners
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      // Handle login
                    },
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 16),

                // Register prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                        "Don't have an account?",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.register);
                      },
                      child: const Text(
                          'Register here.',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}