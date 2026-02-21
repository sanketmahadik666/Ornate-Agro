import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ornate_agro/core/theme/app_theme.dart';
import 'package:ornate_agro/core/routes/app_router.dart';
import 'package:ornate_agro/core/data/database/app_database_impl.dart';
import 'package:ornate_agro/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ornate_agro/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:ornate_agro/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ornate_agro/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ornate_agro/features/auth/presentation/widgets/session_manager.dart';
import 'package:ornate_agro/features/farmers/presentation/bloc/farmer_bloc.dart';
import 'package:ornate_agro/features/farmers/data/datasources/farmer_local_datasource.dart';
import 'package:ornate_agro/features/farmers/data/repositories/farmer_repository_impl.dart';
import 'package:ornate_agro/features/distribution/presentation/bloc/distribution_bloc.dart';
import 'package:ornate_agro/features/distribution/data/datasources/distribution_local_datasource.dart';
import 'package:ornate_agro/features/distribution/data/repositories/distribution_repository_impl.dart';

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
    final authRepository =
        AuthRepositoryImpl(authLocalDataSource, authRemoteDataSource);
    final authBloc = AuthBloc(authRepository);

    // Farmer dependencies
    final farmerLocalDataSource = FarmerLocalDataSource(database);
    final farmerRepository = FarmerRepositoryImpl(farmerLocalDataSource);
    final farmerBloc = FarmerBloc(farmerRepository);

    // Distribution dependencies (Req 3)
    final distributionLocalDataSource = DistributionLocalDataSource(database);
    final distributionRepository =
        DistributionRepositoryImpl(distributionLocalDataSource);
    final distributionBloc = DistributionBloc(distributionRepository);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<FarmerBloc>.value(value: farmerBloc),
        BlocProvider<DistributionBloc>.value(value: distributionBloc),
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
