import 'package:flutter/material.dart';

class BrandLogoCard extends StatelessWidget {
  const BrandLogoCard({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'Tour1.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
