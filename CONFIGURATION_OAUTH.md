# 🔐 Configuration OAuth - Google & Facebook

## ✅ Votre configuration actuelle

Vous avez activé dans Supabase :
- ✅ Email/Password
- ✅ Google OAuth
- ✅ Facebook OAuth

## 📱 Configuration complète

### 1️⃣ Configuration Supabase (Dashboard)

#### Google OAuth
1. Allez dans **Authentication > Providers > Google**
2. Activez Google
3. Vous verrez le **Callback URL** : `https://[votre-projet].supabase.co/auth/v1/callback`
4. Notez-le pour la configuration Google Console

#### Facebook OAuth
1. Allez dans **Authentication > Providers > Facebook**
2. Activez Facebook
3. Notez également le **Callback URL**

---

### 2️⃣ Configuration Google Cloud Console

1. **Créer un projet**
   - Allez sur https://console.cloud.google.com
   - Créez un nouveau projet ou sélectionnez-en un

2. **Activer Google+ API**
   - Dans le menu, allez à **APIs & Services > Library**
   - Recherchez "Google+ API" et activez-la

3. **Créer des identifiants OAuth 2.0**
   - Allez à **APIs & Services > Credentials**
   - Cliquez sur **Create Credentials > OAuth 2.0 Client ID**
   
4. **Configurer l'écran de consentement**
   - Type d'utilisateur : Externe
   - Nom de l'application : Wouri TV
   - Email d'assistance
   - Logo (optionnel)
   - Domaine autorisé : `wouritv.com` (si applicable)

5. **Créer Client ID pour Web**
   - Type d'application : **Application Web**
   - Nom : Wouri TV Web
   - URI de redirection autorisés : 
     ```
     https://[votre-projet].supabase.co/auth/v1/callback
     ```
   - Copiez le **Client ID** et le **Client Secret**

6. **Créer Client ID pour Android**
   - Type : **Android**
   - Nom : Wouri TV Android
   - Nom du package : `com.wouritv.app` (vérifiez dans `android/app/build.gradle`)
   - Empreinte du certificat SHA-1 :
     ```bash
     # Pour le debug
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     
     # Pour la release
     keytool -list -v -keystore [chemin-vers-votre-keystore] -alias [votre-alias]
     ```

7. **Créer Client ID pour iOS**
   - Type : **iOS**
   - Nom : Wouri TV iOS
   - Bundle ID : `com.wouritv.app` (vérifiez dans `ios/Runner/Info.plist`)

8. **Ajouter les identifiants dans Supabase**
   - Retournez dans **Supabase > Authentication > Providers > Google**
   - Collez le **Client ID Web**
   - Collez le **Client Secret Web**
   - Sauvegardez

---

### 3️⃣ Configuration Facebook Developer

1. **Créer une application Facebook**
   - Allez sur https://developers.facebook.com
   - **Mes Apps > Créer une app**
   - Type : **Consommateur**
   - Nom : Wouri TV
   - Email de contact

2. **Ajouter Facebook Login**
   - Dans le tableau de bord, cliquez sur **Ajouter un produit**
   - Sélectionnez **Facebook Login**
   - Choisissez la plateforme : **iOS et Android**

3. **Configurer Facebook Login**
   - Allez dans **Facebook Login > Paramètres**
   - URI de redirection OAuth valides :
     ```
     https://[votre-projet].supabase.co/auth/v1/callback
     ```
   - Domaines d'application autorisés : `wouritv.com`

4. **Récupérer les identifiants**
   - Allez dans **Paramètres > Basique**
   - Copiez **l'ID de l'app**
   - Copiez le **Clé secrète de l'app** (cliquez sur Afficher)

5. **Ajouter les identifiants dans Supabase**
   - Retournez dans **Supabase > Authentication > Providers > Facebook**
   - Collez l'**App ID** (Client ID)
   - Collez la **App Secret** (Client Secret)
   - Sauvegardez

6. **Configurer Android**
   - Dans Facebook Developer, allez à **Paramètres > Basique**
   - Ajoutez la plateforme **Android**
   - Nom du package : `com.wouritv.app`
   - Nom de la classe d'activité par défaut : `com.wouritv.app.MainActivity`
   - Hash de clé (générez-le) :
     ```bash
     keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
     # Mot de passe : android
     ```

7. **Configurer iOS**
   - Ajoutez la plateforme **iOS**
   - Bundle ID : `com.wouritv.app`
   - Activez **Single Sign On**

---

### 4️⃣ Configuration Android (AndroidManifest.xml)

Fichier : `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop">
            
            <!-- Intent filter existant -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            
            <!-- Deep linking pour Supabase OAuth -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                
                <!-- Scheme personnalisé pour votre app -->
                <data
                    android:scheme="io.supabase.wouritv"
                    android:host="login-callback" />
            </intent-filter>
            
        </activity>
        
        <!-- Facebook App ID -->
        <meta-data
            android:name="com.facebook.sdk.ApplicationId"
            android:value="@string/facebook_app_id"/>
        
        <meta-data
            android:name="com.facebook.sdk.ClientToken"
            android:value="@string/facebook_client_token"/>
            
    </application>
    
    <!-- Permissions Internet -->
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>
```

Fichier : `android/app/src/main/res/values/strings.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Wouri TV</string>
    <string name="facebook_app_id">VOTRE_FACEBOOK_APP_ID</string>
    <string name="facebook_client_token">VOTRE_FACEBOOK_CLIENT_TOKEN</string>
</resources>
```

---

### 5️⃣ Configuration iOS (Info.plist)

Fichier : `ios/Runner/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Configurations existantes -->
    
    <!-- URL Schemes pour Supabase OAuth -->
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
        
        <!-- Facebook URL Scheme -->
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>fbVOTRE_FACEBOOK_APP_ID</string>
            </array>
        </dict>
    </array>
    
    <!-- Facebook App ID -->
    <key>FacebookAppID</key>
    <string>VOTRE_FACEBOOK_APP_ID</string>
    
    <key>FacebookDisplayName</key>
    <string>Wouri TV</string>
    
    <!-- Whitelist Facebook Servers -->
    <key>LSApplicationQueriesSchemes</key>
    <array>
        <string>fbapi</string>
        <string>fb-messenger-share-api</string>
        <string>fbauth2</string>
        <string>fbshareextension</string>
    </array>
    
</dict>
</plist>
```

---

### 6️⃣ Test de la configuration

#### Test Google
```dart
final authService = SupabaseAuthService();

try {
  final success = await authService.signInWithGoogle();
  if (success) {
    print('Connexion Google réussie!');
  }
} catch (e) {
  print('Erreur Google: $e');
}
```

#### Test Facebook
```dart
final authService = SupabaseAuthService();

try {
  final success = await authService.signInWithFacebook();
  if (success) {
    print('Connexion Facebook réussie!');
  }
} catch (e) {
  print('Erreur Facebook: $e');
}
```

---

### 7️⃣ URLs de callback importantes

Assurez-vous que ces URLs sont configurées partout :

**Callback URL Supabase** (à ajouter dans Google et Facebook) :
```
https://[votre-projet-id].supabase.co/auth/v1/callback
```

**Deep Link Flutter** (pour redirection après OAuth) :
```
io.supabase.wouritv://login-callback/
```

---

### 8️⃣ Gestion des erreurs courantes

#### Google
- **Error 400: redirect_uri_mismatch** → Vérifiez que l'URL de callback dans Google Console correspond exactement
- **Error 401: invalid_client** → Vérifiez Client ID et Secret dans Supabase
- **Developer Error** → Ajoutez votre compte Gmail en tant que testeur dans Google Console

#### Facebook
- **URL blocked** → Ajoutez l'URL dans les domaines OAuth autorisés
- **App not configured** → Passez l'app en mode "Live" dans Facebook Developer
- **Invalid key hash** → Régénérez le hash de clé Android

---

### 9️⃣ Mode Production

Avant de publier :

1. **Google**
   - Passez l'écran de consentement en mode "Publication"
   - Créez un keystore de production et ajoutez son SHA-1

2. **Facebook**
   - Passez l'app en mode "Live"
   - Complétez la vérification d'entreprise si nécessaire
   - Ajoutez le hash de clé de production

3. **Supabase**
   - Vérifiez les limites de taux
   - Activez la protection CAPTCHA si nécessaire

---

## 🧪 Tests recommandés

1. Test connexion Google sur Android
2. Test connexion Google sur iOS
3. Test connexion Facebook sur Android
4. Test connexion Facebook sur iOS
5. Test déconnexion
6. Test données utilisateur récupérées
7. Test deep linking après OAuth

---

## 📞 Support

Si vous rencontrez des problèmes :
- Vérifiez les logs Supabase : Dashboard > Logs
- Activez le mode debug dans votre app
- Vérifiez que tous les identifiants sont corrects
- Testez d'abord sur émulateur, puis sur appareil réel
