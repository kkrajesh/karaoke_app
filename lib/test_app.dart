import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: Text(
            "RED SCREEN TEST",
            style: TextStyle(fontSize: 48, color: Colors.white),
          ),
        ),
      ),
    ),
  );
}
