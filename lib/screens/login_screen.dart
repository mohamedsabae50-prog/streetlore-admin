import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Email and password are required');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AdminService.instance.signIn(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      setState(() => _error = 'Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final launched = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin + Uri.base.path : null,
      );
      if (!launched) {
        throw StateError('Google sign-in did not open the OAuth page.');
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Google sign-in failed: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 64,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'EgyptLore Admin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in with your Supabase admin account',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 22),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.danger),
                    ),
                  ),
                ElevatedButton(
                  key: const ValueKey('admin-sign-in-button'),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sign In'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const ValueKey('admin-google-sign-in-button'),
                  onPressed: _loading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata_rounded),
                  label: const Text('Sign in with Google'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
