import 'package:flutter/material.dart';

/// Req 3: Distribution log with filters (date, seed type, farmer, status).
class DistributionListPage extends StatelessWidget {
  const DistributionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Distribution Log')),
      body: const Center(child: Text('Distribution log – Req 3')),
    );
  }
}
