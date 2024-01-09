import 'dart:developer' as developer;
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:file_uploader/file_uploader.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

typedef FileUploadProgress = void Function({
  required String id,
  required int progress,
  String? resultUrl,
  Object? resultError,
});

typedef UploadFileTask = Future<String?> Function(
  FileUploadInfo fileUploadInfo,
  FileUploadProgress uploadProgress,
);

typedef DeleteFileTask = Future Function(
  String id,
);

class FileUploadController extends ValueNotifier<FileUploadState> {
  final UploadFileTask _uploadFileTask;
  final DeleteFileTask _deleteFileTask;
  final void Function()? _onUploadEnd;

  FileUploadController({
    required UploadFileTask uploadFileTask,
    required DeleteFileTask deleteFileTask,
    void Function()? onUploadEnd,
  })  : _uploadFileTask = uploadFileTask,
        _deleteFileTask = deleteFileTask,
        _onUploadEnd = onUploadEnd,
        super(const FileUploadState());

  final _uuid = const Uuid();
  final _progressSnackBar = UploadProgressSnackBar();

  void upload({
    required BuildContext context,
    required List<File> files,
  }) async {
    if (!value.isUploaded) {
      developer.log('Cannot start upload while uploader inprogress');
      return;
    }

    final fileUploadInfos = files.map((file) => FileUploadInfo(
          id: _uuid.v4(),
          name: path.basename(file.path),
          file: file,
        ));
    final newFiles = [...value.files, ...fileUploadInfos];

    value = FileUploadState(
      files: newFiles,
      uploading:
          newFiles.where((e) => e.progress == 0 && e.url == null).toList(),
    );

    _handleUploadStart(context);
  }

  void retryUpload({
    required BuildContext context,
    required List<FileUploadInfo> files,
  }) {
    if (!value.isUploaded) {
      developer.log('Cannot start retry while uploader inprogress');
      return;
    }

    final fileIds = files.map((e) => e.id).toList();

    // Reset progress
    final newFiles = value.files.map(
      (file) {
        if (fileIds.contains(file.id)) {
          return FileUploadInfo(
            id: file.id,
            name: file.name,
            file: file.file,
          );
        }
        return file;
      },
    ).toList();

    value = FileUploadState(
      files: newFiles,
      uploading: newFiles.where((e) => fileIds.contains(e.id)).toList(),
    );

    _handleUploadStart(context);
  }

  Future<void> delete(String id) async {
    value = FileUploadState(
      files: value.files.where((e) => e.id != id).toList(),
      uploading: value.uploading.where((e) => e.id != id).toList(),
    );

    try {
      await _deleteFileTask.call(id);
    } catch (e) {
      developer.log(e.toString());
    }
  }

  void addUploadedFiles({
    required List<String> fileUrls,
  }) {
    const uuid = Uuid();
    final uploadedFiles = fileUrls.map(
      (url) => FileUploadInfo(
        id: uuid.v4(),
        url: url,
        progress: 100,
      ),
    );

    value = FileUploadState(
      files: [...value.files, ...uploadedFiles],
      uploading: value.uploading,
    );
  }

  void _handleUploadStart(BuildContext context) {
    if (value.uploading.isEmpty) return;

    for (int i = 0; i < value.uploading.length; i++) {
      _doUpload(
        uploadFileInfo: value.uploading[i],
        uploadProgress: _handleUploadProgress,
      );
    }

    _progressSnackBar.showSnackBar(context: context, controller: this);
  }

  void _handleUploadProgress({
    required String id,
    required int progress,
    String? resultUrl,
    Object? resultError,
  }) {
    final index = value.uploading.indexWhere((e) => e.id == id);

    if (index != -1) {
      FileUploadInfo item = value.uploading[index];
      item = item.copyWith(
        progress: progress,
        url: resultUrl,
        error: resultError,
      );

      value = FileUploadState(
        files: value.files.map((e) => e.id == id ? item : e).toList(),
        uploading: value.uploading.map((e) => e.id == id ? item : e).toList(),
      );
    }

    if (value.isUploaded) {
      _handleUploadEnd();
    }
  }

  void _handleUploadEnd() {
    _onUploadEnd?.call();
  }

  void closeSnackBar() {
    _progressSnackBar.hideSnackBar();
  }

  List<FileUploadInfo> getErrorFiles() {
    return value.files.where((e) => e.error != null).toList();
  }

  Future<void> _doUpload({
    required FileUploadInfo uploadFileInfo,
    required FileUploadProgress uploadProgress,
  }) async {
    if (uploadFileInfo.isUploaded) return;

    try {
      final result = await _uploadFileTask.call(
        uploadFileInfo,
        uploadProgress,
      );

      // Send finish progress
      if (result != null) {
        uploadProgress(
          id: uploadFileInfo.id,
          progress: 100,
          resultUrl: result,
        );
      }
    } catch (e) {
      uploadProgress(
        id: uploadFileInfo.id,
        progress: 0,
        resultError: e,
      );
    }
  }
}

class FileUploadState extends Equatable {
  final List<FileUploadInfo> files;
  final List<FileUploadInfo> uploading;

  bool get isUploaded => uploading.every((e) => e.isUploaded);

  bool get hasError => files.any((e) => e.error != null);

  int get uploadingCount => uploading.length;

  int get uploadedCount =>
      uploading.where((e) => e.isUploaded && e.error == null).length;

  const FileUploadState({
    this.files = const [],
    this.uploading = const [],
  });

  @override
  List<Object> get props => [
        files,
        uploading,
      ];
}
