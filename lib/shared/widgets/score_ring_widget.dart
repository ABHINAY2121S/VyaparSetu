import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class ScoreRingWidget extends StatefulWidget {
  final double score;
  final double maxScore;
  final String label;
  final String? sublabel;
  final Color? color;
  final double size;
  final double strokeWidth;
  final bool animate;

  const ScoreRingWidget({
    super.key,
    required this.score,
    this.maxScore = 100,
    required this.label,
    this.sublabel,
    this.color,
    this.size = 100,
    this.strokeWidth = 8,
    this.animate = true,
  });

  @override
  State<ScoreRingWidget> createState() => _ScoreRingWidgetState();
}

class _ScoreRingWidgetState extends State<ScoreRingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    if (widget.animate) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ScoreRingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      if (widget.animate) {
        _animation = Tween<double>(
          begin: _animation.value,
          end: widget.score,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
        _controller.forward(from: 0);
      } else {
        _animation = Tween<double>(begin: widget.score, end: widget.score).animate(_controller);
      }
    }
  }

  Color get _scoreColor {
    if (widget.color != null) return widget.color!;
    final ratio = widget.score / widget.maxScore;
    if (ratio >= 0.7) return AppColors.scoreHigh;
    if (ratio >= 0.4) return AppColors.scoreMedium;
    return AppColors.scoreLow;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final currentScore = widget.animate ? _animation.value : widget.score;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ScoreRingPainter(
                  score: currentScore,
                  maxScore: widget.maxScore,
                  color: _scoreColor,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentScore.round().toString(),
                    style: GoogleFonts.inter(
                      fontSize: widget.size * 0.24,
                      fontWeight: FontWeight.w800,
                      color: _scoreColor,
                      height: 1,
                    ),
                  ),
                  if (widget.sublabel != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      widget.sublabel!,
                      style: GoogleFonts.inter(
                        fontSize: widget.size * 0.09,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double score;
  final double maxScore;
  final Color color;
  final double strokeWidth;

  _ScoreRingPainter({
    required this.score,
    required this.maxScore,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final sweepAngle = (score / maxScore) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}

class MiniScoreRing extends StatelessWidget {
  final double score;
  final double maxScore;
  final Color? color;
  final double size;

  const MiniScoreRing({
    super.key,
    required this.score,
    this.maxScore = 100,
    this.color,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ScoreRingPainter(
              score: score,
              maxScore: maxScore,
              color: color ?? AppColors.primary,
              strokeWidth: 4,
            ),
          ),
          Text(
            score.round().toString(),
            style: GoogleFonts.inter(
              fontSize: size * 0.26,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
