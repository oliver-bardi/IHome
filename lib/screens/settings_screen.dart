import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login'); // Navigate back to login screen
  }

  void _deleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Fiók törlése'),
          content: Text('Biztosan törölni szeretnéd a fiókodat? Ez a művelet nem vonható vissza.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dialog bezárása
              },
              child: Text('Mégsem'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dialog bezárása
                _performAccountDeletion(context); // Fiók törlése
              },
              child: Text(
                'Törlés',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performAccountDeletion(BuildContext context) {
    // Fiók törlés logikája itt lesz implementálva
    // Például egy API hívás a szerver felé
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('A fiók törlésre került.'),
      ),
    );

    // A felhasználó visszanavigálása a bejelentkező képernyőre
    Navigator.pushReplacementNamed(context, '/login');
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
          Divider(),
          ListTile(
            title: Text(
              'Fiók törlése',
              style: TextStyle(color: Colors.red),
            ),
            leading: Icon(Icons.delete_forever, color: Colors.red),
            onTap: () => _deleteAccount(context),
          ),
        ],
      ),
    );
  }
}
