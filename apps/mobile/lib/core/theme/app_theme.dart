import 'package:flutter/material.dart';

class AppColors {
  // Dark Mode
  static const darkBg = Color(0xFF0A0A0F);
  static const darkSurface = Color(0xFF141420);
  static const darkCard = Color(0xFF1C1C2E);
  static const darkElevated = Color(0xFF252538);

  // Light Mode
  static const lightBg = Color(0xFFF2F2F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFF8F8FC);
  static const lightElevated = Color(0xFFEEEEF6);

  // Accent
  static const primary = Color(0xFF7B6FE8);
  static const primaryLight = Color(0xFF9D94F0);
  static const primaryDark = Color(0xFF5A50D4);
  static const accent = Color(0xFFFF6B6B);
  static const accentGreen = Color(0xFF30D158);
  static const accentBlue = Color(0xFF0A84FF);

  // Text Dark
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFF8E8EA0);
  static const darkTextTertiary = Color(0xFF5A5A6E);

  // Text Light
  static const lightTextPrimary = Color(0xFF1A1A2E);
  static const lightTextSecondary = Color(0xFF6B6B80);
  static const lightTextTertiary = Color(0xFFAAAAAC);
}

class AppTheme {
  static const fontFamily = 'Vazirmatn';

  static ThemeData get dark => _buildTheme(Brightness.dark);
  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final elevated = isDark ? AppColors.darkElevated : AppColors.lightElevated;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: AppColors.accent,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(
            fontFamily: fontFamily,
            color: textSecondary,
            fontWeight: FontWeight.w400),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryDark;
            }
            return AppColors.primary;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          minimumSize:
              WidgetStateProperty.all(const Size(double.infinity, 52)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 0;
            return isDark ? 8 : 4;
          }),
          shadowColor: WidgetStateProperty.all(
              AppColors.primary.withOpacity(0.4)),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 16),
          ),
          overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.1)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
              fontFamily: fontFamily, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: textSecondary.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontFamily: fontFamily, fontWeight: FontWeight.w500),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
            fontFamily: fontFamily,
            color: textPrimary,
            fontWeight: FontWeight.w700),
        displayMedium: TextStyle(
            fontFamily: fontFamily,
            color: textPrimary,
            fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(
            fontFamily: fontFamily,
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 28),
        headlineMedium: TextStyle(
            fontFamily: fontFamily,
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 22),
        headlineSmall: TextStyle(
            fontFamily: fontFamily,
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18),
        titleLarge: TextStyle(
            fontFamily: fontFamily,
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 17),
        titleMedium: TextStyle(
            fontFamily: fontFamily,
            color: textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 15),
        titleSmall: TextStyle(
            fontFamily: fontFamily,
            color: textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 13),
        bodyLarge: TextStyle(
            fontFamily: fontFamily,
            color: textPrimary,
            fontWeight: FontWeight.w400,
            fontSize: 16),
        bodyMedium: TextStyle(
            fontFamily: fontFamily,
            color: textPrimary,
            fontWeight: FontWeight.w400,
            fontSize: 14),
        bodySmall: TextStyle(
            fontFamily: fontFamily,
            color: textSecondary,
            fontWeight: FontWeight.w300,
            fontSize: 12),
        labelLarge: TextStyle(
            fontFamily: fontFamily,
            color: textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14),
        labelMedium: TextStyle(
            fontFamily: fontFamily,
            color: textSecondary,
            fontWeight: FontWeight.w400,
            fontSize: 12),
      ),
      dividerTheme: DividerThemeData(
        color: textSecondary.withOpacity(0.1),
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevated,
        contentTextStyle: TextStyle(
            fontFamily: fontFamily, color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Helper widgets
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = elevated
        ? (isDark ? AppColors.darkElevated : AppColors.lightElevated)
        : (isDark ? AppColors.darkCard : AppColors.lightCard);

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withOpacity(0.1),
        highlightColor: AppColors.primary.withOpacity(0.05),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

// دکمه سه‌بعدی
class AppButton3D extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final double height;
  final double? width;

  const AppButton3D({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.height = 52,
    this.width,
  });

  @override
  State<AppButton3D> createState() => _AppButton3DState();
}

class _AppButton3DState extends State<AppButton3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;
    const depth = 4.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.width ?? double.infinity,
        height: widget.height,
        transform: Matrix4.translationValues(0, _pressed ? depth : 0, 0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    offset: const Offset(0, depth),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    offset: const Offset(0, depth + 4),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}
