import 'dart:io';

import 'package:equatable/equatable.dart';

class FileUploadInfo extends Equatable {
  final String id;
  final String? name;
  final File? file;
  final String? url;
  final int progress;
  final Object? error;

  bool get isUploaded => progress >= 100 || url != null;

  const FileUploadInfo({
    required this.id,
    this.name,
    this.file,
    this.url,
    this.error,
    this.progress = 0,
  });

  @override
  List<Object?> get props {
    return [
      id,
      name,
      file,
      url,
      progress,
      error,
    ];
  }

  FileUploadInfo copyWith({
    String? id,
    String? name,
    File? file,
    String? url,
    int? progress,
    Object? error,
  }) {
    return FileUploadInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      file: file ?? this.file,
      url: url ?? this.url,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}
