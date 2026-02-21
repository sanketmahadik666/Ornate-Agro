import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routes/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state.status != AuthStatus.authenticated) {
            return const Center(child: Text('Not authenticated'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(
                title: 'Farmers',
                value: '—',
                onTap: () => Navigator.pushNamed(context, AppRouter.farmers),
                trailing: IconButton(
                  icon: const Icon(Icons.category, size: 20),
                  onPressed: () => Navigator.pushNamed(context, AppRouter.farmersByCategory),
                  tooltip: 'View by Category',
                ),
              ),
              _SummaryCard(title: 'Distributions', value: '—', onTap: () => Navigator.pushNamed(context, AppRouter.distribution)),
              _SummaryCard(title: 'Yield tracking', value: '—', onTap: () => Navigator.pushNamed(context, AppRouter.yieldTracking)),
              _SummaryCard(title: 'Contact log', value: '—', onTap: () => Navigator.pushNamed(context, AppRouter.contactLog)),
              _SummaryCard(title: 'Crop config', value: '—', onTap: () => Navigator.pushNamed(context, AppRouter.cropConfig)),
              _SummaryCard(title: 'Reports', value: '—', onTap: () => Navigator.pushNamed(context, AppRouter.reports)),
              _SummaryCard(title: 'Backtesting', value: '—', onTap: () => Navigator.pushNamed(context, AppRouter.backtesting)),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) trailing!,
            const SizedBox(width: 8),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
