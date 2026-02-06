enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  cancelled,
}

class DownloadTask {
  DownloadTask({
    required this.id,
    required this.url,
    required this.fileName,
    required this.mimeType,
    this.totalBytes = -1,
    this.receivedBytes = 0,
    this.status = DownloadStatus.pending,
    this.savedPath,
    this.errorMessage,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  final String id;
  final String url;
  final String fileName;
  final String mimeType;
  final int totalBytes;
  final int receivedBytes;
  final DownloadStatus status;
  final String? savedPath;
  final String? errorMessage;
  final DateTime startedAt;

  double get progress =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : -1.0;

  bool get isActive =>
      status == DownloadStatus.pending || status == DownloadStatus.downloading;

  DownloadTask copyWith({
    String? id,
    String? url,
    String? fileName,
    String? mimeType,
    int? totalBytes,
    int? receivedBytes,
    DownloadStatus? status,
    String? savedPath,
    String? errorMessage,
    DateTime? startedAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      totalBytes: totalBytes ?? this.totalBytes,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      status: status ?? this.status,
      savedPath: savedPath ?? this.savedPath,
      errorMessage: errorMessage ?? this.errorMessage,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'url': url,
      'fileName': fileName,
      'mimeType': mimeType,
      'totalBytes': totalBytes,
      'receivedBytes': receivedBytes,
      'status': status.name,
      'savedPath': savedPath,
      'errorMessage': errorMessage,
      'startedAt': startedAt.toIso8601String(),
    };
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'] as String,
      url: json['url'] as String,
      fileName: json['fileName'] as String,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      totalBytes: json['totalBytes'] as int? ?? -1,
      receivedBytes: json['receivedBytes'] as int? ?? 0,
      status: DownloadStatus.values.byName(
        json['status'] as String? ?? 'pending',
      ),
      savedPath: json['savedPath'] as String?,
      errorMessage: json['errorMessage'] as String?,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
    );
  }
}
