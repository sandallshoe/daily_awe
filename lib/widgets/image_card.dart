import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/image_model.dart';

class ImageCard extends StatelessWidget {
  final PexelsImage image;
  final VoidCallback? onTap;
  final bool isPreloading;

  const ImageCard({
    super.key,
    required this.image,
    this.onTap,
    this.isPreloading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'image_${image.id}',
            child: CachedNetworkImage(
              imageUrl: image.getBestQualityUrl(MediaQuery.of(context).size.width),
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 300),
              fadeOutDuration: const Duration(milliseconds: 300),
              placeholder: (context, url) => Container(
                color: Colors.black12,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.black12,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load image\n${error.toString()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          if (!isPreloading) Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Photo by ${image.photographer} on Pexels',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  onPressed: () => _showImageDetails(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Photo Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Photographer: ${image.photographer}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                // TODO: Implement URL launcher
              },
              child: Text(
                'View on Pexels: ${image.originalUrl}',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 