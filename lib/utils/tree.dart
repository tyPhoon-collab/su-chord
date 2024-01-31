import 'package:collection/collection.dart';

class TreeNode<T> {
  TreeNode(this.value);

  final T value;
  final Set<TreeNode<T>> children = {};

  Iterable<T> get childrenValues => children.map((e) => e.value);

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
  String toString() => '$value: [${children.join(', ')}]';
}

class TreeKeyValueNode<K, V> {
  TreeKeyValueNode(this.key, this.value);

  final K key;
  final V value;
  final Map<K, TreeKeyValueNode<K, V>> children = {};

  TreeKeyValueNode<K, V> addChild(K key, V value) {
    final node = TreeKeyValueNode(key, value);
    children[key] = node;
    return node;
  }

  TreeKeyValueNode<K, V>? getChild(K key) => children[key];

  TreeKeyValueNode<K, V> putChildIfAbsent(
    K key,
    V Function() ifAbsent,
  ) {
    final child = getChild(key);

    if (child == null) {
      final value = ifAbsent();
      return addChild(key, value);
    }
    return child;
  }
}
