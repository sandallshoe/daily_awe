import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/image_model.dart';
import '../providers/settings_provider.dart';
import '../services/pexels_service.dart';
import '../services/cache_service.dart';
import '../screens/settings_screen.dart';
import '../config/env_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/image_card.dart';
import 'dart:async';

class SlideshowScreen extends StatefulWidget {
  const SlideshowScreen({super.key});

  @override
  State<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> with SingleTickerProviderStateMixin {
  final PexelsService _pexelsService = PexelsService();
  late final CacheService _cacheService;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _slideshowTimer;
  
  List<PexelsImage> _images = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    debugPrint('SlideshowScreen: Initializing');
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _initializeServices();
  }

  void _startSlideshowTimer() {
    _slideshowTimer?.cancel();
    final settings = context.read<SettingsProvider>().settings;
    _slideshowTimer = Timer.periodic(
      Duration(seconds: settings.slideshowInterval.seconds),
      (_) => _nextImage(),
    );
    debugPrint('SlideshowScreen: Started timer with ${settings.slideshowInterval.seconds}s interval');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Restart timer when settings change
    _startSlideshowTimer();
  }

  Future<void> _initializeServices() async {
    debugPrint('SlideshowScreen: Initializing services');
    final prefs = await SharedPreferences.getInstance();
    _cacheService = CacheService(prefs);
    await _loadImages();
    _startSlideshowTimer();
  }

  Future<void> _loadImages() async {
    debugPrint('SlideshowScreen: Loading images');
    try {
      debugPrint('SlideshowScreen: API Key available: ${EnvConfig.pexelsApiKey.isNotEmpty}');
      debugPrint('SlideshowScreen: Fetching curated images from Pexels');
      final images = await _pexelsService.getCuratedImages();
      debugPrint('SlideshowScreen: Received ${images.length} images');
      
      if (mounted) {
        setState(() {
          _images = images;
          _isLoading = false;
          _isOffline = false;
        });
        _fadeController.forward();
        
        // Cache current and next few images
        _cacheCurrentAndNextImages();
      }
    } catch (e) {
      debugPrint('SlideshowScreen: Error loading images: $e');
      // Try loading cached images
      await _loadCachedImages();
    }
  }

  Future<void> _loadCachedImages() async {
    try {
      final cachedImages = await _cacheService.getCachedImages();
      if (mounted && cachedImages.isNotEmpty) {
        setState(() {
          _images = cachedImages;
          _currentIndex = 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading cached images: $e');
    }
  }

  Future<void> _cacheCurrentAndNextImages() async {
    if (_images.isEmpty) return;

    // Cache current image
    await _cacheService.cacheImage(_images[_currentIndex]);

    // Cache next 2 images
    for (int i = 1; i <= 2; i++) {
      if (_currentIndex + i < _images.length) {
        await _cacheService.cacheImage(_images[_currentIndex + i]);
      }
    }
  }

  void _nextImage() {
    if (_currentIndex < _images.length - 1) {
      _fadeController.reverse().then((_) {
        setState(() {
          _currentIndex++;
        });
        _fadeController.forward();
        _cacheCurrentAndNextImages();
      });
    } else {
      // Reset to first image when reaching the end
      _fadeController.reverse().then((_) {
        setState(() {
          _currentIndex = 0;
        });
        _fadeController.forward();
        _cacheCurrentAndNextImages();
      });
    }
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _fadeController.dispose();
    _pexelsService.dispose();
    _cacheService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_images.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No images available'),
        ),
      );
    }

    final currentImage = _images[_currentIndex];
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            _nextImage();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: CachedNetworkImage(
                imageUrl: currentImage.getBestQualityUrl(screenSize.width),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.background,
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            if (_isOffline)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_bolt, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Offline Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentImage.attribution,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 