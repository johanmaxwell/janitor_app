import 'package:flutter/material.dart';

class PercentageIcon extends StatelessWidget {
  final IconData icon;
  final double percentage;
  final double size;
  final Color? color;

  const PercentageIcon({
    super.key,
    required this.icon,
    required this.percentage,
    this.color = Colors.orange,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Icon(icon, color: Colors.grey[300], size: size),
          ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: percentage.clamp(0.0, 1.0),
              child: Icon(icon, color: color, size: size),
            ),
          ),
        ],
      ),
    );
  }
}
