import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A translucent, blurred "liquid glass" panel — the shared look for the
/// loading overlay and the error banner.
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Full-screen frosted overlay shown while the dashboard's data is loading.
/// A slow or failing network then shows a clear "loading" state instead of
/// misleading ₹0 figures.
class GlassLoadingOverlay extends StatelessWidget {
  const GlassLoadingOverlay({
    super.key,
    this.message = 'Loading your expenses…',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    // Sized by its parent (a Positioned.fill around the AnimatedSwitcher), so
    // this fills the screen without being a Positioned itself.
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        alignment: Alignment.center,
        child: _GlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(AppColors.gold),
                ),
              ),
              const SizedBox(height: 18),
              Text(message,
                  style: AppText.label(13, AppColors.textPrimary),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

/// A non-blocking glass banner shown when a fetch failed, so the user knows the
/// figures may be stale/local rather than silently staring at fallback data.
/// Offers a Retry that re-runs the load.
class GlassErrorBanner extends StatelessWidget {
  const GlassErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined,
              color: AppColors.red, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Couldn't reach the server",
                    style: AppText.label(13, AppColors.textPrimary,
                        weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(message,
                    style: AppText.label(11, AppColors.textSecondary)),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry', style: AppText.label(13, AppColors.gold)),
          ),
        ],
      ),
    );
  }
}
