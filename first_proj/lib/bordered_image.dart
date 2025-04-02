import 'package:flutter/material.dart';

class BorderedImage extends StatelessWidget {
  final ImageProvider image;
  final double borderWidth;
  final Color borderColor;
  final BorderRadius borderRadius;
  final double? width;
  final double? height;

  const BorderedImage({
    super.key,
    required this.image,
    this.borderWidth = 2.0,
    this.borderColor = Colors.black,
    this.borderRadius = BorderRadius.zero,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: borderRadius,
        image: DecorationImage(image: image, fit: BoxFit.cover),
      ),
    );
  }
}
