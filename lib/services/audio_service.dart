import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;
  String? _currentTrack;

  // Track names and their corresponding asset paths
  static const Map<String, String> audioTracks = {
    'Nature': 'assets/audio/mountains.mp3',
    'Ambient': 'assets/audio/ambient.mp3',
    'Piano': 'assets/audio/piano.mp3',
  };

  // Initialize the audio service
  Future<void> initialize() async {
    if (!_isInitialized) {
      // Set up any initial configuration here
      await _player.setLoopMode(LoopMode.one); // Enable looping by default
      _isInitialized = true;
    }
  }

  // Play a specific track
  Future<void> playTrack(String trackName) async {
    if (!_isInitialized) await initialize();
    
    try {
      if (_currentTrack != trackName) {
        final trackPath = audioTracks[trackName];
        if (trackPath == null) throw Exception('Track not found: $trackName');
        
        // Stop current playback if any
        await _player.stop();
        
        // Load and play the new track
        await _player.setAsset(trackPath);
        _currentTrack = trackName;
      }
      
      await _player.play();
    } catch (e) {
      print('Error playing audio track: $e');
      rethrow;
    }
  }

  // Stop playback
  Future<void> stop() async {
    await _player.stop();
  }

  // Pause playback
  Future<void> pause() async {
    await _player.pause();
  }

  // Resume playback
  Future<void> resume() async {
    await _player.play();
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  // Get current track name
  String? getCurrentTrack() => _currentTrack;

  // Check if audio is playing
  bool isPlaying() => _player.playing;

  // Dispose the audio player
  Future<void> dispose() async {
    await _player.dispose();
    _isInitialized = false;
    _currentTrack = null;
  }
} 