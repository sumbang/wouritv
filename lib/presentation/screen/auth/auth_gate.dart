import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wouritv/data/api/supabase_auth_service.dart';
import 'package:wouritv/presentation/screen/auth/onboarding_screen.dart';
import 'package:wouritv/presentation/screen/home/dashboard_screen.dart';
import 'dart:developer' as developer;

/// Widget pour gérer l'état d'authentification
class AuthStateWidget extends StatefulWidget {
  final Widget Function(BuildContext context, User? user) builder;

  const AuthStateWidget({
    super.key,
    required this.builder,
  });

  @override
  State<AuthStateWidget> createState() => _AuthStateWidgetState();
}

class _AuthStateWidgetState extends State<AuthStateWidget> {
  final _authService = SupabaseAuthService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    
    developer.log(
      'AuthGate initialisé - Utilisateur actuel: ${_currentUser?.id ?? "null"} (${_currentUser?.email ?? "N/A"})',
      name: 'AuthGate',
    );

    // Écouter les changements d'authentification
    _authService.authStateChanges.listen((event) {
      developer.log(
        'AuthStateChange - Event: ${event.event}, User: ${event.session?.user?.id ?? "null"}, Email: ${event.session?.user?.email ?? "N/A"}',
        name: 'AuthGate',
      );
      
      if (mounted) {
        setState(() {
          _currentUser = event.session?.user;
        });
        
        developer.log(
          'AuthGate setState - Nouvel utilisateur: ${_currentUser?.id ?? "null"}',
          name: 'AuthGate',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    developer.log(
      'AuthGate build - User: ${_currentUser?.id ?? "null"} (${_currentUser?.email ?? "N/A"})',
      name: 'AuthGate',
    );
    
    return widget.builder(context, _currentUser);
  }
}

/// Provider pour l'authentification avec Riverpod

final authServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService();
});

final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((state) => state.session?.user);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user != null;
});


/// Exemple d'utilisation dans main.dart
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthStateWidget(
      builder: (context, user) {
        if (user == null) {
          // L'utilisateur n'est pas connecté, afficher la page de connexion
          return OnboardingScreen();
        } else {
          // L'utilisateur est connecté, afficher le dashboard
          return const DashboardScreen();
        }
      },
    );
  }
}
