import 'package:uuid/uuid.dart';

import 'file_source.dart';

class LocalFileEntry {
  LocalFileEntry({
    String? id,
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    required this.source,
    this.sourceUrl,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String path;
  final String name;
  final int sizeBytes;
  final String mimeType;
  final FileSource source;
  final String? sourceUrl;
  final DateTime createdAt;

  LocalFileEntry copyWith({
    String? id,
    String? path,
    String? name,
    int? sizeBytes,
    String? mimeType,
    FileSource? source,
    String? sourceUrl,
    DateTime? createdAt,
  }) {
    return LocalFileEntry(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      source: source ?? this.source,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'path': path,
      'name': name,
      'sizeBytes': sizeBytes,
      'mimeType': mimeType,
      'source': source.name,
      'sourceUrl': sourceUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LocalFileEntry.fromJson(Map<String, dynamic> json) {
    return LocalFileEntry(
      id: json['id'] as String?,
      path: json['path'] as String,
      name: json['name'] as String,
      sizeBytes: json['sizeBytes'] as int,
      mimeType: json['mimeType'] as String,
      source: FileSource.values.byName(json['source'] as String? ?? 'picked'),
      sourceUrl: json['sourceUrl'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
