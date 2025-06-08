import 'package:flutter/material.dart';

class ErrorWidget extends StatelessWidget {
  const ErrorWidget(
      {super.key, this.message = '未知错误', this.error, this.onRetry});

  final String message;
  final Exception? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error),
          const SizedBox(height: 16),
          Text(message),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(error.toString()),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('重试'),
            ),
          ],
        ],
      ),
    );
  }
}
