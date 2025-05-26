import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase_options.dart';
import '../theme/theme.dart';
import '../routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class UserFaqScreen extends StatefulWidget {
  const UserFaqScreen({Key? key}) : super(key: key);

  @override
  _UserFaqScreenState createState() => _UserFaqScreenState();
}

class _UserFaqScreenState extends State<UserFaqScreen> {
  List<Map<String, String>> _faqList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFaqFromFirebase();
  }

  Future<void> _loadFaqFromFirebase() async {
    try {
      final ref = FirebaseStorage.instance.ref().child('faq.json');
      final url = await ref.getDownloadURL();
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _faqList = data
              .map<Map<String, String>>((item) => {
            'question': item['question'],
            'answer': item['answer'],
          })
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load FAQ');
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading FAQ: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            },
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
                  'FAQ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontFamily: 'Quicksand',
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _faqList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final faq = _faqList[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            faq['question'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Quicksand',
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            faq['answer'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Quicksand',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}