import 'package:flutter/material.dart';

import '../utils/colors.dart';

const double kPreviewZoomMin = 0.2;
const double kPreviewZoomMax = 3.0;
const double kPreviewZoomStep = 0.1;

class PreviewZoomToolbar extends StatelessWidget {
  final double zoom;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onReset;

  const PreviewZoomToolbar({
    super.key,
    required this.zoom,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ZoomButton(icon: Icons.remove, onPressed: onZoomOut),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '${(zoom * 100).round()}%',
            style: TextStyle(
              color: AppColors.textBody,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ),
        _ZoomButton(icon: Icons.add, onPressed: onZoomIn),
        const SizedBox(width: 4),
        _ZoomButton(icon: Icons.refresh, onPressed: onReset),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ZoomButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: Icon(icon, color: AppColors.textBody),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
