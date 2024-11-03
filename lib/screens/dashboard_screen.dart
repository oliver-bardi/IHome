import 'package:flutter/material.dart';
import 'heating_screen.dart';
import 'lighting_screen.dart';
import 'watering_screen.dart';
import 'security_screen.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          _buildDashboardButton(
            context,
            "Fűtés",
            Icons.thermostat,
            HeatingScreen(),
          ),
          _buildDashboardButton(
            context,
            "Világítás",
            Icons.lightbulb,
            LightingScreen(),
          ),
          _buildDashboardButton(
            context,
            "Öntözés",
            Icons.water,
            WateringScreen(),
          ),
          _buildDashboardButton(
            context,
            "Biztonság",
            Icons.security,
            SecurityScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardButton(
      BuildContext context, String title, IconData icon, Widget screen) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50, color: Colors.blue),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
