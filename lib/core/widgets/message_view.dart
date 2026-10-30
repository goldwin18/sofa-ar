import 'package:flutter/material.dart';

import 'app_button.dart';

/// Centered icon + text (+ optional button). Used for errors and empty states.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.dark = false,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: color.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontSize: 16)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                child: AppButton(
                    label: actionLabel!, icon: Icons.settings, onPressed: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
