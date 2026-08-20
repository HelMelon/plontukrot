import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Network plant photo with optional fallback URL (e.g. thumb → full).
///
/// Load failures are logged in debug mode so silent placeholders are diagnosable.
class PlantImage extends StatefulWidget {
  final String? imageUrl;
  final String? fallbackUrl;
  final BoxFit fit;
  final Alignment alignment;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final double? width;
  final double? height;
  final Widget placeholder;
  final Widget errorWidget;

  /// When set, exposes an image semantics node with this label.
  final String? semanticLabel;

  /// When true, hides this image from the semantics tree (e.g. inside a
  /// labeled card/list row).
  final bool excludeFromSemantics;

  const PlantImage({
    super.key,
    required this.imageUrl,
    this.fallbackUrl,
    required this.placeholder,
    required this.errorWidget,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.memCacheWidth,
    this.memCacheHeight,
    this.width,
    this.height,
    this.semanticLabel,
    this.excludeFromSemantics = false,
  });

  @override
  State<PlantImage> createState() => _PlantImageState();
}

class _PlantImageState extends State<PlantImage> {
  late String? _activeUrl;
  var _triedFallback = false;

  @override
  void initState() {
    super.initState();
    _activeUrl = _normalize(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant PlantImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.fallbackUrl != widget.fallbackUrl) {
      _activeUrl = _normalize(widget.imageUrl);
      _triedFallback = false;
    }
  }

  static String? _normalize(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String? get _fallback {
    final fallback = _normalize(widget.fallbackUrl);
    final primary = _normalize(widget.imageUrl);
    if (fallback == null) return null;
    if (fallback == primary) return null;
    return fallback;
  }

  void _onError(String url, Object error) {
    if (kDebugMode) {
      debugPrint('PlantImage failed url=$url error=$error');
    }
    final fallback = _fallback;
    if (!_triedFallback && fallback != null && fallback != url) {
      setState(() {
        _triedFallback = true;
        _activeUrl = fallback;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _activeUrl;
    final Widget child;
    if (url == null) {
      child = widget.placeholder;
    } else {
      child = CachedNetworkImage(
        imageUrl: url,
        fit: widget.fit,
        alignment: widget.alignment,
        width: widget.width,
        height: widget.height,
        memCacheWidth: widget.memCacheWidth,
        memCacheHeight: widget.memCacheHeight,
        placeholder: (context, _) => widget.placeholder,
        errorWidget: (context, failedUrl, error) {
          final fallback = _fallback;
          final canRetry = !_triedFallback &&
              fallback != null &&
              fallback != failedUrl;
          if (canRetry) {
            // Schedule fallback switch after this build.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _onError(failedUrl, error);
            });
            return widget.placeholder;
          }
          if (kDebugMode) {
            debugPrint(
              'PlantImage final failure url=$failedUrl error=$error',
            );
          }
          return widget.errorWidget;
        },
      );
    }

    if (widget.excludeFromSemantics) {
      return ExcludeSemantics(child: child);
    }
    final label = widget.semanticLabel;
    if (label != null) {
      return Semantics(
        image: true,
        label: label,
        child: ExcludeSemantics(child: child),
      );
    }
    return child;
  }
}
