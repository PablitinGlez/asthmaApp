import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class SnackBarHelper {
  static void showError(BuildContext context, String message) {
    _showToast(
      context,
      title: '¡Oh no!',
      description: message,
      type: ToastificationType.error,
    );
  }

  static void showSuccess(BuildContext context, String message, {Widget? leading}) {
    _showToast(
      context,
      title: '¡Éxito!',
      description: message,
      type: ToastificationType.success,
      leading: leading,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showToast(
      context,
      title: 'Información',
      description: message,
      type: ToastificationType.info,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showToast(
      context,
      title: 'Advertencia',
      description: message,
      type: ToastificationType.warning,
    );
  }

  static void _showToast(
    BuildContext context, {
    required String title,
    required String description,
    required ToastificationType type,
    Widget? leading,
  }) {
    // Evitar que los Toasts se pongan en cola/encimados:
    toastification.dismissAll();

    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 4),
      icon: leading,
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      description: Text(
        description,
        style: const TextStyle(fontFamily: 'Satoshi', fontSize: 13),
      ),
      alignment: Alignment.bottomCenter,
      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.always,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
    );
  }
}
