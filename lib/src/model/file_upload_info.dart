import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:file_uploader/src/enum/image_group.dart';
import 'file_upload_status.dart';

class FileUploadInfo extends Equatable {
  final String id;
  final String? name;
  final File? file;
  final ImageGroup imageGroup;
  final FileUploadStatus status;

  const FileUploadInfo({
    required this.id,
    required this.imageGroup,
    this.name,
    this.file,
    this.status = const FileUploadInprogress(progress: 0),
  });

  @override
  List<Object?> get props => [id, name, file, imageGroup, status];

  FileUploadInfo copyWith({
    String? id,
    String? name,
    File? file,
    ImageGroup? imageGroup,
    FileUploadStatus? status,
  }) {
    return FileUploadInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      file: file ?? this.file,
      imageGroup: imageGroup ?? this.imageGroup,
      status: status ?? this.status,
    );
  }
}
