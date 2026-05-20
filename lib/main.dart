import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:investanco/app/app.dart';
import 'package:investanco/app/di/injection_container.dart' as di;
import 'package:investanco/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:investanco/firebase_options.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await di.init();
  di.sl<AuthBloc>().add(const AuthStarted());
  await LocaleSettings.useDeviceLocale();
  runApp(TranslationProvider(child: const InvestancoApp()));
}
