import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../services/audio_service.dart';

class AudioProvider with ChangeNotifier, WidgetsBindingObserver {
  final AudioService _audioService = AudioService();
  bool _isEnabled = false;
  String _selectedTrack = 'Nature'; // Default track
  double _volume = 1.0;
  bool _wasPlayingBeforeBackground = false;
  bool _isInitialized = false;

  AudioProvider() {
    _initializeAudio();
    WidgetsBinding.instance.addObserver(this);
  }

  // Getters
  bool get isEnabled => _isEnabled;
  String get selectedTrack => _selectedTrack;
  double get volume => _volume;
  bool get isPlaying => _audioService.isPlaying();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Store the current playing state and pause the audio
        _wasPlayingBeforeBackground = isPlaying;
        if (_wasPlayingBeforeBackground) {
          _audioService.pause();
        }
        break;
      case AppLifecycleState.resumed:
        // Resume audio if it was playing before
        if (_wasPlayingBeforeBackground && _isEnabled) {
          _audioService.resume();
        }
        break;
      default:
        break;
    }
  }

  // Initialize audio
  Future<void> _initializeAudio() async {
    if (_isInitialized) return;
    await _audioService.initialize();
    _isInitialized = true;
  }

  // Toggle audio on/off
  Future<void> toggleAudio() async {
    if (!_isInitialized) await _initializeAudio();
    
    setState(() {
      _isEnabled = !_isEnabled;
    });
    
    try {
      if (_isEnabled) {
        await _audioService.playTrack(_selectedTrack);
      } else {
        await _audioService.stop();
      }
    } catch (e) {
      debugPrint('Error toggling audio: $e');
      setState(() {
        _isEnabled = !_isEnabled; // Revert state on error
      });
    }
  }

  // Change track
  Future<void> changeTrack(String trackName) async {
    if (!_isInitialized) await _initializeAudio();
    if (!AudioService.audioTracks.containsKey(trackName)) {
      throw Exception('Invalid track name: $trackName');
    }

    setState(() {
      _selectedTrack = trackName;
    });
    
    try {
      if (_isEnabled) {
        await _audioService.playTrack(trackName);
      }
    } catch (e) {
      debugPrint('Error changing track: $e');
    }
  }

  // Set volume
  Future<void> setVolume(double newVolume) async {
    if (!_isInitialized) await _initializeAudio();
    setState(() {
      _volume = newVolume.clamp(0.0, 1.0);
    });
    
    try {
      await _audioService.setVolume(_volume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  // Clean up resources
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioService.dispose();
    super.dispose();
  }
} 