import 'package:flutter/material.dart';

/// The one button style used across the app. Set [outlined] for secondary actions.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size.fromHeight(50)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
    return outlined
        ? OutlinedButton.icon(
            onPressed: onPressed, icon: Icon(icon), label: Text(label), style: style)
        : FilledButton.icon(
            onPressed: onPressed, icon: Icon(icon), label: Text(label), style: style);
  }
}
