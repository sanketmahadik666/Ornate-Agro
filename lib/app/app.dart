import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/data/database/app_database_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/widgets/session_manager.dart';
import 'features/farmers/presentation/bloc/farmer_bloc.dart';
import 'features/farmers/data/datasources/farmer_local_datasource.dart';
import 'features/farmers/data/repositories/farmer_repository_impl.dart';

class OrnateAgroApp extends StatelessWidget {
  const OrnateAgroApp({required this.database, super.key});

  final AppDatabaseImpl database;

  @override
  Widget build(BuildContext context) {
    // Initialize dependencies
    const secureStorage = FlutterSecureStorage();
    
    // Auth dependencies
    final authLocalDataSource = AuthLocalDataSource(secureStorage);
    final authRemoteDataSource = AuthRemoteDataSource();
    final authRepository = AuthRepositoryImpl(authLocalDataSource, authRemoteDataSource);
    final authBloc = AuthBloc(authRepository);

    // Farmer dependencies
    final farmerLocalDataSource = FarmerLocalDataSource(database);
    final farmerRepository = FarmerRepositoryImpl(farmerLocalDataSource);
    final farmerBloc = FarmerBloc(farmerRepository);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<FarmerBloc>.value(value: farmerBloc),
      ],
      child: SessionManagerWidget(
        child: MaterialApp(
          title: 'Ornate Agro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: AppRouter.login,
        ),
      ),
    );
  }
}
