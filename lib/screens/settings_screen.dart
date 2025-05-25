import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../providers/audio_provider.dart';
import '../services/audio_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer2<SettingsProvider, AudioProvider>(
        builder: (context, settingsProvider, audioProvider, child) {
          final settings = settingsProvider.settings;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Slideshow Interval'),
                  subtitle: Text('${settings.slideshowInterval.seconds} seconds'),
                  trailing: DropdownButton<SlideshowInterval>(
                    value: settings.slideshowInterval,
                    onChanged: (SlideshowInterval? newValue) {
                      if (newValue != null) {
                        settingsProvider.updateSlideshowInterval(newValue);
                      }
                    },
                    items: SlideshowInterval.values.map((interval) {
                      return DropdownMenuItem(
                        value: interval,
                        child: Text('${interval.seconds}s'),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Background Audio'),
                      subtitle: Text(audioProvider.isEnabled ? 'On' : 'Off'),
                      value: audioProvider.isEnabled,
                      onChanged: (bool value) async {
                        await audioProvider.toggleAudio();
                      },
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        children: [
                          ListTile(
                            title: const Text('Audio Track'),
                            trailing: DropdownButton<String>(
                              value: audioProvider.selectedTrack,
                              onChanged: audioProvider.isEnabled ? (String? newValue) async {
                                if (newValue != null) {
                                  await audioProvider.changeTrack(newValue);
                                }
                              } : null,
                              items: AudioService.audioTracks.keys.map((String track) {
                                return DropdownMenuItem(
                                  value: track,
                                  child: Text(track),
                                );
                              }).toList(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Volume'),
                                Slider(
                                  value: audioProvider.volume,
                                  onChanged: audioProvider.isEnabled ? (double value) {
                                    audioProvider.setVolume(value);
                                  } : null,
                                  min: 0.0,
                                  max: 1.0,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                      crossFadeState: audioProvider.isEnabled
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Daily Awe delivers moments of wonder through beautiful imagery from Pexels.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Images provided by Pexels',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 