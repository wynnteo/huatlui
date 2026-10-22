import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_scope.dart';
import 'l10n/app_localizations.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await settings.load();
  await repo.init();
  runApp(const HuatLuiApp());
}

class HuatLuiApp extends StatelessWidget {
  const HuatLuiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The only place that has to listen to settings: changing theme or
    // language rebuilds MaterialApp, and every screen below follows because
    // they read colours/strings through the context.
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'HuatLui',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          locale: settings.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('zh')],
          home: const MainShell(),
        );
      },
    );
  }
}
