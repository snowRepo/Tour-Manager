import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

void showAppBanner(
  BuildContext context,
  String message, {
  Color backgroundColor = AppColors.primary,
  IconData icon = Icons.info_outline_rounded,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearMaterialBanners();
  messenger.showMaterialBanner(
    MaterialBanner(
      backgroundColor: backgroundColor,
      content: Text(message, style: const TextStyle(color: Colors.white)),
      leading: Icon(icon, color: Colors.white),
      actions: [
        TextButton(
          onPressed: messenger.clearMaterialBanners,
          child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  Future.delayed(const Duration(seconds: 3), messenger.clearMaterialBanners);
}
