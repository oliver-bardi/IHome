import 'package:flutter/material.dart';

class LightScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Villanykörte'),
      ),
      body: Center(
        child: Text(
          'Ez a Villanykörte oldal tartalma.',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
