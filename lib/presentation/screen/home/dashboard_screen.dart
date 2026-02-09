import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wouritv/config/providers.dart';
import 'package:wouritv/config/setting.dart';
import 'package:wouritv/data/api/supabase_auth_service.dart';
import 'package:wouritv/domain/entitie/movie_entity.dart';
import 'package:wouritv/l10n/app_localizations.dart';
import 'package:wouritv/presentation/screen/home/all_movies_screen.dart';
import 'package:wouritv/presentation/screen/home/profile_screen.dart';
import 'package:wouritv/presentation/screen/movie/movie_detail_screen.dart';
import 'dart:developer' as developer;

import 'package:wouritv/presentation/screen/home/search_screen.dart';
import 'package:wouritv/presentation/screen/home/my_list_screen.dart';

/// Page d'accueil principale pour les utilisateurs connectés
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _authService = SupabaseAuthService();
  int _currentIndex = 0;
  List<MovieEntity>? _latestMovies;
  List<MovieEntity>? _recommendedMovies;
  List<MovieEntity>? _watchedMovies;
  List<MovieEntity>? _randomMovies;
  bool _isLoadingMovies = true;
  bool _isLoadingRecommended = true;
  bool _isLoadingWatched = true;
  bool _isLoadingRandom = true;

  @override
  void initState() {
    super.initState();
    _loadLatestMovies();
    _loadRecommendedMovies();
    _loadWatchedMovies();
    _loadRandomMovies();
  }

  Future<void> _loadLatestMovies() async {
    try {
      developer.log('🎬 Début du chargement des derniers films', name: 'DashboardScreen');
      
      // Vérifier la connexion Supabase
      final supabaseClient = Supabase.instance.client;
      developer.log('📡 URL Supabase: ${supabaseClient.rest.url}', name: 'DashboardScreen');
      developer.log('🔑 Auth status: ${supabaseClient.auth.currentUser != null ? "Connecté" : "Non connecté"}', name: 'DashboardScreen');
      
      final getLatestMoviesUseCase = ref.read(getLatestMoviesUseCaseProvider);
      developer.log('✅ UseCase récupéré', name: 'DashboardScreen');
      
      final movies = await getLatestMoviesUseCase.execute();
      developer.log('📊 Nombre de films récupérés: ${movies.length}', name: 'DashboardScreen');
      
      if (movies.isNotEmpty) {
        developer.log('🎥 Premier film: ${movies.first.title}', name: 'DashboardScreen');
      }
      
      if (mounted) {
        setState(() {
          _latestMovies = movies;
          _isLoadingMovies = false;
        });
        developer.log('✅ État mis à jour avec succès', name: 'DashboardScreen');
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Erreur lors du chargement des derniers films',
        error: e,
        stackTrace: stackTrace,
        name: 'DashboardScreen',
      );
      
      // Afficher une SnackBar avec l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        
        setState(() {
          _isLoadingMovies = false;
        });
      }
    }
  }

  Future<void> _loadRandomMovies() async {
    try {
      developer.log('🎬 Début du chargement des films aléatoires', name: 'DashboardScreen');
      
      // Vérifier la connexion Supabase
      final supabaseClient = Supabase.instance.client;
      developer.log('📡 URL Supabase: ${supabaseClient.rest.url}', name: 'DashboardScreen');
      developer.log('🔑 Auth status: ${supabaseClient.auth.currentUser != null ? "Connecté" : "Non connecté"}', name: 'DashboardScreen');
      
      final getRandomsMoviesUseCase = ref.read(getRandomMoviesUseCaseProvider);
      developer.log('✅ UseCase récupéré', name: 'DashboardScreen');
      
      final movies = await getRandomsMoviesUseCase.execute();
      developer.log('📊 Nombre de films récupérés: ${movies.length}', name: 'DashboardScreen');
      
      if (movies.isNotEmpty) {
        developer.log('🎥 Premier film: ${movies.first.title}', name: 'DashboardScreen');
      }
      
      if (mounted) {
        setState(() {
          _randomMovies = movies;
          _isLoadingRandom = false;
        });
        developer.log('✅ État mis à jour avec succès', name: 'DashboardScreen');
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Erreur lors du chargement des films aléatoires',
        error: e,
        stackTrace: stackTrace,
        name: 'DashboardScreen',
      );
      
      // Afficher une SnackBar avec l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        
        setState(() {
          _isLoadingRandom = false;
        });
      }
    }
  }

  Future<void> _loadRecommendedMovies() async {
    try {
      developer.log('🎬 Début du chargement des films recommandés', name: 'DashboardScreen');
      
      final getRecommendedMoviesUseCase = ref.read(getRecommendedMoviesUseCaseProvider);
      final movies = await getRecommendedMoviesUseCase.execute(limit: 20);
      
      developer.log('📊 Nombre de films recommandés: ${movies.length}', name: 'DashboardScreen');
      
      if (mounted) {
        setState(() {
          _recommendedMovies = movies;
          _isLoadingRecommended = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Erreur lors du chargement des films recommandés',
        error: e,
        stackTrace: stackTrace,
        name: 'DashboardScreen',
      );
      
      if (mounted) {
        setState(() {
          _isLoadingRecommended = false;
        });
      }
    }
  }

  Future<void> _loadWatchedMovies() async {
    try {
      developer.log('🎬 Début du chargement des films regardes', name: 'DashboardScreen');
      
      final getWatchedMoviesUseCase = ref.read(getMostWatchedMoviesUseCaseProvider);
      final movies = await getWatchedMoviesUseCase.execute(limit: 20);
      
      developer.log('📊 Nombre de films regardés: ${movies.length}', name: 'DashboardScreen');
      
      if (mounted) {
        setState(() {
          _watchedMovies = movies;
          _isLoadingWatched = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Erreur lors du chargement des films regardés',
        error: e,
        stackTrace: stackTrace,
        name: 'DashboardScreen',
      );
      
      if (mounted) {
        setState(() {
          _isLoadingWatched = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final l10n = AppLocalizations.of(context)!;

    // Récupérer le nom complet ou l'email
    String userName = user?.userMetadata?['full_name'] as String? ?? 
                     user?.email?.split('@')[0] ?? 
                     'User';
    
    // Tronquer le nom s'il fait plus de 10 caractères
    if (userName.length > 10) {
      userName = '${userName.substring(0, 10)}...';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hello $userName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Notifications
            },
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            onPressed: () {
              // Naviguer vers l'onglet profil au lieu de pousser une nouvelle route
              setState(() {
                _currentIndex = 3;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
            tooltip: l10n.logout,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n.nav_home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: l10n.nav_search,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.video_library),
            label: l10n.nav_my_list,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: l10n.nav_profile,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final user = _authService.currentUser;

    switch (_currentIndex) {
      case 0:
        return _buildHomeTab(user);
      case 1:
        return const SearchScreen();
      case 2:
        return const MyListScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeTab(user);
    }
  }

  Widget _buildHomeTab(User? user) {

    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section - Carousel des derniers films
          _buildHeroCarousel(),

          const SizedBox(height: 24),

          // Sections de contenu - Limiter à 20 résultats
          _buildMovieSection(
            title: l10n.popular_movies,
            movies: _watchedMovies?.take(20).toList(),
            isLoading: _isLoadingWatched,
            onSeeAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllMoviesScreen(
                    listType: MovieListType.popular,
                    title: l10n.popular_movies,
                    fetchMovies: ({required int limit}) async {
                      final useCase = ref.read(getMostWatchedMoviesUseCaseProvider);
                      return await useCase.execute(limit: limit);
                    },
                  ),
                ),
              );
            },
          ),

          _buildMovieSection(
            title: l10n.new_releases,
            movies: _latestMovies?.take(20).toList(),
            isLoading: _isLoadingMovies,
            onSeeAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllMoviesScreen(
                    listType: MovieListType.newReleases,
                    title: l10n.new_releases,
                    fetchMovies: ({required int limit}) async {
                      final useCase = ref.read(getLatestMoviesUseCaseProvider);
                      return await useCase.execute(limit: limit);
                    },
                  ),
                ),
              );
            },
          ),

          _buildMovieSection(
            title: l10n.recommended_for_you,
            movies: _recommendedMovies?.take(20).toList(),
            isLoading: _isLoadingRecommended,
            onSeeAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllMoviesScreen(
                    listType: MovieListType.recommended,
                    title: l10n.recommended_for_you,
                    fetchMovies: ({required int limit}) async {
                      final useCase = ref.read(getRecommendedMoviesUseCaseProvider);
                      return await useCase.execute(limit: limit);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCarousel() {
    if (_isLoadingMovies) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Setting.primaryColor.withOpacity(0.8),
              Setting.primaryColor,
            ],
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(color: Setting.primaryColor),
        ),
      );
    }

    if (_randomMovies == null || _randomMovies!.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Setting.primaryColor.withOpacity(0.8),
              Setting.primaryColor,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.tv, size: 60, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.app_subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: _randomMovies!.length,
        itemBuilder: (context, index) {
          final movie = _randomMovies![index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailScreen(movie: movie),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image avec bords arrondis et ombre
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // Image de fond si disponible
                            if (movie.banniere != null)
                              Positioned.fill(
                                child: Image.network(
                                  movie.banniere!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Setting.primaryColor.withOpacity(0.8),
                                          Setting.primaryColor,
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.movie, size: 60, color: Colors.white54),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Setting.primaryColor.withOpacity(0.8),
                                        Setting.primaryColor,
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.movie, size: 60, color: Colors.white54),
                                  ),
                                ),
                              ),
                            // Overlay léger pour meilleure lisibilité
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.1),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Titre en dessous de l'image
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _capitalizeWords(movie.title ?? 'Sans titre'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Capitalise la première lettre de chaque mot
  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _buildMovieSection({
    required String title,
    required List<MovieEntity>? movies,
    required bool isLoading,
    VoidCallback? onSeeAll,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                child: Text(l10n.see_all),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : (movies == null || movies.isEmpty)
                  ? Center(
                      child: Text(
                        l10n.no_movie,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: movies.length,
                      itemBuilder: (context, index) {
                        final movie = movies[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MovieDetailScreen(movie: movie),
                              ),
                            );
                          },
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Image carrée avec bords arrondis
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: movie.banniere != null
                                        ? Image.network(
                                            movie.banniere!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Setting.primaryColor.withOpacity(0.8),
                                                    Setting.primaryColor,
                                                  ],
                                                ),
                                              ),
                                              child: const Center(
                                                child: Icon(Icons.movie, size: 40, color: Colors.white54),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Setting.primaryColor.withOpacity(0.8),
                                                  Setting.primaryColor,
                                                ],
                                              ),
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.movie, size: 40, color: Colors.white54),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Titre centré en bas
                                Text(
                                  _capitalizeWords(movie.title ?? 'Sans titre'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _handleSignOut() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logout_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:  Text(l10n.bt_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:  Text(l10n.bt_logout),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        developer.log('🚪 Début de la déconnexion depuis Dashboard', name: 'DashboardScreen');
        await _authService.signOut();
        developer.log('✅ Déconnexion réussie', name: 'DashboardScreen');

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e, stackTrace) {
        developer.log(
          '❌ Erreur lors de la déconnexion',
          error: e,
          stackTrace: stackTrace,
          name: 'DashboardScreen',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
