import 'package:equatable/equatable.dart';

abstract class FileUploadStatus extends Equatable {
  const FileUploadStatus();
}

class FileUploadInprogress extends FileUploadStatus with EquatableMixin {
  final double progress;

  const FileUploadInprogress({
    required this.progress,
  });

  @override
  List<Object> get props => [progress];
}

class FileUploadSuccess extends FileUploadStatus {
  final String remoteId;
  final String? url;

  const FileUploadSuccess({
    required this.remoteId,
    required this.url,
  });

  @override
  List<Object?> get props => [remoteId, url];
}

class FileUploadFailure extends FileUploadStatus {
  final Object exception;
  final StackTrace? stackTrace;

  const FileUploadFailure({
    required this.exception,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [exception, stackTrace];
}
