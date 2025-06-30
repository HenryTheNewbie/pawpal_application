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

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<UserNotificationsScreen> createState() => _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  bool _chatNotifications = true;
  bool _adoptionNotifications = true;
  bool _appUpdateNotifications = true;

  static const String _prefChatKey = 'notifications_chat';
  static const String _prefAdoptionKey = 'notifications_adoption';
  static const String _prefAppUpdateKey = 'notifications_app_update';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _chatNotifications = prefs.getBool(_prefChatKey) ?? true;
      _adoptionNotifications = prefs.getBool(_prefAdoptionKey) ?? true;
      _appUpdateNotifications = prefs.getBool(_prefAppUpdateKey) ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
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
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 24),

                _buildNotificationToggle(
                  title: 'Chat Notifications',
                  subtitle: 'Get notified about new chat messages.',
                  value: _chatNotifications,
                  onChanged: (v) {
                    setState(() => _chatNotifications = v);
                    _savePreference(_prefChatKey, v);
                  },
                ),
                const SizedBox(height: 16),

                _buildNotificationToggle(
                  title: 'Adoption Process Notifications',
                  subtitle: 'Updates about your adoption requests.',
                  value: _adoptionNotifications,
                  onChanged: (v) {
                    setState(() => _adoptionNotifications = v);
                    _savePreference(_prefAdoptionKey, v);
                  },
                ),
                const SizedBox(height: 16),

                _buildNotificationToggle(
                  title: 'App Updates',
                  subtitle: 'News about app features and updates.',
                  value: _appUpdateNotifications,
                  onChanged: (v) {
                    setState(() => _appUpdateNotifications = v);
                    _savePreference(_prefAppUpdateKey, v);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}