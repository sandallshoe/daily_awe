class PexelsImage {
  final int id;
  final String url;
  final String photographer;
  final String photographerUrl;
  final String originalUrl;

  PexelsImage({
    required this.id,
    required this.url,
    required this.photographer,
    required this.photographerUrl,
    required this.originalUrl,
  });

  factory PexelsImage.fromJson(Map<String, dynamic> json) {
    return PexelsImage(
      id: json['id'],
      url: json['src']['large'],
      photographer: json['photographer'],
      photographerUrl: json['photographer_url'],
      originalUrl: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'photographer': photographer,
      'photographer_url': photographerUrl,
      'original_url': originalUrl,
    };
  }

  String get attribution => 'Photo by $photographer on Pexels';
  String get attributionUrl => url;

  // Get the best quality image URL based on device screen size and memory constraints
  String getBestQualityUrl(double screenWidth) {
    if (screenWidth > 1200) return url;
    return url;
  }
} 