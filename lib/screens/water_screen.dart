import 'package:flutter/material.dart';

class WaterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Víz'),
      ),
      body: Center(
        child: Text(
          'Ez a Víz oldal tartalma.',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
