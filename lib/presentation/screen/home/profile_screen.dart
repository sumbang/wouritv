import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wouritv/data/api/supabase_auth_service.dart';
import 'package:wouritv/l10n/app_localizations.dart';

/// Exemple de page de profil utilisateur
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = SupabaseAuthService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    final user = _authService.currentUser;
    if (user?.userMetadata != null) {
      _nameController.text = user!.userMetadata?['name'] ?? '';
      _phoneController.text = user.userMetadata?['phone'] ?? '';
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      await _authService.updateUserMetadata(
        metadata: {
          'name': _nameController.text,
          'phone': _phoneController.text,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profil_ok),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ ERREUR updateUserMetadata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
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

  Future<void> _changePassword() async {
    final passwordController = TextEditingController();

    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.pwd_new),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.pwd_new,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.bt_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: Text(AppLocalizations.of(context)!.bt_confirm),
          ),
        ],
      ),
    );

    if (newPassword == null || newPassword.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _authService.updatePassword(newPassword: newPassword);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pwd_update),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    passwordController.dispose();
  }

  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version} (${packageInfo.buildNumber})';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue,
                child: Text(
                  user?.email?.substring(0, 2).toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 32, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Email
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(AppLocalizations.of(context)!.txt_email),
              subtitle: Text(user?.email ?? 'Non défini'),
            ),
            const Divider(),

            // ID utilisateur
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: Text(AppLocalizations.of(context)!.txt_user),
              subtitle: Text(user?.id ?? 'Non défini'),
            ),
            const Divider(),

            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.txt_perso,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Nom
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.txt_nom,
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Téléphone
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.txt_phone,
                prefixIcon: const Icon(Icons.phone),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton de mise à jour du profil
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(AppLocalizations.of(context)!.profile_update),
            ),
            const SizedBox(height: 16),

            // Bouton de changement de mot de passe
            OutlinedButton(
              onPressed: _isLoading ? null : _changePassword,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(AppLocalizations.of(context)!.txt_pwd),
            ),
            const SizedBox(height: 32),

            // Informations de session
            if (user?.createdAt != null) ...[
              Text(
                AppLocalizations.of(context)!.txt_cpte,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(AppLocalizations.of(context)!.txt_create),
                subtitle: Text(user!.createdAt),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.update),
                title: Text(AppLocalizations.of(context)!.app_version),
                subtitle: FutureBuilder<String>(
                  future: _getAppVersion(),
                  builder: (context, snapshot) {
                    return Text(snapshot.data ?? 'Loading...');
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
