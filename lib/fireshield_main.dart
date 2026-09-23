/// Entry point for the FireShield PWA port.
///
///   flutter run -t lib/fireshield_main.dart -d chrome
///   flutter build web -t lib/fireshield_main.dart --release
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fireshield/fs_app.dart';
import 'fireshield/services/fs_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isSupabaseConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }
  runApp(const FireShieldApp());
}
