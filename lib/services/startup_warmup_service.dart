import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import '../models/plant.dart';

/// Precaches Home list thumbs so [CachedNetworkImage] can paint from cache.
class StartupWarmupService {
  StartupWarmupService({
    this.timeout = const Duration(seconds: 12),
    this.concurrency = 6,
  });

  final Duration timeout;
  final int concurrency;

  /// Precache [plants] list URLs (+ optional [avatarUrl]). Never throws.
  Future<void> precacheHomeContent(
    BuildContext context, {
    required List<Plant> plants,
    String? avatarUrl,
  }) async {
    try {
      await _precacheHomeContent(
        context,
        plants: plants,
        avatarUrl: avatarUrl,
      ).timeout(timeout);
    } on Object {
      // Best-effort.
    }
  }

  Future<void> _precacheHomeContent(
    BuildContext context, {
    required List<Plant> plants,
    String? avatarUrl,
  }) async {
    final urls = <String>{};
    final photo = avatarUrl?.trim();
    if (photo != null && photo.isNotEmpty) {
      urls.add(photo);
    }
    for (final plant in plants) {
      final url = plant.listImageUrl;
      if (url != null && url.isNotEmpty) {
        urls.add(url);
      }
    }
    if (!context.mounted || urls.isEmpty) return;
    await _precacheAll(context, urls.toList());
  }

  Future<void> _precacheAll(BuildContext context, List<String> urls) async {
    final workers = math.min(concurrency, urls.length);
    var next = 0;

    Future<void> worker() async {
      while (true) {
        final index = next;
        next += 1;
        if (index >= urls.length) return;
        if (!context.mounted) return;
        try {
          await precacheImage(
            CachedNetworkImageProvider(urls[index]),
            context,
            onError: (error, stackTrace) {
              // Missing/expired Storage objects (403/404) must not dump
              // FlutterError — cards already fall back via PlantImage.
            },
          );
        } on Object {
          // Skip failed URLs.
        }
      }
    }

    await Future.wait(List<Future<void>>.generate(workers, (_) => worker()));
  }
}
