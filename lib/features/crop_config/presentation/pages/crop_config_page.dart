import 'package:flutter/material.dart';

/// Req 8: Crop types and growing period configuration.
class CropConfigPage extends StatelessWidget {
  const CropConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Configuration')),
      body: const Center(child: Text('Crop config – Req 8')),
    );
  }
}
