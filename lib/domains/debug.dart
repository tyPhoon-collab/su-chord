import 'package:flutter/material.dart';

import '../widgets/debug_chip.dart';

export '../widgets/debug_chip.dart';

abstract interface class HasDebugViews {
  List<DebugChip> build(BuildContext context);
}
