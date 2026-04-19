import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Simple file-based image cache using ONLY built-in Dart APIs.
/// No external packages needed — uses dart:io for download and file storage.
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._();
  factory ImageCacheService() => _instance;
  ImageCacheService._();

  String? _cacheDirPath;

  /// Get the cache directory path
  Future<String> _getCacheDirPath() async {
    if (_cacheDirPath != null) return _cacheDirPath!;
    // Use the system temp directory + our own subfolder
    final tempDir = Directory.systemTemp;
    final cacheDir = Directory('${tempDir.path}/eastnshop_img_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    _cacheDirPath = cacheDir.path;
    return _cacheDirPath!;
  }

  /// Generate a safe filename from URL using simple hash
  String _urlToFileName(String url) {
    // Simple hash: use hashCode + length for uniqueness
    final hash = url.hashCode.toUnsigned(32).toRadixString(16);
    final len = url.length.toRadixString(16);
    // Get file extension from URL
    final uri = Uri.tryParse(url);
    String ext = '.img';
    if (uri != null && uri.path.contains('.')) {
      ext = uri.path.substring(uri.path.lastIndexOf('.'));
      if (ext.length > 5) ext = '.img'; // Safety check
    }
    return '${hash}_$len$ext';
  }

  /// Check if image is cached locally
  Future<File?> getCachedImage(String url) async {
    try {
      final dirPath = await _getCacheDirPath();
      final file = File('$dirPath/${_urlToFileName(url)}');
      if (await file.exists() && (await file.length()) > 0) {
        return file;
      }
    } catch (e) {
      // Silently fail
    }
    return null;
  }

  /// Download and cache an image
  Future<File?> downloadAndCache(String url) async {
    try {
      final dirPath = await _getCacheDirPath();
      final file = File('$dirPath/${_urlToFileName(url)}');

      // Already cached
      if (await file.exists() && (await file.length()) > 0) return file;

      // Download using dart:io HttpClient
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 15);
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        await file.writeAsBytes(bytes);
        return file;
      }
    } catch (e) {
      print('⚠️ Cache download error: $e');
    }
    return null;
  }

  /// Pre-cache a list of URLs to disk
  Future<void> preCacheUrls(List<String> urls) async {
    print('🖼️ Pre-caching ${urls.length} images to disk...');
    final futures = urls.map((url) => downloadAndCache(url)).toList();
    await Future.wait(futures, eagerError: false);
    print('✅ Pre-cache complete!');
  }
}

/// Widget that loads from disk cache first, falls back to network.
/// First time: downloads image → saves to disk → displays.
/// Next time: loads instantly from disk file.
class CachedNetworkImg extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CachedNetworkImg({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<CachedNetworkImg> createState() => _CachedNetworkImgState();
}

class _CachedNetworkImgState extends State<CachedNetworkImg> {
  File? _cachedFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedNetworkImg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final cache = ImageCacheService();

    // Try disk cache first (instant!)
    File? file = await cache.getCachedImage(widget.imageUrl);
    if (file != null && mounted) {
      setState(() { _cachedFile = file; _isLoading = false; });
      return;
    }

    // Not cached — download, save to disk, then show
    file = await cache.downloadAndCache(widget.imageUrl);
    if (mounted) {
      setState(() { _cachedFile = file; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(
          color: Colors.grey[200],
          child: const Center(
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Load from disk cache (instant, no network needed!)
    if (_cachedFile != null) {
      return Image.file(
        _cachedFile!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _networkFallback(),
      );
    }

    // Fallback to network if cache failed
    return _networkFallback();
  }

  Widget _networkFallback() {
    return Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (_, __, ___) => Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
      ),
    );
  }
}
