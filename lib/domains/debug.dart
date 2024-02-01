import 'package:flutter/material.dart';

abstract interface class HasDebugViews {
  List<DebugChip> build();
}

class DebugChip extends StatefulWidget {
  const DebugChip({
    super.key,
    required this.titleText,
    required this.builder,
  });

  final String titleText;
  final Widget Function(BuildContext) builder;

  @override
  State<DebugChip> createState() => _DebugChipState();
}

class _DebugChipState extends State<DebugChip> {
  bool isVisible = true;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isVisible = !isVisible;
                      });
                    },
                    child: const Icon(Icons.crop_square),
                  ),
                  Text(
                    widget.titleText,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              if (isVisible) ...[
                const SizedBox(height: 8),
                widget.builder(context),
              ] else
                const SizedBox(),
            ],
          ),
        ),
      );
}
