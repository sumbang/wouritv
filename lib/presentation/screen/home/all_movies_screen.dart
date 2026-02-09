import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wouritv/config/setting.dart';
import 'package:wouritv/domain/entitie/movie_entity.dart';
import 'package:wouritv/l10n/app_localizations.dart';
import 'dart:developer' as developer;
import 'package:wouritv/presentation/screen/movie/movie_detail_screen.dart';

enum MovieListType {
  popular,
  newReleases,
  recommended,
}

class AllMoviesScreen extends ConsumerStatefulWidget {
  final MovieListType listType;
  final String title;
  final Future<List<MovieEntity>> Function({required int limit}) fetchMovies;

  const AllMoviesScreen({
    super.key,
    required this.listType,
    required this.title,
    required this.fetchMovies,
  });

  @override
  ConsumerState<AllMoviesScreen> createState() => _AllMoviesScreenState();
}

class _AllMoviesScreenState extends ConsumerState<AllMoviesScreen> {
  final List<MovieEntity> _movies = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentLimit = 20;

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMoreData) {
        _loadMoreMovies();
      }
    }
  }

  Future<void> _loadMovies() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final movies = await widget.fetchMovies(limit: _currentLimit);
      
      if (mounted) {
        setState(() {
          _movies.clear();
          _movies.addAll(movies);
          _isLoading = false;
          _hasMoreData = movies.length >= _currentLimit;
        });
      }
    } catch (e) {
      developer.log('Erreur lors du chargement des films', error: e, name: 'AllMoviesScreen');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreMovies() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _currentLimit += 20;
      final movies = await widget.fetchMovies(limit: _currentLimit);
      
      if (mounted) {
        setState(() {
          _movies.clear();
          _movies.addAll(movies);
          _isLoading = false;
          _hasMoreData = movies.length >= _currentLimit;
        });
      }
    } catch (e) {
      developer.log('Erreur lors du chargement de plus de films', error: e, name: 'AllMoviesScreen');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
    // Déterminer le nombre de colonnes selon la largeur de l'écran
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getCrossAxisCount(screenWidth);
    final childAspectRatio = _getChildAspectRatio(crossAxisCount);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _movies.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _movies.isEmpty
              ? Center(child: Text(l10n.no_movie))
              : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: crossAxisCount > 2 ? 8 : 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _movies.length + (_hasMoreData ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _movies.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final movie = _movies[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieDetailScreen(movie: movie),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Image carrée avec bords arrondis
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
                    );
                  },
                ),
    );
  }

  /// Déterminer le nombre de colonnes selon la largeur de l'écran
  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth >= 1200) {
      // Très grande tablette ou desktop
      return 4;
    } else if (screenWidth >= 900) {
      // Grande tablette en mode paysage
      return 3;
    } else if (screenWidth >= 600) {
      // Tablette en mode portrait
      return 3;
    } else {
      // Téléphone
      return 2;
    }
  }

  /// Ajuster le ratio d'aspect selon le nombre de colonnes
  double _getChildAspectRatio(int crossAxisCount) {
    switch (crossAxisCount) {
      case 4:
        return 0.6;
      case 3:
        return 0.65;
      case 2:
      default:
        return 0.7;
    }
  }
}
