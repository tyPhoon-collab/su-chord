import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract interface class HasDebugViews {
  List<DebugChip> build();
}

class DebugChip extends StatelessWidget {
  const DebugChip({
    super.key,
    required this.titleText,
    required this.child,
  });

  final String titleText;
  final Widget child;

  @override
  Widget build(BuildContext context) => Chip(
        label: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleText,
              style: Get.textTheme.titleMedium,
            ),
            child,
          ],
        ),
        padding: const EdgeInsets.all(8),
      );
}
