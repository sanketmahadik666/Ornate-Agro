import 'package:flutter/material.dart';
import '../../../../core/routes/app_router.dart';

/// Req 2: Searchable/filterable list of farmers.
class FarmersListPage extends StatelessWidget {
  const FarmersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.pushNamed(context, AppRouter.farmersByCategory),
            tooltip: 'View by Category',
          ),
        ],
      ),
      body: const Center(child: Text('Farmer list – Req 2')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '${AppRouter.farmers}/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
