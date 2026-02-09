# Tests Unitaires - API Data Layer

Ce dossier contient les tests unitaires pour la couche API de l'application WouriTV.

## Structure des Tests

```
test/
└── data/
    └── api/
        ├── supabase_auth_service_test.dart    # Tests pour l'authentification
        ├── supabase_movie_service_test.dart   # Tests pour les services vidéos
        └── README.md                           # Ce fichier
```

## Approche de Test

Ces tests utilisent une approche **sans mocks** qui se concentre sur :
- Validation de la logique métier
- Vérification des structures de données
- Tests des algorithmes (tri, filtrage, agrégation)
- Validation des formats (email, mot de passe, temps)
- Tests de la gestion du cache (avec Hive en mémoire)

Cette approche a été choisie car les services utilisent `Supabase.instance.client` directement, ce qui rend l'injection de dépendances complexe. Pour des tests d'intégration complets, un environnement Supabase de test serait nécessaire.

## Services Testés

### 1. SupabaseAuthService

Tests couvrant toutes les fonctionnalités d'authentification :

- **Inscription (Sign Up)**
  - Inscription avec email/password
  - Gestion des métadonnées utilisateur
  - Gestion des erreurs

- **Connexion (Sign In)**
  - Connexion email/password
  - Connexion OAuth (Google, Apple, Facebook)
  - Lien magique (Magic Link)
  - Vérification OTP

- **Gestion de Session**
  - Déconnexion
  - Récupération token d'accès
  - Rafraîchissement session
  - Vérification état authentification

- **Gestion du Profil**
  - Mise à jour métadonnées
  - Mise à jour mot de passe
  - Réinitialisation mot de passe

### 2. SupabaseVideoService

Tests couvrant toutes les fonctionnalités de gestion des vidéos :

- **Récupération de Films**
  - Films récents (`fetchLatestMovies`)
  - Films recommandés (`fetchMostRecommendedMovies`)
  - Films les plus regardés (`mostWatchingMovie`)
  - Films aléatoires (`fetchRandomMovies`)
  - Recherche de films (`searchMovies`)
  - Films par catégorie (`fetchMoviesByCategory`)
  - Films par chaîne (`fetchMoviesByChannel`)
  - Détails d'un film (`fetchMovieById`)

- **Gestion du Cache**
  - Vérification validité cache
  - Invalidation cache expiré
  - Mise en cache des données

- **Gestion des Lectures**
  - Création lecture
  - Mise à jour durée (incrémentale)
  - Suppression lecture
  - Parsing format temps (HH:MM:SS)

- **Gestion des Listes Utilisateur**
  - Ajout à la liste
  - Retrait de la liste
  - Vérification présence

- **Gestion des Recommandations**
  - Ajout recommandation (positive/négative)
  - Mise à jour recommandation
  - Comptage recommandations
  - Filtrage par date (3 mois)

- **Validation des Données**
  - Champs requis
  - Champs optionnels
  - Gestion erreurs

## Installation des Dépendances

Avant d'exécuter les tests, installez les dépendances :

```bash
flutter pub get
```

Les dépendances de test incluent :
- `flutter_test` : Framework de test Flutter
- `hive` : Pour les tests de cache en mémoire

## Exécution des Tests

### Exécuter tous les tests

```bash
flutter test
```

### Exécuter les tests d'un fichier spécifique

```bash
# Tests d'authentification
flutter test test/data/api/supabase_auth_service_test.dart

# Tests de service vidéo
flutter test test/data/api/supabase_movie_service_test.dart
```

### Exécuter avec couverture de code

```bash
flutter test --coverage
```

Le rapport de couverture sera généré dans `coverage/lcov.info`.

### Afficher le rapport de couverture (macOS/Linux)

```bash
# Installer genhtml
brew install lcov  # macOS
# ou
sudo apt-get install lcov  # Linux

# Générer le rapport HTML
genhtml coverage/lcov.info -o coverage/html

# Ouvrir le rapport
open coverage/html/index.html  # macOS
# ou
xdg-open coverage/html/index.html  # Linux
```

## Type de Tests Implémentés

### Tests de Validation
- Validation des formats d'email et mots de passe
- Validation des structures de données (métadonnées, tokens)
- Vérification des paramètres requis vs optionnels

### Tests d'Algorithmes
- Tri et filtrage de films
- Agrégation de données (comptage de recommandations, temps de visionnage)
- Mélange aléatoire (shuffle)
- Pagination et calcul de ranges

### Tests de Logique Métier
- Gestion du cache (fraîcheur, invalidation)
- Parsing de temps (HH:MM:SS ↔ secondes)
- Mapping de données (videoId → movieId)
- Calcul de durées cumulatives

### Tests de Configuration
- Providers OAuth (Google, Apple, Facebook)
- URLs de redirection
- Types OTP
- Durées de cache

## Notes Importantes

### Approche de Test Actuelle

Ces tests utilisent une approche **sans mocks** pour plusieurs raisons :

1. **Architecture des Services** : Les services utilisent `Supabase.instance.client` directement (singleton), ce qui rend difficile l'injection de mocks.

2. **Focus sur la Logique** : Les tests se concentrent sur la logique métier vérifiable sans dépendances externes :
   - Validation de données
   - Algorithmes de tri et filtrage
   - Calculs et conversions
   - Gestion du cache Hive

3. **Tests Rapides** : Sans appels réseau ni mocks complexes, les tests s'exécutent très rapidement.

### Limitations

- ❌ Pas de tests d'intégration avec Supabase réel
- ❌ Pas de tests des appels API réels
- ❌ Pas de vérification des réponses Supabase

### Recommandations pour Tests Complets

Pour ajouter des tests d'intégration complets :

Pour ajouter des tests d'intégration complets :

1. **Refactoriser pour l'Injection de Dépendances** :
   ```dart
   class SupabaseVideoService {
     final SupabaseClient client;
     SupabaseVideoService({SupabaseClient? client}) 
       : client = client ?? Supabase.instance.client;
   }
   ```

2. **Créer un Projet Supabase de Test** :
   - Base de données dédiée aux tests
   - Données de test pré-remplies
   - Scripts de nettoyage

3. **Utiliser des Mocks pour Tests Isolés** :
   - Installer `mockito` et `build_runner`
   - Générer les mocks avec `@GenerateMocks`
   - Tester chaque méthode en isolation

### Structure Recommandée des Tests

Chaque test suit le pattern AAA (Arrange-Act-Assert) :

```dart
test('description du test', () {
  // Arrange - Préparer les données de test
  final testData = {...};
  
  // Act - Exécuter la logique à tester
  final result = calculateSomething(testData);
  
  // Assert - Vérifier les résultats
  expect(result, expectedValue);
});
```

Pour les tests asynchrones :

```dart
test('description du test async', () async {
  // Arrange
  final testData = {...};
  
  // Act
  final result = await asyncMethod(testData);
  
  // Assert
  expect(result, expectedValue);
});
```

## Couverture de Tests

Les tests actuels couvrent :

✅ Validation de données (email, password, metadata)
✅ Configuration OAuth et URLs de redirection
✅ Logique de cache (Hive) - fraîcheur et invalidation
✅ Algorithmes de tri, filtrage et agrégation
✅ Parsing et conversion de formats (temps, types)
✅ Gestion de pagination et calculs de range
✅ Structures de données et validation de champs
✅ Messages d'erreur et gestion d'exceptions
✅ Logique métier (comptage, cumuls, mapping)

❌ Appels API réels vers Supabase
❌ Authentification OAuth en conditions réelles
❌ Tests d'intégration end-to-end

## Améliorations Futures

- [ ] Refactoriser services pour injection de dépendances
- [ ] Ajouter tests d'intégration avec Supabase de test
- [ ] Créer des mocks pour tester les appels API en isolation
- [ ] Ajouter tests de performance pour le cache
- [ ] Tester cas limites (données volumineuses, timeouts)
- [ ] Ajouter tests de widgets pour les screens
- [ ] Tests de régression pour les bugs corrigés
- [ ] Tests de sécurité (validation tokens, sessions)

## Ressources

- [Documentation Flutter Testing](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart/introduction)

## Contribution

Pour ajouter de nouveaux tests :

1. Suivre la structure existante (Arrange-Act-Assert)
2. Utiliser des noms de tests descriptifs
3. Grouper les tests par fonctionnalité avec `group()`
4. Ajouter des commentaires pour les cas complexes
5. Vérifier la couverture de code après ajout

## Support

En cas de problème avec les tests, vérifier :

1. Que toutes les dépendances sont installées (`flutter pub get`)
2. Que les mocks sont générés (`build_runner`)
3. Que Hive est correctement initialisé
4. Les logs de sortie pour identifier les erreurs spécifiques
