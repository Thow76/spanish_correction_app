import 'package:flutter/material.dart';

import 'app/app_config.dart';
import 'app/spanish_correction_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppConfig.load();
  runApp(SpanishCorrectionApp(config: config));
}
