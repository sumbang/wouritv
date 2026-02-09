# 🏗️ Guide d'intégration des tables Supabase avec Flutter BLoC

## 📋 Structure créée

```
lib/
├── data/
│   ├── model/
│   │   └── video_model.dart          # Modèle de données (JSON ↔ Dart)
│   ├── repository/
│   │   └── video_repository_impl.dart # Implémentation du repository
│   └── api/
│       └── supabase_video_service.dart # Service API Supabase
├── domain/
│   ├── entitie/
│   │   └── video_entity.dart         # Entité métier
│   ├── repository/
│   │   └── video_repository.dart     # Interface du repository
│   └── usercase/
│       └── get_videos_usecase.dart   # Use cases
├── presentation/
│   └── bloc/
│       └── video/
│           ├── video_bloc.dart       # BLoC
│           ├── video_event.dart      # Événements
│           └── video_state.dart      # États
└── config/
    └── providers.dart                # Providers Riverpod
```

## 🗄️ Configuration Supabase

### 1. Créer la table `videos` dans Supabase

```sql
CREATE TABLE videos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  video_url TEXT NOT NULL,
  category TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  views INTEGER DEFAULT 0,
  likes INTEGER DEFAULT 0
);

-- Index pour améliorer les performances
CREATE INDEX idx_videos_category ON videos(category);
CREATE INDEX idx_videos_created_at ON videos(created_at DESC);
CREATE INDEX idx_videos_views ON videos(views DESC);

-- Fonction pour incrémenter les vues
CREATE OR REPLACE FUNCTION increment_views(video_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE videos SET views = views + 1 WHERE id = video_id;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour incrémenter les likes
CREATE OR REPLACE FUNCTION increment_likes(video_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE videos SET likes = likes + 1 WHERE id = video_id;
END;
$$ LANGUAGE plpgsql;
```

### 2. Configurer les politiques RLS (Row Level Security)

```sql
-- Activer RLS
ALTER TABLE videos ENABLE ROW LEVEL SECURITY;

-- Politique de lecture (tout le monde peut lire)
CREATE POLICY "Videos are viewable by everyone"
ON videos FOR SELECT
USING (true);

-- Politique d'insertion (seulement les authentifiés)
CREATE POLICY "Authenticated users can insert videos"
ON videos FOR INSERT
TO authenticated
WITH CHECK (true);

-- Politique de mise à jour (seulement les authentifiés)
CREATE POLICY "Authenticated users can update videos"
ON videos FOR UPDATE
TO authenticated
USING (true);
```

## 📱 Utilisation dans les screens

### Exemple 1: Afficher la liste des vidéos

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wouritv/config/providers.dart';
import 'package:wouritv/presentation/bloc/video/video_bloc.dart';
import 'package:wouritv/presentation/bloc/video/video_event.dart';
import 'package:wouritv/presentation/bloc/video/video_state.dart';

class VideoListScreen extends ConsumerWidget {
  const VideoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoBloc = ref.watch(videoBlocProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vidéos')),
      body: BlocProvider.value(
        value: videoBloc..add(LoadVideosEvent()),
        child: BlocBuilder<VideoBloc, VideoState>(
          builder: (context, state) {
            if (state is VideoLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is VideoError) {
              return Center(child: Text('Erreur: ${state.message}'));
            }
            
            if (state is VideoEmpty) {
              return Center(child: Text(state.message));
            }
            
            if (state is VideoLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  videoBloc.add(RefreshVideosEvent());
                },
                child: ListView.builder(
                  itemCount: state.videos.length,
                  itemBuilder: (context, index) {
                    final video = state.videos[index];
                    return ListTile(
                      leading: Image.network(
                        video.thumbnailUrl,
                        width: 100,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.movie),
                      ),
                      title: Text(video.title),
                      subtitle: Text(video.description),
                      trailing: Text('${video.views} vues'),
                      onTap: () {
                        // Navigation vers le détail
                      },
                    );
                  },
                ),
              );
            }
            
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
```

### Exemple 2: Recherche de vidéos

```dart
class VideoSearchScreen extends ConsumerStatefulWidget {
  const VideoSearchScreen({super.key});

  @override
  ConsumerState<VideoSearchScreen> createState() => _VideoSearchScreenState();
}

class _VideoSearchScreenState extends ConsumerState<VideoSearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoBloc = ref.watch(videoBlocProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Rechercher...',
            border: InputBorder.none,
          ),
          onSubmitted: (query) {
            videoBloc.add(SearchVideosEvent(query));
          },
        ),
      ),
      body: BlocProvider.value(
        value: videoBloc,
        child: BlocBuilder<VideoBloc, VideoState>(
          builder: (context, state) {
            // Même logique que l'exemple 1
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
```

### Exemple 3: Vidéos par catégorie

```dart
videoBloc.add(LoadVideosByCategoryEvent('Films'));
```

### Exemple 4: Vidéos populaires

```dart
videoBloc.add(const LoadPopularVideosEvent(limit: 20));
```

## 🔄 Pour adapter à vos propres tables

### Étape 1: Créer l'entité
```dart
// lib/domain/entitie/ma_table_entity.dart
class MaTableEntity extends Equatable {
  final String id;
  final String nom;
  // ... vos champs
  
  const MaTableEntity({required this.id, required this.nom});
  
  @override
  List<Object?> get props => [id, nom];
}
```

### Étape 2: Créer le modèle
```dart
// lib/data/model/ma_table_model.dart
class MaTableModel extends MaTableEntity {
  const MaTableModel({required super.id, required super.nom});
  
  factory MaTableModel.fromJson(Map<String, dynamic> json) {
    return MaTableModel(
      id: json['id'],
      nom: json['nom'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {'id': id, 'nom': nom};
  }
}
```

### Étape 3: Créer le service API
```dart
// lib/data/api/supabase_ma_table_service.dart
class SupabaseMaTableService {
  final _client = Supabase.instance.client;
  
  Future<List<MaTableModel>> fetch() async {
    final response = await _client.from('ma_table').select();
    return (response as List).map((e) => MaTableModel.fromJson(e)).toList();
  }
}
```

### Étape 4: Créer le repository
```dart
// lib/domain/repository/ma_table_repository.dart
abstract class MaTableRepository {
  Future<List<MaTableEntity>> getData();
}

// lib/data/repository/ma_table_repository_impl.dart
class MaTableRepositoryImpl implements MaTableRepository {
  final SupabaseMaTableService service;
  MaTableRepositoryImpl(this.service);
  
  @override
  Future<List<MaTableEntity>> getData() async {
    final data = await service.fetch();
    return data.map((e) => e as MaTableEntity).toList();
  }
}
```

### Étape 5: Créer les use cases, BLoC, etc.

Suivez le même pattern que pour `video`.

## 📦 Dépendances requises

Ajoutez dans `pubspec.yaml` si ce n'est pas déjà fait :

```yaml
dependencies:
  flutter_bloc: ^8.1.6
  equatable: ^2.0.8
  hooks_riverpod: ^3.2.0
```

## 🚀 Prochaines étapes

1. **Adaptez** le code à vos tables Supabase réelles
2. **Créez** les SQL pour vos tables
3. **Configurez** les RLS policies
4. **Testez** l'intégration
5. **Ajoutez** d'autres tables suivant le même pattern

**Quelle est votre première table à intégrer ?** Je peux adapter le code spécifiquement pour elle.
