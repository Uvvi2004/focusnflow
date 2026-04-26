import 'package:flutter/material.dart';
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F1117),
      body: Center(child: Text('Tasks', style: TextStyle(color: Colors.white))),
    );
  }
}