import 'package:flutter/material.dart';
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F1117),
      body: Center(child: Text('Groups', style: TextStyle(color: Colors.white))),
    );
  }
}