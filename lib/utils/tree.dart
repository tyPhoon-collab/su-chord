import 'package:collection/collection.dart';

class TreeNode<T> {
  TreeNode(this.value) : children = {};

  final T value;
  Set<TreeNode<T>> children;

  Set<T> get childrenValues => children.map((e) => e.value).toSet();

  void addChild(TreeNode<T> child) {
    children.add(child);
  }

  TreeNode<T>? getChild(T value) =>
      children.firstWhereOrNull((e) => e.value == value);

  TreeNode<T> putChildIfAbsent(T value, TreeNode<T> Function() ifAbsent) =>
      children.firstWhere((e) => e.value == value, orElse: () {
        final node = ifAbsent();
        addChild(node);
        return node;
      });

  @override
  String toString() => '$value: $childrenValues';
}
