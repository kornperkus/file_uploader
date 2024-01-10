import 'dart:developer' as developer;
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import 'file_upload_info.dart';
import 'widgets/progress_snack_bar.dart';

typedef UploadFileTask = Future<FileUploadStatus> Function(
  FileUploadInfo fileUploadInfo,
  void Function(String id, double progress) onUploadProgress,
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
    if (value.isUploadInProgress) {
      developer.log('Cannot start upload while upload is inprogress');
      return;
    }

    final fileUploadInfos = files
        .map((file) => FileUploadInfo(
              id: _uuid.v4(),
              name: path.basename(file.path),
              file: file,
            ))
        .toList();

    value = FileUploadState(
      files: [...value.files, ...fileUploadInfos],
    );

    _handleUploadStart(context, fileUploadInfos);
  }

  void retryUpload({
    required BuildContext context,
    required List<FileUploadInfo> files,
  }) {
    if (value.isUploadInProgress) {
      developer.log('Cannot start retry while uploader inprogress');
      return;
    }

    final fileIds = files.map((e) => e.id).toList();

    // Reset progress
    final newFiles = value.files.map(
      (file) {
        if (fileIds.contains(file.id)) {
          return file.copyWith(
            status: const FileUploadInprogress(progress: 0),
          );
        }
        return file;
      },
    ).toList();

    value = FileUploadState(
      files: newFiles,
    );

    _handleUploadStart(context, newFiles);
  }

  Future<void> delete(FileUploadInfo fileUploadInfo) async {
    value = FileUploadState(
      files: value.files.where((e) => e.id != fileUploadInfo.id).toList(),
    );

    if (fileUploadInfo.status is FileUploadSuccess) {
      final remoteId = (fileUploadInfo.status as FileUploadSuccess).remoteId;

      try {
        await _deleteFileTask.call(remoteId);
      } catch (e) {
        developer.log(e.toString());
      }
    }
  }

  /// Map<remoteId, url>
  void addUploadedFiles({
    required List<Map<String, String?>> files,
  }) {
    final uploadedFiles = files.map(
      (file) => FileUploadInfo(
        id: _uuid.v4(),
        status: FileUploadSuccess(
          remoteId: file['id'] as String,
          url: file['url'],
        ),
      ),
    );

    value = FileUploadState(
      files: [...value.files, ...uploadedFiles],
    );
  }

  void _handleUploadStart(BuildContext context, List<FileUploadInfo> files) {
    if (files.isEmpty) return;

    for (int i = 0; i < files.length; i++) {
      _doUpload(
        uploadFileInfo: files[i],
        onUploadProgress: _handleUploadProgress,
      );
    }

    _progressSnackBar.showSnackBar(context: context, controller: this);
  }

  void _handleUploadProgress(String id, double progress) {
    final item = value.files.firstWhereOrNull((e) => e.id == id);
    if (item == null) return;

    final newFiles = value.files.map((file) {
      if (file.id == id) {
        return item.copyWith(
          status: FileUploadInprogress(progress: progress),
        );
      }
      return file;
    }).toList();

    value = FileUploadState(files: newFiles);
  }

  void _handleUploadComplete(String id, FileUploadStatus result) {
    final item = value.files.firstWhereOrNull((e) => e.id == id);
    if (item == null) return;

    final newFiles = value.files.map((file) {
      if (file.id == id) {
        return item.copyWith(
          status: result,
        );
      }
      return file;
    }).toList();

    value = FileUploadState(files: newFiles);

    if (value.isUploadIdle) {
      _handleUploadCompleteAll();
    }
  }

  void _handleUploadCompleteAll() {
    _onUploadEnd?.call();
  }

  void closeSnackBar() {
    _progressSnackBar.hideSnackBar();
  }

  List<FileUploadInfo> getErrorFiles() {
    return value.files.where((e) => e.status is FileUploadFailure).toList();
  }

  Future<void> _doUpload({
    required FileUploadInfo uploadFileInfo,
    required void Function(String id, double progress) onUploadProgress,
  }) async {
    if (uploadFileInfo.status is FileUploadSuccess) return;

    try {
      final result = await _uploadFileTask.call(
        uploadFileInfo,
        onUploadProgress,
      );

      _handleUploadComplete(uploadFileInfo.id, result);
    } catch (e, s) {
      _handleUploadComplete(
        uploadFileInfo.id,
        FileUploadFailure(exception: e, stackTrace: s),
      );
    }
  }
}

class FileUploadState extends Equatable {
  final List<FileUploadInfo> files;

  bool get isUploadInProgress {
    final result = files.any((e) => e.status is FileUploadInprogress);
    return result;
  }

  bool get isUploadIdle {
    final result = !isUploadInProgress;
    return result;
  }

  bool get hasError {
    final result = files.any((e) => e.status is FileUploadFailure);
    return result;
  }

  int get uploadSuccessCount {
    final result = files.where((e) => e.status is FileUploadSuccess).length;
    return result;
  }

  const FileUploadState({
    this.files = const [],
  });

  @override
  List<Object> get props => [files];
}
