import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wouritv/config/app_theme.dart';
import 'package:wouritv/config/setting.dart';
import 'package:wouritv/data/api/supabase_auth_service.dart';
import 'package:wouritv/l10n/app_localizations.dart';
import 'package:wouritv/presentation/component/view_models/password_view_model.dart';
import 'package:wouritv/presentation/component/widget/input.dart';
import 'package:wouritv/presentation/component/widget/password.dart';
import 'package:wouritv/presentation/component/widget/bouton_full.dart';
import 'dart:developer' as developer;

/// Exemple de page de connexion avec Supabase
class LoginScreen extends StatefulHookConsumerWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _authService = SupabaseAuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSignUp = false;
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    
    // Écouter les changements d'authentification pour auto-fermer l'écran
    _authStream = _authService.authStateChanges;
    _authStream.listen((authState) {
      developer.log(
        'LoginScreen - AuthStateChange: ${authState.event}, User: ${authState.session?.user?.id ?? "null"}',
        name: 'LoginScreen',
      );
      
      // Si l'utilisateur vient de se connecter, fermer l'écran de login
      if (authState.event == AuthChangeEvent.signedIn && 
          authState.session != null && 
          mounted) {
        developer.log(
          'LoginScreen - Connexion détectée, fermeture automatique',
          name: 'LoginScreen',
        );
        
        // Pop pour revenir à AuthGate qui affichera automatiquement le Dashboard
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        // Inscription avec les métadonnées utilisateur
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {
            'full_name': _fullNameController.text.trim(),
          },
          emailRedirectTo: null, // Désactive la redirection pour mobile
        );

        developer.log(
          'Réponse inscription: user=${response.user?.id}, session=${response.session != null}',
          name: 'LoginScreen',
        );

        if (mounted) {
          if (response.user != null && response.session == null) {
            // Confirmation par email requise
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.signup_success),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
            // Retourner à l'écran de connexion
            setState(() => _isSignUp = false);
          } else if (response.session != null) {
            // Inscription réussie avec session active (si confirmation email désactivée)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.signup_success),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pushReplacementNamed('/');
          }
        }
      } else {
        final response = await _authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted && response.user != null) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Erreur lors de ${_isSignUp ? 'l\'inscription' : 'la connexion'}',
        error: e,
        stackTrace: stackTrace,
        name: 'LoginScreen',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error_general(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final success = await _authService.signInWithGoogle();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.google_signin_progress),
            backgroundColor: Colors.blue,
          ),
        );
        
        // Vérifier périodiquement si l'utilisateur est connecté (max 10s)
        for (int i = 0; i < 20; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          final user = _authService.currentUser;
          if (user != null && mounted) {
            developer.log(
              'Session Google détectée, redirection vers home',
              name: 'LoginScreen',
            );
            Navigator.of(context).pushReplacementNamed('/home');
            return;
          }
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Erreur lors de la connexion Google',
        error: e,
        stackTrace: stackTrace,
        name: 'LoginScreen',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error_google(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);

    try {
      developer.log(
        'Démarrage connexion Apple',
        name: 'LoginScreen',
      );
      final success = await _authService.signInWithApple();
      
      developer.log(
        'Retour signInWithApple: success=$success',
        name: 'LoginScreen',
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.apple_signin_progress),
            backgroundColor: Colors.blue,
          ),
        );
        
        // Attendre le callback OAuth et vérifier la session
        developer.log(
          'OAuth Apple initié - en attente du callback',
          name: 'LoginScreen',
        );
        
        // Vérifier périodiquement si l'utilisateur est connecté (max 10s)
        for (int i = 0; i < 20; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          final user = _authService.currentUser;
          if (user != null && mounted) {
            developer.log(
              'Session Apple détectée, redirection vers home',
              name: 'LoginScreen',
            );
            Navigator.of(context).pushReplacementNamed('/home');
            return;
          }
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Erreur lors de la connexion Apple',
        error: e,
        stackTrace: stackTrace,
        name: 'LoginScreen',
      );
      if (mounted) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error_apple(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.enter_email_first),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(email: _emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.reset_password_success),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Erreur lors de la réinitialisation du mot de passe',
        error: e,
        stackTrace: stackTrace,
        name: 'LoginScreen',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error_general(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? l10n.inscription_title : l10n.connexion_title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Center(
                          child: Image.asset(
                            'assets/img/wouri2.png',
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Champ Full Name (uniquement en mode inscription)
                        if (_isSignUp) ...[
                          Input(
                            label: l10n.fullname_label,
                            controller: _fullNameController,
                            icon: const Icon(Icons.person),
                            keyboardType: TextInputType.name,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.fullname_required;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Champ Email
                        Input(
                          label: l10n.email_label,
                          controller: _emailController,
                          icon: const Icon(Icons.email),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.email_required;
                            }
                            if (!value.contains('@')) {
                              return l10n.email_invalid;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Champ Mot de passe
                        Password(
                          label: l10n.password_label,
                          controller: _passwordController,
                          icon: const Icon(Icons.lock),
                          background: AppTheme.isDarkMode(context)
                              ? Colors.grey[900] ?? Colors.grey
                              : Colors.white,
                          state:  ref.watch(passwordViewModelProvider),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.password_required;
                            }
                            if (value.length < 6) {
                              return l10n.password_min_length;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // Mot de passe oublié - aligné à droite
                        if (!_isSignUp)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleResetPassword,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                l10n.forgot_password,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Bouton principal
                        BoutonFull(
                          texte: _isSignUp ? l10n.signup_button : l10n.login_button,
                          onTap: _handleEmailAuth,
                          fontSize: 18.0,
                          couleur: Setting.white,
                          isLoading: _isLoading,
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            l10n.or_continue_with,
                            style: TextStyle(
                              color: AppTheme.isDarkMode(context)
                                  ? Colors.grey[400]
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Boutons sociaux
                        Row(
                          children: [
                            Expanded(
                              child: BoutonFull(
                                texte: l10n.google_button,
                                background: AppTheme.googleColor,
                                couleur: Colors.white,
                                height: 48,
                                fontSize: 16,
                                isLoading: _isLoading,
                                onTap: _handleGoogleSignIn,
                                icon: const Icon(
                                  Icons.g_mobiledata,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: BoutonFull(
                                texte: l10n.apple_button,
                                background: Colors.black,
                                couleur: Colors.white,
                                height: 48,
                                fontSize: 16,
                                isLoading: _isLoading,
                                onTap: _handleAppleSignIn,
                                icon: const Icon(
                                  Icons.apple,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Lien d'inscription/connexion en bas de page
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: TextButton(
                onPressed: () {
                  setState(() => _isSignUp = !_isSignUp);
                },
                child: Text(
                  _isSignUp ? l10n.already_have_account : l10n.no_account,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
