import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wouritv/config/providers.dart';
import 'package:wouritv/config/setting.dart';
import 'package:wouritv/domain/entitie/movie_entity.dart';
import 'package:wouritv/l10n/app_localizations.dart';
import 'package:wouritv/presentation/screen/auth/auth_gate.dart';
import 'package:wouritv/presentation/screen/movie/movie_detail_screen.dart';
import 'dart:developer' as developer;

/// Écran pour afficher la liste de films de l'utilisateur
class MyListScreen extends ConsumerStatefulWidget {
  const MyListScreen({super.key});

  @override
  ConsumerState<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends ConsumerState<MyListScreen> {
  List<MovieEntity>? _userMovies;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserList();
  }

  Future<void> _loadUserList() async {
    try {
      setState(() {
        _isLoading = true;
      });

      developer.log('🎬 Chargement de la liste utilisateur', name: 'MyListScreen');
      
      final authService = ref.read(authServiceProvider);
      final userId = authService.currentUser?.id;
      
      if (userId == null) {
        developer.log('❌ Utilisateur non connecté', name: 'MyListScreen');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _userMovies = [];
          });
        }
        return;
      }

      final getListMovieUseCase = ref.read(getListMovieUseCaseProvider);
      final movies = await getListMovieUseCase.execute(userId);
      
      developer.log('✅ ${movies.length} films récupérés', name: 'MyListScreen');
      
      if (mounted) {
        setState(() {
          _userMovies = movies;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Erreur lors du chargement de la liste',
        error: e,
        stackTrace: stackTrace,
        name: 'MyListScreen',
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _userMovies = [];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_userMovies == null || _userMovies!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.my_list_title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                l10n.my_list_description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserList,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: _userMovies!.length,
        itemBuilder: (context, index) {
          final movie = _userMovies![index];
          return _buildMovieCard(movie);
        },
      ),
    );
  }

  Widget _buildMovieCard(MovieEntity movie) {
    return GestureDetector(
      onTap: () async {
        // Naviguer vers le détail du film
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(movie: movie),
          ),
        );
        
        // Si le film a été retiré de la liste, recharger
        if (result == true) {
          _loadUserList();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image du film
          Expanded(
            child: Container(
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
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Titre du film
          Text(
            _capitalizeWords(movie.title ?? 'Sans titre'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
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
        child: Icon(
          Icons.movie,
          size: 40,
          color: Colors.white54,
        ),
      ),
    );
  }
}
