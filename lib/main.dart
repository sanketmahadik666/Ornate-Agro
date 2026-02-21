import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await bootstrap();
  runApp(OrnateAgroApp(database: database));
}
