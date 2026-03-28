import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

import 'app.dart';
import 'core/services/cache_service.dart';
import 'i18n/multi_file_asset_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await CacheService.instance.init();
  await EasyLocalization.ensureInitialized();

  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    debugPrint('[${record.level.name}] ${record.time}: ${record.message}');
  });

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('ja'),
        Locale('zh'),
        Locale('vi'),
        Locale('th'),
        Locale('id'),
        Locale('ms'),
        Locale('my'),
        Locale('fr'),
        Locale('de'),
        Locale('es'),
        Locale('pt'),
        Locale('it'),
        Locale('hi'),
        Locale('ar'),
        Locale('ru'),
      ],
      fallbackLocale: const Locale('en'),
      path: 'lib/i18n',
      assetLoader: MultiFileAssetLoader(),
      child: const ProviderScope(child: TaroApp()),
    ),
  );
}
