import 'package:flutter/material.dart';
import 'anggaran.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finance Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BudgetPage(),
    );
  }
}
