import 'package:flutter/material.dart';
class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F1117),
      body: Center(child: Text('Rooms', style: TextStyle(color: Colors.white))),
    );
  }
}