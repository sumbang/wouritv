import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wouritv/presentation/screen/auth/auth_gate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:wouritv/config/providers.dart';
import 'package:wouritv/config/setting.dart';
import 'package:wouritv/domain/entitie/contenu_entity.dart';
import 'package:wouritv/domain/entitie/lecture_entity.dart';

import 'dart:developer' as developer;

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final ContenuEntity content;
  final String movieTitle;
  final int movieId;
  final bool startFromBeginning;
  final bool isPremium; // Nouveau: indique si c'est une vidéo premium

  const VideoPlayerScreen({
    super.key,
    required this.content,
    required this.movieTitle,
    required this.movieId,
    this.startFromBeginning = false,
    this.isPremium = false, // Par défaut, vidéo gratuite
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _playerSubscription;
  StreamSubscription<YoutubeVideoState>? _positionSubscription;
  Duration _position = Duration.zero;
  bool _isControlsVisible = true;
  bool _isPlaying = false;
  bool _isInitializing = true; // État de chargement
  Timer? _progressTimer;
  Timer? _hideControlsTimer;
  Timer? _backupSaveTimer; // Sauvegarde de sécurité toutes les 60s
  LectureEntity? _currentLecture;
  int _totalWatchedTime = 0; // Temps total cumulé (ne se réinitialise jamais)
  int _lastVideoPosition = 0; // Position précédente dans la vidéo
  int _lastSavedDuration = 0;

  // Stocker la référence au use case pour l'utiliser dans dispose()
  dynamic _updateDurationUseCase;
  dynamic _completeLectureUseCase;

  @override
  void initState() {
    super.initState();

    developer.log(
      '🎬 INIT VideoPlayerScreen:\n'
      '   - startFromBeginning: ${widget.startFromBeginning}\n'
      '   - videoId: ${widget.content.videoId}\n'
      '   - lastReading: ${widget.content.lastReading}',
      name: 'VideoPlayerScreen',
    );

    // Sauvegarder la référence au use case pour pouvoir l'utiliser dans dispose()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateDurationUseCase = ref.read(updateLectureDurationUseCaseProvider);
        _completeLectureUseCase = ref.read(completeLectureUseCaseProvider);
      }
    });
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    developer.log(
      '🚀🚀🚀 DEBUT _initializePlayer 🚀🚀🚀',
      name: 'VideoPlayerScreen',
    );

    // Le videoId est directement l'ID YouTube
    String? videoId = widget.content.videoId;

    developer.log('📹 VideoId reçu: $videoId', name: 'VideoPlayerScreen');

    if (videoId == null || videoId.isEmpty) {
      developer.log(
        '❌ VideoId null ou vide - fermeture',
        name: 'VideoPlayerScreen',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID de vidéo invalide'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return;
    }

    // Vérification de la possession pour les vidéos premium
    if (widget.isPremium) {
      developer.log(
        '🔐 Contenu premium détecté - vérification de l\'achat...',
        name: 'VideoPlayerScreen',
      );

      try {
        final authService = ref.read(authServiceProvider);
        final userId = authService.currentUser?.id;

        if (userId == null) {
          developer.log(
            '❌ Utilisateur non connecté',
            name: 'VideoPlayerScreen',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Vous devez être connecté pour accéder à ce contenu premium',
                ),
                backgroundColor: Colors.red,
              ),
            );
          });
          return;
        }

        // Vérifier si l'utilisateur possède ce film premium
        final premiumService = ref.read(premiumVideoServiceProvider);
        final hasPurchased = await premiumService.hasUserPurchased(
          movieId: widget.movieId.toString(),
          userId: userId,
        );

        if (!hasPurchased) {
          developer.log(
            '❌ Utilisateur n\'a pas acheté ce contenu premium',
            name: 'VideoPlayerScreen',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Accès refusé : vous devez acheter ce contenu premium',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
          });
          return;
        }

        developer.log(
          '✅ Vérification réussie - utilisateur possède le contenu premium',
          name: 'VideoPlayerScreen',
        );
      } catch (e, stackTrace) {
        developer.log(
          '❌ Erreur lors de la vérification de l\'achat: $e',
          error: e,
          stackTrace: stackTrace,
          name: 'VideoPlayerScreen',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        });
        return;
      }
    }

    // Récupérer ou créer la lecture
    try {
      final authService = ref.read(authServiceProvider);
      final userId = authService.currentUser?.id;

      developer.log(
        '=== DEBUT INIT LECTURE ===\n'
        '   - VideoId: ${widget.content.videoId}\n'
        '   - UserId: $userId\n'
        '   - MovieId: ${widget.movieId}',
        name: 'VideoPlayerScreen',
      );

      if (userId == null) {
        developer.log(
          '❌ ECHEC: Utilisateur non connecté - lecture sans sync',
          name: 'VideoPlayerScreen',
        );
      } else if (widget.content.videoId == null ||
          widget.content.videoId!.isEmpty) {
        developer.log(
          '❌ ECHEC: VideoId invalide - lecture sans sync',
          name: 'VideoPlayerScreen',
        );
      } else {
        developer.log(
          '🚀 Appel getOrCreateLectureUseCase...',
          name: 'VideoPlayerScreen',
        );

        final getOrCreateLectureUseCase = ref.read(
          getOrCreateLectureUseCaseProvider,
        );
        _currentLecture = await getOrCreateLectureUseCase.execute(
          videoId: widget.content.videoId!,
          userId: userId,
        );

        if (_currentLecture != null) {
          _totalWatchedTime = _currentLecture!.duree;
          _lastSavedDuration = _currentLecture!.duree;

          // Si on reprend la lecture (pas depuis le début), initialiser la position
          if (!widget.startFromBeginning &&
              _currentLecture!.lastReading != null) {
            _lastVideoPosition = _timeToSeconds(_currentLecture!.lastReading!);
          }

          developer.log(
            '✅ LECTURE INITIALISEE:\n'
            '   - ID: ${_currentLecture!.id}\n'
            '   - Durée cumulée: ${_currentLecture!.duree}s\n'
            '   - Position reprise: ${_lastVideoPosition}s\n'
            '   - idmovie: ${_currentLecture!.idmovie}\n'
            '   - iduser: ${_currentLecture!.iduser}',
            name: 'VideoPlayerScreen',
          );
        } else {
          developer.log(
            '❌ ECHEC: _currentLecture est null après execute()',
            name: 'VideoPlayerScreen',
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ EXCEPTION LORS INIT LECTURE:\n'
        '   - Type: ${e.runtimeType}\n'
        '   - Message: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'VideoPlayerScreen',
      );
    }

    if (!mounted) return;

    _position = Duration(seconds: _lastVideoPosition);
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      startSeconds: widget.startFromBeginning
          ? 0
          : _lastVideoPosition.toDouble(),
      params: const YoutubePlayerParams(
        mute: false,
        enableCaption: false,
        showControls: false,
        showFullscreenButton: false,
      ),
    );
    _playerSubscription = _controller!.stream.listen((value) {
      if (!mounted) return;
      final wasPlaying = _isPlaying;
      final isNowPlaying = value.playerState == PlayerState.playing;
      setState(() => _isPlaying = isNowPlaying);
      if (wasPlaying && !isNowPlaying && _currentLecture != null) {
        unawaited(_saveProgress());
      }
    });
    _positionSubscription = _controller!.videoStateStream.listen((value) {
      if (mounted) setState(() => _position = value.position);
    });

    developer.log(
      'Position initiale du lecteur : ${_position.inSeconds}s',
      name: 'VideoPlayerScreen',
    );

    // Démarrage du timer de progression locale
    developer.log(
      '🚀 Démarrage du timer de progression locale...',
      name: 'VideoPlayerScreen',
    );
    _startProgressTimer();

    // Démarrage du timer de sauvegarde de sécurité (60s)
    _startBackupSaveTimer();

    // Démarrage du timer pour masquer les contrôles après 10 secondes
    _startHideControlsTimer();

    // Forcer l'orientation paysage pour la lecture vidéo
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Marquer l'initialisation comme terminée
    setState(() {
      _isInitializing = false;
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _hideControlsTimer?.cancel();
    _backupSaveTimer?.cancel();

    // Sauvegarder la position actuelle avant de quitter
    if (_currentLecture != null && _controller != null) {
      final currentPosition = _position.inSeconds;
      if (currentPosition != _lastSavedDuration) {
        developer.log(
          '💾 Tentative de sauvegarde finale - Position: ${currentPosition}s',
          name: 'VideoPlayerScreen',
        );
        _saveProgress()
            .then((_) {
              developer.log(
                '✅ Sauvegarde finale terminée',
                name: 'VideoPlayerScreen',
              );
            })
            .catchError((e) {
              developer.log(
                '❌ Erreur sauvegarde finale: $e',
                name: 'VideoPlayerScreen',
              );
            });
      }

      // Marquer la lecture comme terminée avec la date/heure de fermeture
      _markVideoAsCompleted();
    }

    unawaited(_playerSubscription?.cancel());
    unawaited(_positionSubscription?.cancel());
    unawaited(_controller?.close());

    // Restaurer l'orientation normale et les contrôles système
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _startProgressTimer() {
    // Timer pour mettre à jour la durée cumulée chaque seconde
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_controller != null && _isPlaying) {
        final currentPosition = _position.inSeconds;
        final positionDiff = currentPosition - _lastVideoPosition;

        // Incrémenter le temps cumulé uniquement si la lecture avance
        if (positionDiff > 0 && positionDiff < 5) {
          // Ignorer les sauts > 5s (seek)
          setState(() {
            _totalWatchedTime += positionDiff;
          });
        }

        _lastVideoPosition = currentPosition;

        // Log toutes les 10 secondes pour éviter trop de logs
        if (currentPosition % 10 == 0) {
          developer.log(
            '⏱️ Position: ${currentPosition}s | Temps cumulé: ${_totalWatchedTime}s',
            name: 'VideoPlayerScreen',
          );
        }
      }
    });

    developer.log(
      '✅ Timer de progression locale démarré (1s)',
      name: 'VideoPlayerScreen',
    );
  }

  void _startBackupSaveTimer() {
    // Timer de sécurité: sauvegarder toutes les 60s pendant la lecture
    _backupSaveTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (_currentLecture != null && _controller != null) {
        final currentPosition = _position.inSeconds;
        // Sauvegarder si la position a changé depuis la dernière sauvegarde
        if (currentPosition != _lastSavedDuration) {
          developer.log(
            '💾 Sauvegarde de sécurité (60s) - Position: ${currentPosition}s',
            name: 'VideoPlayerScreen',
          );
          _saveProgress();
        }
      }
    });

    developer.log(
      '✅ Timer de sauvegarde de sécurité démarré (60s)',
      name: 'VideoPlayerScreen',
    );
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isControlsVisible) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });

    // Si on affiche les contrôles, relancer le timer pour les masquer après 10s
    if (_isControlsVisible) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  Future<void> _saveProgress() async {
    if (_currentLecture == null || _controller == null) {
      developer.log(
        '⚠️ Aucune lecture en cours - skip save',
        name: 'VideoPlayerScreen',
      );
      return;
    }

    try {
      final currentPosition = _position.inSeconds;

      developer.log(
        '💾 DEBUT SAUVEGARDE:\n'
        '   - Lecture ID: ${_currentLecture!.id}\n'
        '   - Position actuelle: ${currentPosition}s\n'
        '   - Temps cumulé local: ${_totalWatchedTime}s\n'
        '   - Dernière sauvegarde: ${_lastSavedDuration}s',
        name: 'VideoPlayerScreen',
      );

      // Utiliser la référence stockée ou lire depuis ref si toujours monté
      final updateDurationUseCase =
          _updateDurationUseCase ??
          ref.read(updateLectureDurationUseCaseProvider);
      await updateDurationUseCase.execute(
        lectureId: _currentLecture!.id,
        duree: currentPosition, // Sauvegarder uniquement la position actuelle
      );
      _lastSavedDuration =
          currentPosition; // Mettre à jour avec la position sauvegardée

      developer.log(
        '✅ SAUVEGARDE REUSSIE: Position ${currentPosition}s sauvegardée - Lecture ID: ${_currentLecture!.id}',
        name: 'VideoPlayerScreen',
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ ERREUR SAUVEGARDE:\n'
        '   - Lecture ID: ${_currentLecture?.id}\n'
        '   - Position: ${_position.inSeconds}s\n'
        '   - Erreur: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'VideoPlayerScreen',
      );
    }
  }

  Future<void> _markVideoAsCompleted() async {
    if (_currentLecture == null) return;

    try {
      final completeLectureUseCase = _completeLectureUseCase;
      if (completeLectureUseCase == null) return;
      final currentPosition = _position.inSeconds;

      developer.log(
        '🏁 Marquage lecture terminée:'
        '   - Lecture ID: ${_currentLecture!.id}\n'
        '   - Position finale: ${currentPosition}s\n'
        '   - Date/heure de fin: ${DateTime.now()}',
        name: 'VideoPlayerScreen',
      );

      await completeLectureUseCase.execute(
        lectureId: _currentLecture!.id,
        finalDuration: currentPosition, // Position où l'utilisateur a quitté
      );

      developer.log(
        '✅ Vidéo marquée comme terminée avec date/heure de fermeture',
        name: 'VideoPlayerScreen',
      );
    } catch (e) {
      developer.log(
        '❌ Erreur lors de la finalisation: $e',
        name: 'VideoPlayerScreen',
      );
    }
  }

  void _seekTo(Duration position) {
    _lastVideoPosition = position.inSeconds;
    setState(() => _position = position);
    unawaited(_controller!.seekTo(seconds: position.inMilliseconds / 1000));
  }

  void _seekBackward() {
    final currentPosition = _position;
    final newPosition = currentPosition - const Duration(seconds: 15);
    _seekTo(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  void _seekForward() {
    final currentPosition = _position;
    final duration = _controller!.metadata.duration;
    final newPosition = currentPosition + const Duration(seconds: 15);
    _seekTo(newPosition < duration ? newPosition : duration);
  }

  int _timeToSeconds(String time) {
    final parts = time.split(':');
    if (parts.length == 3) {
      return int.parse(parts[0]) * 3600 +
          int.parse(parts[1]) * 60 +
          int.parse(parts[2]);
    } else if (parts.length == 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    return 0;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    // Pendant l'initialisation, afficher un loader
    if (_isInitializing || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Setting.primaryColor),
              const SizedBox(height: 16),
              const Text(
                'Chargement de la vidéo...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: YoutubePlayer(
          controller: _controller!,
          autoFullScreen: false,
          enableFullScreenOnVerticalDrag: false,
          builder: (context, player, controller) => Stack(
            fit: StackFit.expand,
            children: [
              player,

              // Zone de tap pour afficher/masquer les contrôles
              GestureDetector(
                onTap: _toggleControls,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),

              // Contrôles personnalisés
              if (_isControlsVisible)
                AnimatedOpacity(
                  opacity: _isControlsVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header avec titre et bouton fermer
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.movieTitle,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (widget.content.title.isNotEmpty)
                                        Text(
                                          widget.content.title,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Contrôles centraux
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Retour 15s
                            IconButton(
                              icon: const Icon(
                                Icons.replay_10,
                                color: Colors.white,
                                size: 48,
                              ),
                              onPressed: _seekBackward,
                            ),
                            const SizedBox(width: 32),
                            // Play/Pause
                            IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 64,
                              ),
                              onPressed: () {
                                if (_isPlaying) {
                                  unawaited(_controller!.pauseVideo());
                                } else {
                                  unawaited(_controller!.playVideo());
                                }
                              },
                            ),
                            const SizedBox(width: 32),
                            // Avance 15s
                            IconButton(
                              icon: const Icon(
                                Icons.forward_10,
                                color: Colors.white,
                                size: 48,
                              ),
                              onPressed: _seekForward,
                            ),
                          ],
                        ),

                        // Barre de progression et temps
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Barre de progression
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 12,
                                    ),
                                    activeTrackColor: Setting.primaryColor,
                                    inactiveTrackColor: Colors.white.withValues(
                                      alpha: 0.3,
                                    ),
                                    thumbColor: Setting.primaryColor,
                                    overlayColor: Setting.primaryColor
                                        .withValues(alpha: 0.3),
                                  ),
                                  child: Slider(
                                    value: _position.inSeconds.toDouble().clamp(
                                      0.0,
                                      _controller!.metadata.duration.inSeconds
                                          .toDouble()
                                          .clamp(1.0, double.infinity),
                                    ),
                                    min: 0.0,
                                    max: _controller!
                                        .metadata
                                        .duration
                                        .inSeconds
                                        .toDouble()
                                        .clamp(1.0, double.infinity),
                                    onChanged: (value) {
                                      _seekTo(Duration(seconds: value.toInt()));
                                    },
                                  ),
                                ),
                                // Temps
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(
                                        _controller!.metadata.duration,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
