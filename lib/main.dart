import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/admin_service.dart';
import 'theme.dart';

bool adminDashboardAccessAllowed({
  required bool isLoggedIn,
  required bool isAdmin,
}) => isLoggedIn && isAdmin;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppTheme.loadSavedMode();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SharedPreferencesLocalStorage(
        persistSessionKey: 'streetlore-admin-auth-token',
      ),
    ),
  );

  runApp(const StreetloreAdminApp());
}

class StreetloreAdminApp extends StatelessWidget {
  const StreetloreAdminApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'EgyptLore Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        // Keep the admin interface English while avoiding unsupported
        // browser locale failures in Flutter's localization delegates.
        locale: const Locale('en'),
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
          Locale('en', 'US'),
          Locale('ar', 'EG'),
        ],
        home: const SelectionArea(child: _AdminAuthGate()),
        routes: {
          '/login': (_) => const SelectionArea(child: LoginScreen()),
          '/dashboard': (_) => const SelectionArea(child: _AdminAuthGate()),
        },
      ),
    );
  }
}

class _AdminAuthGate extends StatefulWidget {
  const _AdminAuthGate();

  @override
  State<_AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<_AdminAuthGate> {
  late final Future<bool> _adminAccess;

  @override
  void initState() {
    super.initState();
    _adminAccess = _checkAdminAccess();
  }

  Future<bool> _checkAdminAccess() async {
    final adminService = AdminService.instance;
    if (!adminService.isLoggedIn) return false;

    try {
      final isAdmin = await adminService.verifyCurrentUserIsAdmin();
      if (!isAdmin && adminService.isLoggedIn) {
        await adminService.signOut();
      }
      return adminDashboardAccessAllowed(
        isLoggedIn: adminService.isLoggedIn,
        isAdmin: isAdmin,
      );
    } catch (error, stackTrace) {
      debugPrint('AdminAuthGate: administrator verification failed: $error');
      debugPrint('$stackTrace');
      if (adminService.isLoggedIn) {
        try {
          await adminService.signOut();
        } catch (signOutError, signOutStackTrace) {
          debugPrint('AdminAuthGate: sign-out failed: $signOutError');
          debugPrint('$signOutStackTrace');
        }
      }
      return adminDashboardAccessAllowed(
        isLoggedIn: adminService.isLoggedIn,
        isAdmin: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminAccess,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == true
            ? const DashboardScreen()
            : const LoginScreen();
      },
    );
  }
}
