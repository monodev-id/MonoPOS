import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import '../../core/themes/app_sizes.dart';

class AppSuccessOverlay {
  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void show(
    String message, {
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    final navigator = AppRoutes.rootNavigatorKey.currentState;
    final overlay = navigator?.overlay;
    if (overlay == null) return;

    _dismiss();

    final entry = OverlayEntry(
      builder: (_) => _SuccessOverlayContent(message: message),
    );

    _activeEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    final entry = _activeEntry;
    _activeEntry = null;

    if (entry != null && entry.mounted) {
      entry.remove();
    }
  }
}

class _SuccessOverlayContent extends StatefulWidget {
  final String message;

  const _SuccessOverlayContent({required this.message});

  @override
  State<_SuccessOverlayContent> createState() => _SuccessOverlayContentState();
}

class _SuccessOverlayContentState extends State<_SuccessOverlayContent> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _checkProgress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _checkProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      liveRegion: true,
      container: true,
      label: widget.message,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.6, end: 1.0).animate(_scale),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSizes.padding * 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.padding * 1.5,
                  vertical: AppSizes.padding,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radius * 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(72, 72),
                          painter: _CheckPainter(
                            progress: _checkProgress.value,
                            color: theme.colorScheme.tertiary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSizes.padding),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 4, circlePaint);

    final fillPaint = Paint()..color = color;
    canvas.drawCircle(center, (radius - 4) * progress, fillPaint);

    final path = Path();
    path.moveTo(size.width * 0.32, size.height * 0.52);
    path.lineTo(size.width * 0.46, size.height * 0.66);
    path.lineTo(size.width * 0.70, size.height * 0.36);

    final pathMetric = path.computeMetrics().first;
    final drawnPath = pathMetric.extractPath(0, pathMetric.length * progress);

    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(drawnPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
