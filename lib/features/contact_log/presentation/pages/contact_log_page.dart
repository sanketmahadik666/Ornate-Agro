import 'package:flutter/material.dart';

/// Req 6: Contact log (date, method, note, staff identity).
class ContactLogPage extends StatelessWidget {
  const ContactLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Log')),
      body: const Center(child: Text('Contact log – Req 6')),
    );
  }
}
