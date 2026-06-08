import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class WorkqlyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? titleWidget;
  final bool centerTitle;
  final double? titleSpacing;
  final PreferredSizeWidget? bottom;

  const WorkqlyAppBar({
    super.key,
    this.title = '',
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.titleWidget,
    this.centerTitle = false,
    this.titleSpacing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor     = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder   : const Color(0xFFF1F5F9);
    final titleColor  = isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue;
    final iconColor   = isDark ? AppTheme.accentGold    : AppTheme.emeraldGreen;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        centerTitle: centerTitle,
        titleSpacing: titleSpacing,
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: leading ??
            (automaticallyImplyLeading && Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: titleColor,
                    onPressed: () => Navigator.maybePop(context),
                  )
                : null),
        title: titleWidget ??
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
        actions: actions,
        iconTheme: IconThemeData(color: iconColor, size: 22),
        actionsIconTheme: IconThemeData(color: iconColor, size: 22),
        bottom: bottom,
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
