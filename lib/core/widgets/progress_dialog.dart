import 'package:flutter/material.dart';

typedef ProgressReporter = void Function(double? progress, String message);

class _ProgressState {
  const _ProgressState(this.value, this.message);
  final double? value; // null = unknown (spinner-style bar)
  final String message;
}

/// Blocks the screen with a progress bar while [task] runs, then closes itself.
class ProgressDialog {
  ProgressDialog._();

  static Future<T> run<T>(
    BuildContext context, {
    required String title,
    required Future<T> Function(ProgressReporter report) task,
  }) async {
    final state = ValueNotifier<_ProgressState>(const _ProgressState(null, 'Starting…'));
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(title),
          content: ValueListenableBuilder<_ProgressState>(
            valueListenable: state,
            builder: (_, p, __) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: p.value),
                const SizedBox(height: 14),
                Text(p.message),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      return await task((value, message) => state.value = _ProgressState(value, message));
    } finally {
      navigator.pop();
    }
  }
}
