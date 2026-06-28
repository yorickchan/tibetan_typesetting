import 'dart:io' show File;

import 'package:flutter/widgets.dart';

Widget platformImage({
  required String? imagePath,
  double? width,
  double? height,
  BoxFit? fit,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  if (imagePath == null || imagePath.isEmpty) {
    return const SizedBox.shrink();
  }
  return Image.file(
    File(imagePath),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
