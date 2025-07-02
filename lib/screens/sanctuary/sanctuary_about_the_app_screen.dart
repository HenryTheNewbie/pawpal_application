import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../firebase_options.dart';
import '../../theme/theme.dart';
import '../../routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class SanctuaryAboutTheAppScreen extends StatefulWidget {
  const SanctuaryAboutTheAppScreen({Key? key}) : super(key: key);

  @override
  State<SanctuaryAboutTheAppScreen> createState() => _SanctuaryAboutTheAppScreenState();
}

class _SanctuaryAboutTheAppScreenState extends State<SanctuaryAboutTheAppScreen> {
  String? _lastUpdated;
  List<Map<String, String>> _sections = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAboutAppFromFirebase();
  }

  Future<void> _loadAboutAppFromFirebase() async {
    try {
      final ref = FirebaseStorage.instance.ref().child('about_the_app.json');
      final url = await ref.getDownloadURL();
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final lastUpdated = data['last_updated'] as String?;
        final sectionsData = data['sections'] as List<dynamic>;

        final parsedSections = sectionsData
            .map<Map<String, String>>((item) => {
          'section': item['section'],
          'content': item['content'],
        })
            .toList();

        setState(() {
          _lastUpdated = lastUpdated;
          _sections = parsedSections;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load About the App');
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading About the App: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),

                const Text(
                  'About the App',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: Image.asset(
                    'assets/images/pawpal_logo_full.png',
                    height: size.height * 0.25,
                  ),
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  )
                else ...[
                    Text(
                      _lastUpdated ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Quicksand',
                      ),
                    ),
                    const SizedBox(height: 24),

                    for (var section in _sections) ...[
                      Text(
                        section['section'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Quicksand',
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        section['content'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Quicksand',
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}