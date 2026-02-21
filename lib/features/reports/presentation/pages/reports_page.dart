import 'package:flutter/material.dart';

/// Req 7: Reports (filters, PDF/CSV export, Blacklist/Reminder reports).
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: const Center(child: Text('Reports – Req 7')),
    );
  }
}
