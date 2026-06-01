import 'package:flutter/material.dart';

class ScaledPreview extends StatelessWidget {
  final double zoom;
  final double width;
  final double height;
  final Widget child;

  const ScaledPreview({
    super.key,
    required this.zoom,
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width * zoom,
      height: height * zoom,
      child: Transform.scale(
        alignment: Alignment.topLeft,
        scale: zoom,
        child: child,
      ),
    );
  }
}
