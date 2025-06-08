import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  const Loading({
    super.key,
    this.text,
  });

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (text != null) ...[
            const SizedBox(height: 16),
            Text(text!),
          ],
        ],
      ),
    );
  }
}
