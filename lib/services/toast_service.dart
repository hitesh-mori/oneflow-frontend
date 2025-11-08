import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../core/theme/app_colors.dart';

/// Premium Toast Service with elegant minimal design using theme purple
/// Features: White cards with purple accents, modern typography, subtle shadows
class AppToast {
  // Get the purple theme color
  static Color get _purpleColor => AppColors.theme['primaryColor'] as Color;

  // Subtle accent colors for icons only
  static const Color _errorIconColor = Color(0xFFEF4444);
  static const Color _warningIconColor = Color(0xFFF59E0B);
  static const Color _infoIconColor = Color(0xFF3B82F6);

  /// Show success toast - White card with purple accent and purple icon
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.minimal,
      title: Text(
        title ?? 'Success',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
          height: 1.3,
          color: AppColors.theme['textColor'],
        ),
      ),
      description: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          height: 1.5,
          color: (AppColors.theme['textColor'] as Color).withValues(alpha: 0.8),
        ),
      ),
      primaryColor: _purpleColor,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.theme['textColor'],
      alignment: Alignment.topRight,
      autoCloseDuration: duration ?? const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: _purpleColor.withValues(alpha: 0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: _purpleColor.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
      ],
      showProgressBar: true,
      progressBarTheme: ProgressIndicatorThemeData(
        color: _purpleColor,
        linearTrackColor: _purpleColor.withValues(alpha: 0.15),
      ),
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: false,
      icon: Icon(
        Icons.check_circle_rounded,
        color: _purpleColor,
        size: 24,
      ),
    );
  }

  /// Show error toast - White card with purple accent and red icon
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.minimal,
      title: Text(
        title ?? 'Error',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
          height: 1.3,
          color: AppColors.theme['textColor'],
        ),
      ),
      description: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          height: 1.5,
          color: (AppColors.theme['textColor'] as Color).withValues(alpha: 0.8),
        ),
      ),
      primaryColor: _purpleColor,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.theme['textColor'],
      alignment: Alignment.topRight,
      autoCloseDuration: duration ?? const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: _purpleColor.withValues(alpha: 0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: _purpleColor.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
      ],
      showProgressBar: true,
      progressBarTheme: ProgressIndicatorThemeData(
        color: _purpleColor,
        linearTrackColor: _purpleColor.withValues(alpha: 0.15),
      ),
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: false,
      icon: Icon(
        Icons.error_rounded,
        color: _errorIconColor,
        size: 24,
      ),
    );
  }

  /// Show info toast - White card with purple accent and blue icon
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.minimal,
      title: Text(
        title ?? 'Info',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
          height: 1.3,
          color: AppColors.theme['textColor'],
        ),
      ),
      description: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          height: 1.5,
          color: (AppColors.theme['textColor'] as Color).withValues(alpha: 0.8),
        ),
      ),
      primaryColor: _purpleColor,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.theme['textColor'],
      alignment: Alignment.topRight,
      autoCloseDuration: duration ?? const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: _purpleColor.withValues(alpha: 0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: _purpleColor.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
      ],
      showProgressBar: true,
      progressBarTheme: ProgressIndicatorThemeData(
        color: _purpleColor,
        linearTrackColor: _purpleColor.withValues(alpha: 0.15),
      ),
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: false,
      icon: Icon(
        Icons.info_rounded,
        color: _infoIconColor,
        size: 24,
      ),
    );
  }

  /// Show warning toast - White card with purple accent and orange icon
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.minimal,
      title: Text(
        title ?? 'Warning',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
          height: 1.3,
          color: AppColors.theme['textColor'],
        ),
      ),
      description: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          height: 1.5,
          color: (AppColors.theme['textColor'] as Color).withValues(alpha: 0.8),
        ),
      ),
      primaryColor: _purpleColor,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.theme['textColor'],
      alignment: Alignment.topRight,
      autoCloseDuration: duration ?? const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: _purpleColor.withValues(alpha: 0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: _purpleColor.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
      ],
      showProgressBar: true,
      progressBarTheme: ProgressIndicatorThemeData(
        color: _purpleColor,
        linearTrackColor: _purpleColor.withValues(alpha: 0.15),
      ),
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: false,
      icon: Icon(
        Icons.warning_rounded,
        color: _warningIconColor,
        size: 24,
      ),
    );
  }

  /// Show custom toast with your brand purple - Premium styling
  static void showCustom(
    BuildContext context,
    String message, {
    String? title,
    IconData? icon,
    Duration? duration,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.minimal,
      title: title != null
          ? Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                height: 1.3,
                color: AppColors.theme['textColor'],
              ),
            )
          : null,
      description: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          height: 1.5,
          color: (AppColors.theme['textColor'] as Color).withValues(alpha: 0.8),
        ),
      ),
      primaryColor: _purpleColor,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.theme['textColor'],
      alignment: Alignment.topRight,
      autoCloseDuration: duration ?? const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: _purpleColor.withValues(alpha: 0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: _purpleColor.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
      ],
      showProgressBar: true,
      progressBarTheme: ProgressIndicatorThemeData(
        color: _purpleColor,
        linearTrackColor: _purpleColor.withValues(alpha: 0.15),
      ),
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: false,
      icon: Icon(
        icon ?? Icons.notifications_active_rounded,
        color: _purpleColor,
        size: 24,
      ),
    );
  }
}
