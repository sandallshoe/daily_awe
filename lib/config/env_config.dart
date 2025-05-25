import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static String get pexelsApiKey => dotenv.env['PEXELS_API_KEY'] ?? '';
  
  static int get maxCacheSize => 
      int.tryParse(dotenv.env['MAX_CACHE_SIZE'] ?? '100') ?? 100;
  
  static int get defaultSlideshowInterval =>
      int.tryParse(dotenv.env['DEFAULT_SLIDESHOW_INTERVAL'] ?? '10') ?? 10;
      
  static bool get isConfigValid => pexelsApiKey.isNotEmpty;
} 