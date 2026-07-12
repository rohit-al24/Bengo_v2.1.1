import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/app_decorations.dart';
import '../utils/app_text_styles.dart';

class BenGoAppBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBackTap;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  const BenGoAppBar({
    super.key,
    this.title = 'BenGo',
    this.showBack = false,
    this.onBackTap,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        decoration:
            AppDecorations.softPanel(color: AppColors.bgWhite, radius: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (showBack)
                GestureDetector(
                  onTap: onBackTap ?? () => Navigator.maybePop(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: AppDecorations.skeuomorphicCard(radius: 14),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                const SizedBox(width: 42),
              const SizedBox(width: 14),
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: AppTextStyles.brandNameSmall.copyWith(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              if (actions != null)
                Row(mainAxisSize: MainAxisSize.min, children: actions!)
              else
                const SizedBox(width: 42),
            ],
          ),
        ),
      ),
    );
  }
}
