import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'data/database/kogutopedia_db.dart';
import 'firebase_options.dart';
import 'presentation/providers/entry_provider.dart';
import 'core/utils/slogan_loader.dart';
import 'core/utils/updater.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  final database = await KogutopediaDatabase.getInstance();
  await SloganLoader.load();

  UpdateInfo? update;
  try {
    update = await AppUpdater.checkForUpdate();
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: KogutopediaApp(pendingUpdate: update),
    ),
  );
}
