class BrowserTab {
  BrowserTab({
    required this.id,
    required this.url,
    this.title,
    this.isLoading = false,
    this.progress = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String url;
  final String? title;
  final bool isLoading;
  final double progress;
  final DateTime createdAt;

  BrowserTab copyWith({
    String? id,
    String? url,
    String? title,
    bool? isLoading,
    double? progress,
    DateTime? createdAt,
  }) {
    return BrowserTab(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'url': url,
      'title': title,
      'isLoading': isLoading,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BrowserTab.fromJson(Map<String, dynamic> json) {
    return BrowserTab(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String?,
      isLoading: json['isLoading'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
