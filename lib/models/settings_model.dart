enum SlideshowInterval { 
  fiveSeconds(5), 
  tenSeconds(10), 
  thirtySeconds(30);

  final int seconds;
  const SlideshowInterval(this.seconds);
}

enum AudioTrack {
  nature('Nature', 'assets/audio/nature.mp3'),
  ambient('Ambient', 'assets/audio/ambient.mp3'),
  piano('Piano', 'assets/audio/piano.mp3');

  final String displayName;
  final String assetPath;
  const AudioTrack(this.displayName, this.assetPath);
}

class Settings {
  final SlideshowInterval slideshowInterval;
  final bool isAudioEnabled;
  final AudioTrack selectedTrack;

  const Settings({
    this.slideshowInterval = SlideshowInterval.tenSeconds,
    this.isAudioEnabled = false,
    this.selectedTrack = AudioTrack.nature,
  });

  Settings copyWith({
    SlideshowInterval? slideshowInterval,
    bool? isAudioEnabled,
    AudioTrack? selectedTrack,
  }) {
    return Settings(
      slideshowInterval: slideshowInterval ?? this.slideshowInterval,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      selectedTrack: selectedTrack ?? this.selectedTrack,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slideshowInterval': slideshowInterval.seconds,
      'isAudioEnabled': isAudioEnabled,
      'selectedTrack': selectedTrack.name,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      slideshowInterval: SlideshowInterval.values.firstWhere(
        (interval) => interval.seconds == json['slideshowInterval'],
        orElse: () => SlideshowInterval.tenSeconds,
      ),
      isAudioEnabled: json['isAudioEnabled'] ?? false,
      selectedTrack: AudioTrack.values.firstWhere(
        (track) => track.name == json['selectedTrack'],
        orElse: () => AudioTrack.nature,
      ),
    );
  }
} 