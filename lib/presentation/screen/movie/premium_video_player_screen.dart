import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wouritv/config/providers.dart';
import 'package:wouritv/domain/entitie/contenu_entity.dart';
import 'package:wouritv/domain/entitie/lecture_entity.dart';
import 'dart:developer' as developer;

import 'package:wouritv/presentation/screen/auth/auth_gate.dart';

class PremiumVideoPlayerScreen extends ConsumerStatefulWidget {
  final ContenuEntity content;
  final String movieTitle;
  final int movieId;
  final String cloudFrontUrl;
  final bool startFromBeginning;

  const PremiumVideoPlayerScreen({
    super.key,
    required this.content,
    required this.movieTitle,
    required this.movieId,
    required this.cloudFrontUrl,
    this.startFromBeginning = false,
  });

  @override
  ConsumerState<PremiumVideoPlayerScreen> createState() => _PremiumVideoPlayerScreenState();
}

class _PremiumVideoPlayerScreenState extends ConsumerState<PremiumVideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitializing = true;
  Timer? _progressTimer;
  Timer? _backupSaveTimer;
  LectureEntity? _currentLecture;
  int _totalWatchedTime = 0;
  int _lastVideoPosition = 0;
  int _lastSavedDuration = 0;
  dynamic _updateDurationUseCase;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initializePlayer() async {
    try {
      developer.log('🎬 Initialisation lecteur premium: ${widget.cloudFrontUrl}', name: 'PremiumVideoPlayer');

      // Récupérer ou créer la lecture
      final authService = ref.read(authServiceProvider);
      final userId = authService.currentUser?.id;
      
      developer.log('👤 User ID: $userId', name: 'PremiumVideoPlayer');
      
      if (userId != null && widget.content.videoId != null && widget.content.videoId!.isNotEmpty) {
        developer.log('📊 Récupération de la lecture...', name: 'PremiumVideoPlayer');
        final getOrCreateLectureUseCase = ref.read(getOrCreateLectureUseCaseProvider);
        _currentLecture = await getOrCreateLectureUseCase.execute(
          videoId: widget.content.videoId!,
          userId: userId,
        );
        
        if (_currentLecture != null) {
          _totalWatchedTime = _currentLecture!.duree;
          _lastSavedDuration = _currentLecture!.duree;
          
          if (!widget.startFromBeginning && _currentLecture!.lastReading != null) {
            _lastVideoPosition = _timeToSeconds(_currentLecture!.lastReading!);
          }
          
          developer.log('✅ Lecture initialisée - Durée: ${_currentLecture!.duree}s, Position: ${_lastVideoPosition}s', 
            name: 'PremiumVideoPlayer');
        }
      }

      // Initialiser le lecteur vidéo
      developer.log('🎥 Création VideoPlayerController...', name: 'PremiumVideoPlayer');
      developer.log('🔗 URL: ${widget.cloudFrontUrl}', name: 'PremiumVideoPlayer');
      
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.cloudFrontUrl),
      );

      developer.log('⏳ Initialisation VideoPlayerController (timeout 30s)...', name: 'PremiumVideoPlayer');
      
      // Ajouter un timeout pour éviter de bloquer indéfiniment
      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('La vidéo met trop de temps à charger. Vérifiez que le fichier existe sur S3/CloudFront.');
        },
      );
      
      developer.log('✅ VideoPlayerController initialisé', name: 'PremiumVideoPlayer');
      developer.log('📺 Taille vidéo: ${_videoPlayerController!.value.size}', name: 'PremiumVideoPlayer');
      developer.log('⏱️ Durée vidéo: ${_videoPlayerController!.value.duration}', name: 'PremiumVideoPlayer');

      // Se positionner à la dernière position si nécessaire
      if (_lastVideoPosition > 0 && !widget.startFromBeginning) {
        developer.log('⏩ Positionnement à ${_lastVideoPosition}s...', name: 'PremiumVideoPlayer');
        await _videoPlayerController!.seekTo(Duration(seconds: _lastVideoPosition));
      }

      // Initialiser Chewie (contrôles de lecture)
      developer.log('🎮 Création ChewieController...', name: 'PremiumVideoPlayer');
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white70,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.red),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          developer.log('❌ Erreur Chewie: $errorMessage', name: 'PremiumVideoPlayer');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Erreur de lecture',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      developer.log('✅ ChewieController créé', name: 'PremiumVideoPlayer');

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        developer.log('✅ Interface mise à jour - Lecteur prêt', name: 'PremiumVideoPlayer');
      }

      // Démarrer les timers de suivi
      _startProgressTimer();
      _startBackupSaveTimer();

      developer.log('✅ Lecteur premium initialisé avec succès', name: 'PremiumVideoPlayer');

    } catch (e, stackTrace) {
      developer.log('❌ Erreur initialisation lecteur: $e', 
        error: e, stackTrace: stackTrace, name: 'PremiumVideoPlayer');
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_videoPlayerController != null && _videoPlayerController!.value.isPlaying) {
        final currentPosition = _videoPlayerController!.value.position.inSeconds;
        
        if (currentPosition > _lastVideoPosition) {
          final increment = currentPosition - _lastVideoPosition;
          _totalWatchedTime += increment;
          _lastVideoPosition = currentPosition;
          
          developer.log('⏱️ Progression: +${increment}s (total: ${_totalWatchedTime}s)', 
            name: 'PremiumVideoPlayer');
          
          _saveProgress();
        }
      }
    });
  }

  void _startBackupSaveTimer() {
    _backupSaveTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (_totalWatchedTime > _lastSavedDuration) {
        developer.log('💾 Sauvegarde automatique (60s)', name: 'PremiumVideoPlayer');
        _saveProgress();
      }
    });
  }

  Future<void> _saveProgress() async {
    if (_currentLecture == null || _totalWatchedTime <= _lastSavedDuration) {
      return;
    }

    try {
      _updateDurationUseCase ??= ref.read(updateLectureDurationUseCaseProvider);
      
      final currentPosition = _videoPlayerController?.value.position.inSeconds ?? 0;
      final formattedTime = _formatTime(Duration(seconds: currentPosition));
      
      await _updateDurationUseCase.execute(
        lectureId: _currentLecture!.id!,
        newDuree: _totalWatchedTime,
        lastReading: formattedTime,
      );
      
      _lastSavedDuration = _totalWatchedTime;
      
      developer.log('💾 Progression sauvegardée: ${_totalWatchedTime}s @ $formattedTime', 
        name: 'PremiumVideoPlayer');
      
    } catch (e) {
      developer.log('❌ Erreur sauvegarde: $e', name: 'PremiumVideoPlayer');
    }
  }

  int _timeToSeconds(String time) {
    try {
      final parts = time.split(':');
      if (parts.length == 3) {
        return int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60 + int.parse(parts[2]);
      }
    } catch (e) {
      developer.log('❌ Erreur conversion temps: $e', name: 'PremiumVideoPlayer');
    }
    return 0;
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  @override
  void dispose() {
    _saveProgress();
    _progressTimer?.cancel();
    _backupSaveTimer?.cancel();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isInitializing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Chargement de la vidéo premium...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            : _chewieController != null
                ? Stack(
                    children: [
                      Center(
                        child: Chewie(controller: _chewieController!),
                      ),
                      Positioned(
                        top: 40,
                        left: 16,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        left: 0,
                        right: 0,
                        child: Text(
                          widget.movieTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Text(
                      'Erreur de chargement de la vidéo',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
      ),
    );
  }
}
