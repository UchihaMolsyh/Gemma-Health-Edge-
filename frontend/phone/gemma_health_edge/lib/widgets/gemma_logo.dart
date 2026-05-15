import 'package:flutter/material.dart';

class GemmaLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const GemmaLogo({super.key, this.size = 64, this.showShadow = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        Icons.local_hospital,
        size: size * 0.75,
        color: const Color(0xFF4285F4),
      ),
    );
  }
}
