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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.7),
        surfaceTintColor: Colors.transparent,
        leading: leading ??
            (Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.textCaption),
                    onPressed: () => Navigator.pop(context),
                  )
                : null),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.textCaption,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        actions: actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
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
