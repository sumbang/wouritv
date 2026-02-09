import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wouritv/config/providers.dart';
import 'package:wouritv/config/setting.dart';
import 'package:wouritv/domain/entitie/movie_entity.dart';
import 'package:wouritv/l10n/app_localizations.dart';
import 'package:wouritv/presentation/component/widget/search_input.dart';
import 'package:wouritv/presentation/screen/movie/movie_detail_screen.dart';
import 'dart:developer' as developer;

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<MovieEntity> _searchResults = [];
  bool _isSearching = false;
  
  // Contenu par défaut
  List<MovieEntity>? _popularSeries;
  List<MovieEntity>? _popularMovies;
  List<MovieEntity>? _userList;
  bool _isLoadingDefault = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    _loadDefaultContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultContent() async {
    try {
      setState(() {
        _isLoadingDefault = true;
      });

      // Charger les séries populaires (catégorie "SERIE")
      final seriesUseCase = ref.read(getMoviesByCategoryUseCaseProvider);
      final series = await seriesUseCase.execute('SERIE', limit: 10);

      // Charger les films populaires (catégorie "FILM")
      final filmsUseCase = ref.read(getMoviesByCategoryUseCaseProvider);
      final films = await filmsUseCase.execute('FILM', limit: 10);

      // Charger les derniers films ajoutés
      final latestUseCase = ref.read(getLatestMoviesUseCaseProvider);
      final latest = await latestUseCase.execute(limit: 10);

      if (mounted) {
        setState(() {
          _popularSeries = series;
          _popularMovies = films;
          _userList = latest;
          _isLoadingDefault = false;
        });
      }
    } catch (e) {
      developer.log('Erreur lors du chargement du contenu par défaut: $e', name: 'SearchScreen');
      if (mounted) {
        setState(() {
          _isLoadingDefault = false;
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final searchUseCase = ref.read(searchMoviesUseCaseProvider);
      final results = await searchUseCase.execute(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      developer.log('Erreur lors de la recherche: $e', name: 'SearchScreen');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SearchInput(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: l10n.search_hint,
            onChanged: _performSearch,
            onClear: () => _performSearch(''),
          ),
        ),

        // Contenu
        Expanded(
          child: _searchController.text.isEmpty
              ? _buildDefaultContent(l10n)
              : _buildSearchResults(l10n),
        ),
      ],
    );
  }

  Widget _buildDefaultContent(AppLocalizations l10n) {
    if (_isLoadingDefault) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Séries populaires
          if (_popularSeries != null && _popularSeries!.isNotEmpty)
            _buildSection(
              title: l10n.popular_series,
              movies: _popularSeries!,
            ),
          
          const SizedBox(height: 24),
          
          // Films populaires
          if (_popularMovies != null && _popularMovies!.isNotEmpty)
            _buildSection(
              title: l10n.popular_movies,
              movies: _popularMovies!,
            ),
          
          const SizedBox(height: 24),
          
          // Derniers ajouts
          if (_userList != null && _userList!.isNotEmpty)
            _buildSection(
              title: l10n.latest_additions,
              movies: _userList!,
            ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<MovieEntity> movies}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return _buildMovieCard(movie);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMovieCard(MovieEntity movie) {
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
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 140,
                width: 120,
                color: Colors.grey.shade800,
                child: movie.banniere.isNotEmpty
                    ? Image.network(
                        movie.banniere,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.movie,
                              color: Colors.grey.shade600,
                              size: 40,
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.movie,
                          color: Colors.grey.shade600,
                          size: 40,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Titre
            Flexible(
              child: Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n) {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.search_empty,
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final movie = _searchResults[index];
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 0.7,
                    child: Container(
                      color: Colors.grey.shade800,
                      child: movie.banniere.isNotEmpty
                          ? Image.network(
                              movie.banniere,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.movie,
                                    color: Colors.grey.shade600,
                                    size: 30,
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                Icons.movie,
                                color: Colors.grey.shade600,
                                size: 30,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Titre
              Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
