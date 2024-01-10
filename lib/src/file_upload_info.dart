import 'dart:io';

import 'package:equatable/equatable.dart';

part 'file_upload_status.dart';

class FileUploadInfo extends Equatable {
  final String id;
  final String? name;
  final File? file;
  final FileUploadStatus status;

  const FileUploadInfo({
    required this.id,
    this.name,
    this.file,
    this.status = const FileUploadInprogress(progress: 0),
  });

  @override
  List<Object?> get props => [id, name, file, status];

  FileUploadInfo copyWith({
    String? id,
    String? name,
    File? file,
    FileUploadStatus? status,
  }) {
    return FileUploadInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      file: file ?? this.file,
      status: status ?? this.status,
    );
  }
}
