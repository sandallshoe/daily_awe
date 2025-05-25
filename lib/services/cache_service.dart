import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/image_model.dart';

class CacheService {
  final SharedPreferences _prefs;
  final http.Client _client;
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB

  CacheService(this._prefs) : _client = http.Client();

  Future<void> _cacheImage(PexelsImage image) async {
    try {
      final response = await _client.get(Uri.parse(image.url));
      if (response.statusCode == 200) {
        final cacheDir = await getTemporaryDirectory();
        final file = File('${cacheDir.path}/${image.id}.jpg');
        await file.writeAsBytes(response.bodyBytes);
        
        // Cache metadata
        final metadata = {
          'id': image.id,
          'photographer': image.photographer,
          'photographerUrl': image.photographerUrl,
          'originalUrl': image.originalUrl,
          'url': image.url,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        
        await _prefs.setString('image_${image.id}_metadata', jsonEncode(metadata));
        debugPrint('Image cached successfully: ${image.id}');
      }
    } catch (e) {
      debugPrint('Error caching image: $e');
    }
  }

  Future<List<PexelsImage>> getCachedImages() async {
    final List<PexelsImage> images = [];
    final keys = _prefs.getKeys().where((key) => key.startsWith('image_') && key.endsWith('_metadata'));
    
    for (final key in keys) {
      try {
        final metadata = jsonDecode(_prefs.getString(key) ?? '{}');
        final image = PexelsImage(
          id: metadata['id'],
          url: metadata['url'],
          photographer: metadata['photographer'],
          photographerUrl: metadata['photographerUrl'],
          originalUrl: metadata['originalUrl'],
        );
        images.add(image);
      } catch (e) {
        debugPrint('Error loading cached image: $e');
      }
    }
    
    return images;
  }

  Future<void> cacheImage(PexelsImage image) async {
    try {
      await _cacheImage(image);
      await _enforceMaxCacheSize();
    } catch (e) {
      debugPrint('Error caching image: $e');
    }
  }

  Future<void> _enforceMaxCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final files = cacheDir.listSync();
      
      int totalSize = 0;
      for (var file in files) {
        if (file is File) {
          totalSize += file.lengthSync();
        }
      }

      if (totalSize > _maxCacheSize) {
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        
        for (var file in files) {
          if (file is File) {
            await file.delete();
            totalSize -= file.lengthSync();
            if (totalSize <= _maxCacheSize) break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error enforcing cache size: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      
      final keys = _prefs.getKeys().where((key) => key.startsWith('image_'));
      for (final key in keys) {
        await _prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  void dispose() {
    _client.close();
  }
} 