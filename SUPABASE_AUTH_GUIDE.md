# Guide d'utilisation - Authentification Supabase Flutter

## 📦 Fichiers créés

1. **`lib/data/api/supabase_auth_service.dart`** - Service d'authentification principal
2. **`lib/presentation/screen/auth/login_screen.dart`** - Écran de connexion/inscription
3. **`lib/presentation/screen/auth/auth_gate.dart`** - Widget pour gérer l'état d'authentification
4. **`lib/presentation/screen/auth/profile_screen.dart`** - Écran de profil utilisateur

## 🚀 Fonctionnalités implémentées

### Service d'authentification (`SupabaseAuthService`)

- ✅ Inscription avec email/mot de passe
- ✅ Connexion avec email/mot de passe
- ✅ Connexion Google OAuth
- ✅ Connexion Apple OAuth
- ✅ Connexion Facebook OAuth
- ✅ Lien magique (Magic Link)
- ✅ Réinitialisation du mot de passe
- ✅ Mise à jour du mot de passe
- ✅ Mise à jour des métadonnées utilisateur
- ✅ Déconnexion
- ✅ Vérification OTP
- ✅ Rafraîchissement de session
- ✅ Stream des changements d'état

## 📝 Utilisation

### 1. Dans votre `main.dart`

```dart
import 'package:wouritv/presentation/screen/auth/auth_gate.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wouri TV',
      home: AuthGate(), // Utiliser AuthGate comme point d'entrée
    );
  }
}
```

### 2. Utilisation du service d'authentification

```dart
import 'package:wouritv/data/api/supabase_auth_service.dart';

final authService = SupabaseAuthService();

// Inscription
await authService.signUpWithEmail(
  email: 'user@example.com',
  password: 'password123',
);

// Connexion
await authService.signInWithEmail(
  email: 'user@example.com',
  password: 'password123',
);

// Vérifier si connecté
if (authService.isAuthenticated) {
  print('Utilisateur connecté: ${authService.currentUser?.email}');
}

// Déconnexion
await authService.signOut();
```

### 3. Écouter les changements d'authentification

```dart
authService.authStateChanges.listen((event) {
  final user = event.session?.user;
  if (user != null) {
    print('Utilisateur connecté: ${user.email}');
  } else {
    print('Utilisateur déconnecté');
  }
});
```

### 4. Avec Riverpod (optionnel)

Si vous utilisez Riverpod, décommentez le code dans `auth_gate.dart` :

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isAuth = ref.watch(isAuthenticatedProvider);
    
    if (isAuth) {
      return Text('Connecté: ${user?.email}');
    }
    return Text('Non connecté');
  }
}
```

## ⚙️ Configuration OAuth (Google, Apple, Facebook)

### Pour Google

1. Dans la console Supabase, allez dans Authentication > Providers
2. Activez Google et ajoutez vos identifiants OAuth
3. Configurez le Redirect URL : `io.supabase.wouritv://login-callback/`

### Pour Apple

1. Configurez Apple Sign In dans votre compte développeur Apple
2. Dans Supabase, activez Apple comme provider
3. Ajoutez les identifiants nécessaires

### Pour Facebook

1. Créez une app Facebook Developer
2. Dans Supabase, activez Facebook comme provider
3. Ajoutez l'App ID et l'App Secret

### Configuration Android (android/app/src/main/AndroidManifest.xml)

```xml
<manifest>
  <application>
    <!-- Deep linking pour OAuth -->
    <activity android:name=".MainActivity">
      <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
          android:scheme="io.supabase.wouritv"
          android:host="login-callback" />
      </intent-filter>
    </activity>
  </application>
</manifest>
```

### Configuration iOS (ios/Runner/Info.plist)

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>io.supabase.wouritv</string>
    </array>
  </dict>
</array>
```

## 🔐 Sécurité

- Les mots de passe doivent contenir au moins 6 caractères
- Les sessions sont automatiquement rafraîchies
- Les tokens sont stockés de manière sécurisée par Supabase
- Utilisez HTTPS en production

## 🎨 Personnalisation

Vous pouvez personnaliser les écrans en modifiant :
- Les couleurs dans les thèmes
- Les validations de formulaire
- Les messages d'erreur
- Les redirections après connexion

## 📱 Exemples de navigation

```dart
// Dans LoginScreen après connexion réussie
Navigator.of(context).pushReplacementNamed('/home');

// Dans ProfileScreen pour se déconnecter
await authService.signOut();
Navigator.of(context).pushReplacementNamed('/login');
```

## 🐛 Gestion des erreurs

Toutes les méthodes lancent des exceptions en cas d'erreur. Utilisez try-catch :

```dart
try {
  await authService.signInWithEmail(
    email: email,
    password: password,
  );
} catch (e) {
  print('Erreur de connexion: $e');
  // Afficher un message à l'utilisateur
}
```

## 📊 Métadonnées utilisateur

Vous pouvez stocker des informations supplémentaires :

```dart
// Lors de l'inscription
await authService.signUpWithEmail(
  email: 'user@example.com',
  password: 'password123',
  metadata: {
    'name': 'John Doe',
    'age': 30,
    'country': 'France',
  },
);

// Mise à jour
await authService.updateUserMetadata(
  metadata: {
    'name': 'Jane Doe',
    'phone': '+33612345678',
  },
);

// Lecture
final metadata = authService.currentUser?.userMetadata;
print(metadata?['name']);
```

## 🔄 Rafraîchissement de session

Les sessions sont automatiquement rafraîchies, mais vous pouvez le faire manuellement :

```dart
await authService.refreshSession();
```

## 📧 Lien magique (Magic Link)

Connexion sans mot de passe :

```dart
await authService.signInWithMagicLink(
  email: 'user@example.com',
);
// L'utilisateur recevra un email avec un lien de connexion
```

## ✅ Vérification OTP

```dart
await authService.verifyOTP(
  email: 'user@example.com',
  token: '123456',
);
```
