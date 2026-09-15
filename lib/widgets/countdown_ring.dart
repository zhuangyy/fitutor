import 'package:flutter/material.dart';

class CountdownRing extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final double size;
  final Color? color;

  const CountdownRing({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.size = 200,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;
    final activeColor = color ?? colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(activeColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$remainingSeconds',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: activeColor,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text('秒',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}
