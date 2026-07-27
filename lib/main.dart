import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'app.dart';
import 'data/database/kogutopedia_db.dart';
import 'firebase_options.dart';
import 'presentation/providers/entry_provider.dart';
import 'core/utils/slogan_loader.dart';
import 'core/utils/updater.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint('Flutter error: ${details.exception}\n${details.stack}');
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF020814),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  final database = await KogutopediaDatabase.getInstance();
  await SloganLoader.load();

  UpdateInfo? update;
  try {
    update = await AppUpdater.checkForUpdate();
  } catch (e) {
    debugPrint('Update check error: $e');
  }

  runZonedGuarded(
    () {
      runApp(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
          ],
          child: KogutopediaApp(pendingUpdate: update),
        ),
      );
    },
    (error, stack) {
      debugPrint('Unhandled error: $error\n$stack');
    },
  );
}
