import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'data/api_client.dart';
import 'data/backend_sync.dart';
import 'data/ball_outbox.dart';
import 'data/mock_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MockData.load();
  await ApiClient.instance.loadSession();
  // Best-effort initial sync; failures are logged and won't block startup.
  unawaited(BackendSync.instance.refreshAll());
  // Drain any balls queued while offline.
  unawaited(BallOutbox.instance.drain());
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const IsmvccApp());
}
