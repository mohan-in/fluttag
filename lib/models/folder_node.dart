/// Represents a directory node in the folder tree.
class FolderNode {
  FolderNode({
    required this.path,
    required this.name,
    List<FolderNode>? children,
    this.isExpanded = false,
  }) : children = children ?? [];

  final String path;
  final String name;
  final List<FolderNode> children;
  bool isExpanded;
}
