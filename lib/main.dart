import 'package:flutter/widgets.dart';
import 'package:investanco/app/app.dart';
import 'package:investanco/app/di/injection_container.dart' as di;
import 'package:investanco/gen/strings.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  await LocaleSettings.useDeviceLocale();
  runApp(TranslationProvider(child: const InvestancoApp()));
}
