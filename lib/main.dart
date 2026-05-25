import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'data/mock_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MockData.load();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const IsmvccApp());
}
