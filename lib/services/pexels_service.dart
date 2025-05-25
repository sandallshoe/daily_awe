import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/image_model.dart';
import '../config/env_config.dart';

class PexelsService {
  static const String _baseUrl = 'https://api.pexels.com/v1';
  final http.Client _client;

  PexelsService({http.Client? client}) : _client = client ?? http.Client();

  String _maskApiKey(String key) {
    if (key.isEmpty) return '[EMPTY]';
    if (key.length <= 5) return '${key.substring(0, 1)}...';
    return '${key.substring(0, 5)}...';
  }

  Future<List<PexelsImage>> searchImages({
    String query = 'nature,landscape,space',
    int page = 1,
    int perPage = 15,
  }) async {
    debugPrint('PexelsService: Searching for images with query: $query');
    final url = Uri.parse(
      '$_baseUrl/search?query=$query&per_page=$perPage&page=$page',
    );

    try {
      final apiKey = EnvConfig.pexelsApiKey;
      debugPrint('PexelsService: Making API request to ${url.toString()}');
      debugPrint('PexelsService: API key status: ${apiKey.isEmpty ? "MISSING" : "present"} (${_maskApiKey(apiKey)})');
      
      if (apiKey.isEmpty) {
        throw Exception('API key is missing. Please check your .env file');
      }

      final response = await _client.get(
        url,
        headers: {'Authorization': apiKey},
      );

      debugPrint('PexelsService: Received response with status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final photos = data['photos'] as List;
        debugPrint('PexelsService: Successfully parsed ${photos.length} photos');
        return photos.map((photo) => PexelsImage.fromJson(photo)).toList();
      } else {
        final errorBody = response.body;
        debugPrint('PexelsService: Error response body: $errorBody');
        throw Exception('Failed to load images: ${response.statusCode}\nResponse: $errorBody');
      }
    } catch (e, stackTrace) {
      debugPrint('PexelsService: Error during search: $e');
      debugPrint('PexelsService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<PexelsImage>> getCuratedImages({
    int page = 1,
    int perPage = 15,
  }) async {
    debugPrint('PexelsService: Getting curated images');
    final url = Uri.parse(
      '$_baseUrl/curated?per_page=$perPage&page=$page',
    );

    try {
      final apiKey = EnvConfig.pexelsApiKey;
      debugPrint('PexelsService: Making API request to ${url.toString()}');
      debugPrint('PexelsService: API key status: ${apiKey.isEmpty ? "MISSING" : "present"} (${_maskApiKey(apiKey)})');
      
      if (apiKey.isEmpty) {
        throw Exception('API key is missing. Please check your .env file');
      }

      final response = await _client.get(
        url,
        headers: {'Authorization': apiKey},
      );

      debugPrint('PexelsService: Received response with status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final photos = data['photos'] as List;
        debugPrint('PexelsService: Successfully parsed ${photos.length} photos');
        return photos.map((photo) => PexelsImage.fromJson(photo)).toList();
      } else {
        final errorBody = response.body;
        debugPrint('PexelsService: Error response body: $errorBody');
        throw Exception('Failed to load curated images: ${response.statusCode}\nResponse: $errorBody');
      }
    } catch (e, stackTrace) {
      debugPrint('PexelsService: Error during curated fetch: $e');
      debugPrint('PexelsService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
} 