import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/admin_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase — real project credentials (see lib/config/supabase_config.dart)
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const StreetloreAdminApp());
}

class StreetloreAdminApp extends StatelessWidget {
  const StreetloreAdminApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Streetlore Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AdminService.instance.isLoggedIn
          ? const DashboardScreen()
          : const LoginScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
    );
  }
}
