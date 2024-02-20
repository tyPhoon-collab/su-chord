import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chord_search_tree.dart';

abstract interface class HasDebugViews {
  List<DebugChip> build(BuildContext context);
}

class DebugChip extends ConsumerStatefulWidget {
  const DebugChip({
    super.key,
    required this.titleText,
    required this.builder,
  });

  final String titleText;
  final Widget Function(BuildContext) builder;

  @override
  ConsumerState<DebugChip> createState() => _DebugChipState();
}

class _DebugChipState extends ConsumerState<DebugChip> {
  bool _enable = false;

  @override
  void initState() {
    super.initState();
    _enable = ref.read(debugViewKeysProvider).contains(widget.titleText);
  }

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
                        _enable = !_enable;
                        final keys = ref.read(debugViewKeysProvider);
                        if (_enable) {
                          keys.add(widget.titleText);
                        } else {
                          keys.remove(widget.titleText);
                        }
                      });
                    },
                    child: _enable
                        ? const Icon(Icons.check_box_outlined)
                        : const Icon(Icons.check_box_outline_blank),
                  ),
                  Text(
                    widget.titleText,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              if (_enable) ...[
                const SizedBox(height: 8),
                widget.builder(context),
              ] else
                const SizedBox(),
            ],
          ),
        ),
      );
}
