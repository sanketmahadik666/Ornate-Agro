import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/backtesting/presentation/pages/backtest_page.dart';
import '../../features/contact_log/presentation/pages/contact_log_page.dart';
import '../../features/crop_config/presentation/pages/crop_config_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/distribution/presentation/pages/distribution_list_page.dart';
import '../../features/farmers/presentation/pages/farmers_list_page.dart';
import '../../features/farmers/presentation/pages/farmers_by_category_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/yield_tracking/presentation/pages/yield_tracking_page.dart';

abstract final class AppRouter {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String backtesting = '/backtesting';
  static const String farmers = '/farmers';
  static const String farmersByCategory = '/farmers/categories';
  static const String distribution = '/distribution';
  static const String yieldTracking = '/yield';
  static const String contactLog = '/contact-log';
  static const String cropConfig = '/crop-config';
  static const String reports = '/reports';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case backtesting:
        return MaterialPageRoute(builder: (_) => const BacktestPage());
      case farmers:
        return MaterialPageRoute(builder: (_) => const FarmersListPage());
      case farmersByCategory:
        return MaterialPageRoute(builder: (_) => const FarmersByCategoryPage());
      case distribution:
        return MaterialPageRoute(builder: (_) => const DistributionListPage());
      case yieldTracking:
        return MaterialPageRoute(builder: (_) => const YieldTrackingPage());
      case contactLog:
        return MaterialPageRoute(builder: (_) => const ContactLogPage());
      case cropConfig:
        return MaterialPageRoute(builder: (_) => const CropConfigPage());
      case reports:
        return MaterialPageRoute(builder: (_) => const ReportsPage());
      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}
