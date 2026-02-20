import 'package:flutter/material.dart';

import '../utils/colors.dart';

class AppShell extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget child;

  const AppShell({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate950,
      appBar: AppBar(
        backgroundColor: AppColors.slate950.withValues(alpha: 0.7),
        surfaceTintColor: Colors.transparent,
        leading: leading ??
            (Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.slate200),
                    onPressed: () => Navigator.pop(context),
                  )
                : null),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.slate200,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        actions: actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.slate800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
