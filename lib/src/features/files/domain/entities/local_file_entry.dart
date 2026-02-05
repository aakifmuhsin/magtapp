class LocalFileEntry {
  LocalFileEntry({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    required this.createdAt,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final String mimeType;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'path': path,
      'name': name,
      'sizeBytes': sizeBytes,
      'mimeType': mimeType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LocalFileEntry.fromJson(Map<String, dynamic> json) {
    return LocalFileEntry(
      path: json['path'] as String,
      name: json['name'] as String,
      sizeBytes: json['sizeBytes'] as int,
      mimeType: json['mimeType'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

