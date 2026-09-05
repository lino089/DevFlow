class FileNode {
  final String name;
  final String fullPath;
  final String relativePath;
  final bool isDirectory;
  final List<FileNode> children;
  final bool isExpanded;
  final int? sizeBytes;

  const FileNode({
    required this.name,
    required this.fullPath,
    required this.relativePath,
    required this.isDirectory,
    this.children = const [],
    this.isExpanded = false,
    this.sizeBytes,
  });

  FileNode copyWith({
    String? name,
    String? fullPath,
    String? relativePath,
    bool? isDirectory,
    List<FileNode>? children,
    bool? isExpanded,
    int? sizeBytes,
  }) {
    return FileNode(
      name: name ?? this.name,
      fullPath: fullPath ?? this.fullPath,
      relativePath: relativePath ?? this.relativePath,
      isDirectory: isDirectory ?? this.isDirectory,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }
}
