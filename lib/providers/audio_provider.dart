import 'package:flutter/foundation.dart';
import '../services/audio_service.dart';

class AudioProvider with ChangeNotifier {
  final AudioService _audioService = AudioService();
  bool _isEnabled = false;
  String _selectedTrack = 'Nature'; // Default track
  double _volume = 1.0;

  AudioProvider() {
    _initializeAudio();
  }

  // Getters
  bool get isEnabled => _isEnabled;
  String get selectedTrack => _selectedTrack;
  double get volume => _volume;
  bool get isPlaying => _audioService.isPlaying();

  // Initialize audio
  Future<void> _initializeAudio() async {
    await _audioService.initialize();
  }

  // Toggle audio on/off
  Future<void> toggleAudio() async {
    _isEnabled = !_isEnabled;
    
    if (_isEnabled) {
      await _audioService.playTrack(_selectedTrack);
    } else {
      await _audioService.stop();
    }
    
    notifyListeners();
  }

  // Change track
  Future<void> changeTrack(String trackName) async {
    if (!AudioService.audioTracks.containsKey(trackName)) {
      throw Exception('Invalid track name: $trackName');
    }

    _selectedTrack = trackName;
    
    if (_isEnabled) {
      await _audioService.playTrack(trackName);
    }
    
    notifyListeners();
  }

  // Set volume
  Future<void> setVolume(double newVolume) async {
    _volume = newVolume.clamp(0.0, 1.0);
    await _audioService.setVolume(_volume);
    notifyListeners();
  }

  // Clean up resources
  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
} 