import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login'); // Navigate back to login screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Logout'),
            leading: Icon(Icons.logout),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
