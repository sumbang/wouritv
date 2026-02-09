import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wouritv/config/app_theme.dart';
import 'package:wouritv/config/providers.dart';
import 'package:wouritv/config/setting.dart';
import 'package:wouritv/domain/entitie/contenu_entity.dart';
import 'package:wouritv/domain/entitie/movie_entity.dart';
import 'package:wouritv/domain/entitie/movie_content_entity.dart';
import 'dart:developer' as developer;
import 'package:wouritv/presentation/screen/auth/auth_gate.dart';
import 'package:wouritv/presentation/screen/movie/video_player_screen.dart';

import 'package:wouritv/l10n/app_localizations.dart';

class MovieDetailScreen extends ConsumerStatefulWidget {
  final MovieEntity movie;

  const MovieDetailScreen({
    super.key,
    required this.movie,
  });

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
  bool _isDescriptionExpanded = false;
  static const int _maxDescriptionWords = 10; // Changé de caractères à mots
  
  MovieWithContentsEntity? _movieDetails;
  bool _isLoadingDetails = true;
  bool? _userRecommendation; // null = pas d'avis, true = j'aime, false = je n'aime pas
  List<MovieEntity> _suggestions = [];
  bool _isLoadingSuggestions = true;

  @override
  void initState() {
    super.initState();
    // Réactiver le chargement des détails
    _loadMovieDetails();
  }

  Future<void> _loadMovieDetails() async {
    try {
      developer.log('🎬 Chargement des détails du film: ${widget.movie.id}', name: 'MovieDetailScreen');
      developer.log('🔍 Type de l\'ID: ${widget.movie.id.runtimeType}', name: 'MovieDetailScreen');
      
      final getMovieByIdUseCase = ref.read(getMovieByIdUseCaseProvider);
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      
      // Convertir l'ID en String
      final movieId = widget.movie.id.toString();
      developer.log('📝 ID converti: $movieId', name: 'MovieDetailScreen');
      developer.log('👤 Utilisateur connecté: ${user?.id ?? "Aucun"}', name: 'MovieDetailScreen');
      
      final movieDetails = await getMovieByIdUseCase.execute(movieId, userId: user?.id);
      
      developer.log('✅ Détails chargés: ${movieDetails.movie.title}', name: 'MovieDetailScreen');
      developer.log('📦 Nombre de contenus: ${movieDetails.contents.length}', name: 'MovieDetailScreen');
      developer.log('📋 Film dans la liste: ${movieDetails.isInList}', name: 'MovieDetailScreen');
      developer.log('👍 Recommandation utilisateur: ${movieDetails.userRecommendation}', name: 'MovieDetailScreen');
      developer.log('📦 Duree de lecture : ${movieDetails.contents.first.lastReading}', name: 'MovieDetailScreen');
      
      if (mounted) {
        setState(() {
          _movieDetails = movieDetails;
          _userRecommendation = movieDetails.userRecommendation;
          _isLoadingDetails = false;
        });
        
        // Charger les suggestions après avoir déterminé le type
        _loadSuggestions();
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Erreur lors du chargement des détails',
        error: e,
        stackTrace: stackTrace,
        name: 'MovieDetailScreen',
      );
      
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
        
        // Ne pas afficher de SnackBar, juste logger l'erreur
        developer.log('Continuer sans les contenus', name: 'MovieDetailScreen');
      }
    }
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Convertir le temps HH:MM:SS ou MM:SS en secondes
  int _timeToSeconds(String time) {
    final parts = time.split(':');
    
    if (parts.length == 3) {
      // Format HH:MM:SS
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = int.tryParse(parts[2]) ?? 0;
      return hours * 3600 + minutes * 60 + seconds;
    } else if (parts.length == 2) {
      // Format MM:SS
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return minutes * 60 + seconds;
    }
    
    return 0; // Format invalide
  }

  /// Formater les secondes en temps lisible (ex: "1h 30min" ou "45min")
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  /// Afficher un dialogue pour choisir entre continuer et reprendre depuis le début
  Future<bool> _showPlayDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resume_reading),
        content: Text(l10n.resume_reading_question),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.from_beginning),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Setting.primaryColor,
            ),
            child: Text(l10n.continue_watching),
          ),
        ],
      ),
    );
    
    return result ?? false; // Par défaut, continuer
  }

  /// Lancer la lecture d'un contenu
  Future<void> _playContent(ContenuEntity content, {bool shouldAskResume = false}) async {
    bool continueFromLastPosition = true;
    
    if (shouldAskResume && content.lastReading != null) {
      continueFromLastPosition = await _showPlayDialog(context);
    }
    
    if (!mounted) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          content: content,
          movieTitle: widget.movie.title,
          movieId: int.parse(widget.movie.id),
          startFromBeginning: !continueFromLastPosition,
        ),
      ),
    );
  }

  /// Charger les suggestions de films/séries similaires
  Future<void> _loadSuggestions() async {
    try {
      final isSeries = _movieDetails != null && _movieDetails!.contents.length > 1;
      developer.log('🎯 Chargement de suggestions - Type: ${isSeries ? "Série" : "Film"}', name: 'MovieDetailScreen');
      
      final getRandomMoviesUseCase = ref.read(getRandomMoviesUseCaseProvider);
      final allMovies = await getRandomMoviesUseCase.execute(limit: 50);
      
      // Filtrer selon le type (série ou film) et exclure le film actuel
      final filteredMovies = allMovies.where((m) {
        // Exclure le film actuel
        if (m.id == widget.movie.id) return false;
        
        // Note: Comme on ne peut pas déterminer si c'est une série sans charger les contenus,
        // on affiche simplement des films aléatoires
        return true;
      }).take(10).toList();
      
      if (mounted) {
        setState(() {
          _suggestions = filteredMovies;
          _isLoadingSuggestions = false;
        });
        developer.log('✅ ${filteredMovies.length} suggestions chargées', name: 'MovieDetailScreen');
      }
    } catch (e) {
      developer.log('❌ Erreur lors du chargement des suggestions: $e', name: 'MovieDetailScreen');
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  /// Ajouter ou retirer un film de la liste de l'utilisateur
  Future<void> _toggleMovieInList() async {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text(AppLocalizations.of(context)!.connexion_required_liste),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final movieId = widget.movie.id.toString();
    final userId = user.id;
    final isCurrentlyInList = _movieDetails?.isInList ?? false;

    try {
      if (isCurrentlyInList) {
        // Retirer de la liste
        final removeUseCase = ref.read(removeMovieFromListUseCaseProvider);
        await removeUseCase.execute(movieId: movieId, userId: userId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.liste_remove),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Ajouter à la liste
        final addUseCase = ref.read(addMovieToListUseCaseProvider);
        await addUseCase.execute(movieId: movieId, userId: userId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.liste_add),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      
      // Recharger les détails pour mettre à jour isInList
      await _loadMovieDetails();
    } catch (e, stackTrace) {
      developer.log(
        '❌ Erreur lors de la gestion de la liste',
        error: e,
        stackTrace: stackTrace,
        name: 'MovieDetailScreen',
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

  /// Gérer les recommandations (J'aime / Je n'aime pas)
  Future<void> _handleRecommendation(bool isLike) async {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.connexion_required_liste),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final movieId = widget.movie.id.toString();
    final userId = user.id;
    final wasLiked = _userRecommendation == true;
    final wasDisliked = _userRecommendation == false;

    try {
      // Si l'utilisateur clique sur le même bouton, on retire la recommandation
      if ((isLike && wasLiked) || (!isLike && wasDisliked)) {
        final movieService = ref.read(movieServiceProvider);
        await movieService.removeMovieRecommendation(
          movieId: movieId,
          userId: userId,
        );
        
        if (mounted) {
          setState(() {
            _userRecommendation = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.recommand_add),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Sinon, on enregistre ou met à jour la recommandation
        final recommendUseCase = ref.read(recommendMovieUseCaseProvider);
        await recommendUseCase.execute(
          movieId: movieId,
          userId: userId,
          recommend: isLike,
        );
        
        if (mounted) {
          setState(() {
            _userRecommendation = isLike;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isLike 
                  ? AppLocalizations.of(context)!.recommand_add
                  : AppLocalizations.of(context)!.recommand_delete,
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Erreur lors de la gestion de la recommandation',
        error: e,
        stackTrace: stackTrace,
        name: 'MovieDetailScreen',
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

  @override
  Widget build(BuildContext context) {

    final l10n = AppLocalizations.of(context)!;

    // Utiliser les détails chargés ou le movie initial
    final movie = _movieDetails?.movie ?? widget.movie;
    final isDarkMode = AppTheme.isDarkMode(context);
    
    // Déterminer si c'est une série (plusieurs contenus) ou un film
    final isSeries = _movieDetails != null && _movieDetails!.contents.length > 1;
    
    // Récupérer la durée du premier contenu s'il existe
    final firstContentDuration = _movieDetails?.contents.isNotEmpty == true 
        ? _movieDetails!.contents.first.duree 
        : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Bannière avec effet de dégradé
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.38,
            pinned: true,
            stretch: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Setting.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image de bannière
                  if (movie.banniere != null)
                    Image.network(
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
                          child: Icon(Icons.movie, size: 80, color: Colors.white54),
                        ),
                      ),
                    )
                  else
                    Container(
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
                        child: Icon(Icons.movie, size: 80, color: Colors.white54),
                      ),
                    ),
                  // Dégradé vers le fond
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            isDarkMode ? Colors.black : Colors.white,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenu du film
          SliverToBoxAdapter(
            child: _isLoadingDetails
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre du film
                        Text(
                          _capitalizeWords(movie.title ?? l10n.no_title),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Informations de classification en scroll horizontal
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              if (movie.categorie != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildInfoChip(
                                    icon: Icons.category,
                                    label: movie.categorie!,
                                    isDarkMode: isDarkMode,
                                  ),
                                ),
                              if (movie.paiement != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildInfoChip(
                                    icon: movie.paiement == 'OUI' 
                                        ? Icons.lock 
                                        : Icons.lock_open,
                                    label: movie.paiement == 'OUI' ? l10n.premium : l10n.free,
                                    isDarkMode: isDarkMode,
                                  ),
                                ),
                              // Ajouter la durée uniquement pour les films (pas pour les séries)
                              if (!isSeries && firstContentDuration != null && firstContentDuration.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildInfoChip(
                                    icon: Icons.access_time,
                                    label: firstContentDuration,
                                    isDarkMode: isDarkMode,
                                  ),
                                ),
                              if (movie.prix != null && movie.prix! > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildInfoChip(
                                    icon: Icons.attach_money,
                                    label: '${movie.prix} FCFA',
                                    isDarkMode: isDarkMode,
                                  ),
                                ),
                              // Boutons d'action (icônes uniquement)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildIconButton(
                                  icon: (_movieDetails?.isInList ?? false) ? Icons.remove : Icons.add,
                                  onPressed: _toggleMovieInList,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildIconButton(
                                  icon: Icons.thumb_up,
                                  onPressed: () => _handleRecommendation(true),
                                  isDarkMode: isDarkMode,
                                  isActive: _userRecommendation == true,
                                ),
                              ),
                              _buildIconButton(
                                icon: Icons.thumb_down,
                                onPressed: () => _handleRecommendation(false),
                                isDarkMode: isDarkMode,
                                isActive: _userRecommendation == false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Bouton lecture - Uniquement pour les films (1 seul contenu)
                        if (!isSeries) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _movieDetails != null && _movieDetails!.contents.isNotEmpty
                                  ? () {
                                      developer.log('Lecture du film: ${movie.title}', name: 'MovieDetailScreen');
                                      final content = _movieDetails!.contents.first;
                                      final hasProgress = content.lastReading != null;
                                      _playContent(content, shouldAskResume: hasProgress);
                                    }
                                  : null,
                              icon: const Icon(Icons.play_arrow, size: 28),
                              label: Text(
                                l10n.look,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Setting.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          
                          // Barre de progression si lastReading existe
                          if (_movieDetails!.contents.isNotEmpty && _movieDetails!.contents.first.lastReading != null) ...[
                            const SizedBox(height: 12),
                            _buildProgressBar(_movieDetails!.contents.first, l10n),
                          ],
                          
                          const SizedBox(height: 24),
                        ],

                        // Liste des contenus/épisodes - Uniquement pour les séries
                        if (isSeries && _movieDetails!.contents.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.episode,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                '${_movieDetails!.contents.length} ${_movieDetails!.contents.length > 1 ? 'épisodes' : 'épisode'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 220, // Augmenter la hauteur pour accommoder les titres longs
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _movieDetails!.contents.length,
                              itemBuilder: (context, index) {
                                final content = _movieDetails!.contents[index];
                                return GestureDetector(
                                  onTap: () {
                                    developer.log('Lecture du contenu: ${content.id}', name: 'MovieDetailScreen');
                                    final hasProgress = content.lastReading != null;
                                    _playContent(content, shouldAskResume: hasProgress);
                                  },
                                  child: Container(
                                    width: 140,
                                    margin: EdgeInsets.only(
                                      left: index == 0 ? 0 : 12,
                                      right: index == _movieDetails!.contents.length - 1 ? 0 : 0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Miniature de l'épisode
                                        Container(
                                          width: 140,
                                          height: 105,
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
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: movie.banniere != null
                                                    ? Image.network(
                                                        movie.banniere!,
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: double.infinity,
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
                                                            child: Icon(Icons.play_circle_outline, size: 40, color: Colors.white54),
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
                                                          child: Icon(Icons.play_circle_outline, size: 40, color: Colors.white54),
                                                        ),
                                                      ),
                                              ),
                                              // Icône play au centre
                                              const Center(
                                                child: Icon(
                                                  Icons.play_circle_filled,
                                                  size: 48,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              
                                              // Barre de progression en bas si lastReading existe
                                              if (content.lastReading != null && content.duree != null)
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: Container(
                                                    height: 4,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withOpacity(0.3),
                                                      borderRadius: const BorderRadius.only(
                                                        bottomLeft: Radius.circular(12),
                                                        bottomRight: Radius.circular(12),
                                                      ),
                                                    ),
                                                    child: FractionallySizedBox(
                                                      alignment: Alignment.centerLeft,
                                                      widthFactor: _timeToSeconds(content.lastReading!) / 
                                                          _timeToSeconds(content.duree!),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: Setting.primaryColor,
                                                          borderRadius: const BorderRadius.only(
                                                            bottomLeft: Radius.circular(12),
                                                            bottomRight: Radius.circular(12),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Titre de l'épisode avec durée intégrée
                                        Expanded(
                                          child: Text(
                                            content.duree != null && content.duree!.isNotEmpty
                                                ? '${content.title ?? '${l10n.episode ?? 'Episode'} ${index + 1}'} (${content.duree})'
                                                : content.title ?? '${l10n.episode ?? 'Episode'} ${index + 1}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDarkMode ? Colors.white : Colors.black,
                                              height: 1.2,
                                            ),
                                          ),
                                        ),

                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        ],

                        // Description
                        if (movie.description != null && movie.description!.isNotEmpty) ...[
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDescription(movie.description!, isDarkMode, l10n),
                          const SizedBox(height: 24),
                        ],

                        // Section "Ceci pourrait vous intéresser"
                        Text(
                          l10n.suggestion,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        if (_isLoadingSuggestions)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_suggestions.isEmpty)
                           Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                l10n.no_suggestion,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _suggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion = _suggestions[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => MovieDetailScreen(movie: suggestion),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 140,
                                    margin: EdgeInsets.only(
                                      left: index == 0 ? 0 : 12,
                                      right: index == _suggestions.length - 1 ? 0 : 0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Miniature
                                        Container(
                                          width: 140,
                                          height: 160,
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
                                            child: suggestion.banniere != null
                                                ? Image.network(
                                                    suggestion.banniere!,
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
                                        // Titre
                                        Text(
                                          _capitalizeWords(suggestion.title ?? (l10n.no_title ?? 'Sans titre')),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode ? Colors.white : Colors.black,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDarkMode,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive 
              ? Setting.primaryColor 
              : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive 
              ? Colors.white 
              : (isDarkMode ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildDescription(String description, bool isDarkMode, AppLocalizations l10n) {
    // Nettoyer la description : supprimer les sauts de ligne multiples et espaces multiples
    final cleanedDescription = description
        .replaceAll(RegExp(r'\n+'), ' ')  // Remplacer les sauts de ligne par des espaces
        .replaceAll(RegExp(r'\s+'), ' ')  // Remplacer les espaces multiples par un seul espace
        .trim();  // Supprimer les espaces au début et à la fin
    
    final words = cleanedDescription.split(' ');
    final shouldTruncate = words.length > _maxDescriptionWords;
    
    final displayText = _isDescriptionExpanded || !shouldTruncate
        ? cleanedDescription
        : '${words.take(_maxDescriptionWords).join(' ')}...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayText,
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
          ),
        ),
        if (shouldTruncate) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Text(
              _isDescriptionExpanded ? l10n.show_less : l10n.show_more,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Setting.primaryColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar(ContenuEntity content, AppLocalizations l10n) {
    developer.log('Construction de la barre de progression pour le contenu: ${content.id}', name: 'MovieDetailScreen');
    if (content.lastReading == null || content.duree == null) {
      developer.log('Aucune progression à afficher pour le contenu: ${content.id}', name: 'MovieDetailScreen');
      return const SizedBox.shrink();
    }

    
    developer.log('Calcul de la progression pour le contenu: ${content.id} - lastReading: ${content.lastReading}, duree: ${content.duree}', name: 'MovieDetailScreen');
  
    final watchedSeconds = _timeToSeconds(content.lastReading!);
    final totalSeconds = _timeToSeconds(content.duree!); // Utiliser _timeToSeconds au lieu de int.tryParse
  

    if (totalSeconds == 0) {
      developer.log('Durée totale nulle pour le contenu: ${content.id}', name: 'MovieDetailScreen');
      return const SizedBox.shrink();
    }

    final progress = watchedSeconds / totalSeconds;
    final remainingSeconds = totalSeconds - watchedSeconds;
    
    developer.log('Progression: $progress, Secondes restantes: $remainingSeconds pour le contenu: ${content.id}', name: 'MovieDetailScreen');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Setting.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_formatDuration(remainingSeconds)} ${l10n.remaining}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
