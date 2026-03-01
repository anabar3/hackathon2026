import 'package:flutter/material.dart';

/// Wraps a scrollable [child] with top and bottom fade gradients using a
/// [ShaderMask], giving the appearance that content smoothly fades out at
/// the scroll edges.
///
/// Usage:
/// ```dart
/// FadeScrollView(
///   child: SingleChildScrollView(...),
/// )
/// ```
class FadeScrollView extends StatelessWidget {
  final Widget child;

  /// How much of the height is consumed by the top fade (0.0 – 1.0).
  final double topFade;

  /// How much of the height is consumed by the bottom fade (0.0 – 1.0).
  final double bottomFade;

  const FadeScrollView({
    super.key,
    required this.child,
    this.topFade = 0.06,
    this.bottomFade = 0.10,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0.0, topFade, 1.0 - bottomFade, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
