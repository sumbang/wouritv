# Wouri TV

Application Flutter de streaming : « Le Carrefour des cinémas d'Afrique ».

## Développement

Utiliser **Flutter 3.47.6 stable / Dart 3.13.5**, puis :

```sh
flutter pub get --enforce-lockfile
flutter analyze --no-fatal-infos
flutter test
flutter run
```

Le fichier `pubspec.lock` est versionné pour reproduire les versions validées. Après une mise à jour volontaire des dépendances, exécuter `flutter pub upgrade`, vérifier les migrations des plugins et remettre à jour ce fichier. Ne pas utiliser de `dependency_overrides` pour masquer un conflit de contraintes.

## Migration des dépendances et plateformes

La migration actualise les plugins Flutter et adapte les appels aux API incompatibles. Les versions précises et leurs dépendances transitives sont enregistrées dans `pubspec.yaml` et `pubspec.lock`. La chaîne Android utilise Java 17, AGP 8.13.2, Gradle 8.13, Kotlin 2.2.20, API 36, Android minimum 24 et un NDK r28 pour la compatibilité des bibliothèques natives avec les pages mémoire de 16 Ko. Le SDK de compilation ne correspond pas à la version minimale du système pouvant exécuter l'application.

Au 8 octobre 2026, les nouvelles versions Android mobiles soumises à Google Play doivent cibler **Android 16 / API 36**. Depuis le 28 avril 2026, les builds envoyés à App Store Connect doivent utiliser **Xcode 26 ou ultérieur et le SDK iOS 26 ou ultérieur**. Le déploiement minimum iOS est 15.0, selon les exigences des plugins ; cela n'impose pas iOS 26 aux utilisateurs.

Sources officielles : [archive Flutter](https://docs.flutter.dev/install/archive), [exigences Google Play](https://developer.android.com/google/play/requirements/target-sdk), [pages mémoire de 16 Ko](https://developer.android.com/guide/practices/page-sizes), [exigences Apple](https://developer.apple.com/news/upcoming-requirements/?id=04282026a).

## Validation et distribution

`.github/workflows/ci.yml` analyse et teste les PR et les branches `main`/`master`, puis compile un AAB release sans clé de production et une application iOS release sans signature. L'AAB de validation est un artefact de compilation, pas un fichier prêt à publier. La CI installe explicitement l'API Android 36 et le NDK r28, vérifie les segments ELF des bibliothèques natives 64 bits (`arm64-v8a` et `x86_64`) de l'AAB et l'alignement ZIP de l'APK pour les pages de 16 Ko. Elle vérifie Xcode et le SDK iOS >= 26 et refuse les erreurs d'analyse ou de test. Le lock CocoaPods régénéré est disponible dans l'artefact `ios-pod-lock` ; il doit être récupéré et versionné après validation macOS. Sur Linux, la compilation iOS n'est pas disponible ; ce contrôle s'exécute sur le runner macOS.

Le workflow de distribution existant, `deploy.yml`, s'exécute après fusion d'une PR et dépend désormais de cette validation. Il utilise les clés de signature et comptes de distribution configurés dans les secrets du dépôt. Il envoie Android sur la piste interne de Google Play et iOS sur TestFlight. L'identifiant Android est `mobile.apps.wouri` et doit correspondre à l'application existante dans Play Console. L'identifiant iOS est `ios.apps.wouri.tv`. Le workflow extrait l'équipe Apple et le nom du profil depuis le provisioning profile fourni dans les secrets et génère les options d'export ; aucun identifiant fictif n'est utilisé.

Secrets Android : `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`, `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`. Secrets iOS : `IOS_CERTIFICATE_P12_BASE64`, `IOS_CERTIFICATE_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64`, `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_BASE64`.

Avant toute publication publique :

- Vérifier le `versionCode` Android et le numéro de build iOS : ils doivent dépasser ceux déjà utilisés dans les consoles.
- Exécuter les builds signés avec les clés de production existantes, puis vérifier l'acceptation par Play Console et App Store Connect.
- Tester la lecture vidéo/YouTube, l'authentification, les notifications au premier plan et en arrière-plan, les permissions, les analytics et les rapports de crash sur appareils réels.
- Vérifier Android sur un appareil/émulateur configuré avec des pages mémoire de 16 Ko et contrôler les bibliothèques natives du bundle final.
- Vérifier les déclarations Data Safety, les manifests de confidentialité iOS, les justifications d'accès, ATT et la classification d'âge selon les fonctions réellement utilisées.

Une compilation et des tests automatisés réussis ne constituent pas une validation de publication par les stores ni un test complet des services Firebase/Supabase en production.

Les avertissements et erreurs sont bloquants ; les conseils de style préexistants restent visibles sans bloquer la CI. `cupertino_icons` reste en 1.0.9 car Chewie 1.17.2 impose la branche 1.x. Les outils de génération Hive et des icônes sont des dépendances de développement.

## Validation locale de cette migration

Sur Flutter 3.47.6 : résolution avec lockfile réussie, 68 tests passent, analyse sans erreur ni warning (`--no-fatal-infos` ; 52 conseils de style restent signalés). Les XML/plist et YAML ont été vérifiés. Les builds Android/iOS n'ont pas été exécutés localement : aucun SDK Android ni Xcode n'est installé. La CI doit encore confirmer les builds, régénérer `ios/Podfile.lock` et vérifier les binaires 16 Ko.

Le lock CocoaPods précédent, lié aux anciens plugins, a été retiré pour permettre une résolution complète des nouveaux SDK Firebase. Après le premier build macOS réussi, récupérer `ios-pod-lock` et versionner le lock résultant.

Les cinq dépendances de développement transitives restant sur des versions antérieures sont contraintes notamment par `hive_generator` 2.0.1 et son analyseur 6.x. Aucun override n'a été introduit.
