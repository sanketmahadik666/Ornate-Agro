import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ornate_agro/core/theme/app_theme.dart';
import 'package:ornate_agro/core/routes/app_router.dart';
import 'package:ornate_agro/features/auth/presentation/bloc/auth_bloc.dart';

class OrnateAgroApp extends StatelessWidget {
  const OrnateAgroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()),
      ],
      child: MaterialApp(
        title: 'Ornate Agro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.login,
      ),
    );
  }
}
