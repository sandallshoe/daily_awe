import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
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

class _SlideshowScreenState extends State<SlideshowScreen> with TickerProviderStateMixin {
  final PexelsService _pexelsService = PexelsService();
  late final CacheService _cacheService;
  late AnimationController _fadeController;
  late AnimationController _kenBurnsController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _slideshowTimer;
  
  List<PexelsImage> _images = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isOffline = false;

  // Ken Burns effect parameters
  final List<double> _scales = [1.0, 1.1, 1.2];
  final List<Alignment> _alignments = [
    const Alignment(-1, -1),
    const Alignment(1, 1),
    const Alignment(-1, 1),
    const Alignment(1, -1),
  ];
  int _currentScaleIndex = 0;
  int _currentAlignmentIndex = 0;
  int? _lastInterval;

  @override
  void initState() {
    super.initState();
    debugPrint('SlideshowScreen: Initializing');
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _kenBurnsController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _initializeKenBurnsAnimations();
    _initializeServices();
  }

  void _initializeKenBurnsAnimations() {
    final startScale = _scales[_currentScaleIndex];
    final endScale = _scales[(_currentScaleIndex + 1) % _scales.length];
    final startAlignment = _alignments[_currentAlignmentIndex];
    final endAlignment = _alignments[(_currentAlignmentIndex + 1) % _alignments.length];

    _scaleAnimation = Tween<double>(
      begin: startScale,
      end: endScale,
    ).animate(CurvedAnimation(
      parent: _kenBurnsController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(startAlignment.x, startAlignment.y),
      end: Offset(endAlignment.x, endAlignment.y),
    ).animate(CurvedAnimation(
      parent: _kenBurnsController,
      curve: Curves.easeInOut,
    ));

    _kenBurnsController.forward();
  }

  void _startSlideshowTimer() {
    final settings = context.read<SettingsProvider>().settings;
    final newInterval = settings.slideshowInterval.seconds;
    
    // Only restart timer if interval has changed
    if (_lastInterval != newInterval) {
      _slideshowTimer?.cancel();
      _slideshowTimer = Timer.periodic(
        Duration(seconds: newInterval),
        (_) => _nextImage(),
      );
      _lastInterval = newInterval;
      debugPrint('SlideshowScreen: Started timer with ${newInterval}s interval');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only start timer if we have images loaded
    if (!_isLoading && _images.isNotEmpty) {
      _startSlideshowTimer();
    }
  }

  Future<void> _initializeServices() async {
    debugPrint('SlideshowScreen: Initializing services');
    final prefs = await SharedPreferences.getInstance();
    _cacheService = CacheService(prefs);
    await _loadImages();
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
        _startSlideshowTimer();
        
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
    _fadeController.reverse().then((_) {
      setState(() {
        if (_currentIndex < _images.length - 1) {
          _currentIndex++;
        } else {
          _currentIndex = 0;
        }
        
        // Update Ken Burns effect parameters
        _currentScaleIndex = (_currentScaleIndex + 1) % _scales.length;
        _currentAlignmentIndex = (_currentAlignmentIndex + 1) % _alignments.length;
        
        // Reset and reinitialize Ken Burns animations
        _kenBurnsController.reset();
        _initializeKenBurnsAnimations();
      });
      
      _fadeController.forward();
      _cacheCurrentAndNextImages();
    });
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _fadeController.dispose();
    _kenBurnsController.dispose();
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
            AnimatedBuilder(
              animation: Listenable.merge([_kenBurnsController, _fadeController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: currentImage.getBestQualityUrl(screenSize.width),
                        fit: BoxFit.cover,
                        alignment: Alignment(
                          _slideAnimation.value.dx,
                          _slideAnimation.value.dy,
                        ),
                        placeholder: (context, url) => Container(
                          color: Theme.of(context).colorScheme.background,
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                );
              },
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