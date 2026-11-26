import 'package:flutter/material.dart';

void showCommunicationSnackBar(
  BuildContext context, {
  required String title,
  required String message,
  required IconData icon,
  bool isError = false,
}) {
  final colors = Theme.of(context).colorScheme;
  final foreground = colors.inversePrimary;
  final accent = isError ? colors.error : foreground;
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.onInverseSurface),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}
