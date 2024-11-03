import 'package:flutter/material.dart';

class WateringScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Öntözés Vezérlés")),
      body: Center(
        child: Text(
          "Itt lehet az öntözőrendszert vezérelni.",
          style: TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
