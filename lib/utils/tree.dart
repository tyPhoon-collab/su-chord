class TreeNode<T> {
  TreeNode(this.value) : children = {};

  final T value;
  Set<TreeNode<T>> children;

  void addChild(TreeNode<T> child) {
    children.add(child);
  }

  TreeNode<T> putChildIfAbsent(T value, TreeNode<T> Function() ifAbsent) =>
      children.firstWhere((e) => e.value == value, orElse: () {
        final node = ifAbsent();
        addChild(node);
        return node;
      });
}
