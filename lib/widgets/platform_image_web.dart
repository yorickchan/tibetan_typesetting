import 'dart:convert';
import 'dart:typed_data';

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

  if (imagePath.startsWith('data:')) {
    final commaIndex = imagePath.indexOf(',');
    if (commaIndex != -1) {
      final base64 = imagePath.substring(commaIndex + 1);
      return Image.memory(
        base64Decode(base64),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }
  }

  if (imagePath.startsWith('blob:')) {
    return Image.network(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }

  return Image.network(
    imagePath,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder ??
        (_, __, ___) => const SizedBox.shrink(),
  );
}
