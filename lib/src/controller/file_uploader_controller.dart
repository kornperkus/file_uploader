import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import 'package:file_uploader/src/enum/image_group.dart';

import '../model/file_upload_info.dart';
import '../model/file_upload_status.dart';
import '../widgets/progress_snack_bar.dart';

part 'file_uploader_state.dart';

class FileUploadController extends ValueNotifier<FileUploadState> {
  final void Function()? _onUploadEnd;

  FileUploadController({
    void Function()? onUploadEnd,
  })  : _onUploadEnd = onUploadEnd,
        super(const FileUploadState());

  final _uuid = const Uuid();
  final _progressSnackBar = UploadProgressSnackBar();

  void upload({
    required BuildContext context,
    required List<File> files,
    required ImageGroup imageGroup,
  }) async {
    if (value.isUploadInProgress) {
      developer.log('Cannot start upload while upload is inprogress');
      return;
    }

    final fileUploadInfos = files
        .map((e) => FileUploadInfo(
              id: _uuid.v4(),
              name: path.basename(e.path),
              file: e,
              imageGroup: imageGroup,
            ))
        .toList();

    switch (imageGroup) {
      case ImageGroup.product:
        value = value.copyWith(
          productImages: [...value.productImages, ...fileUploadInfos],
        );
        break;
      case ImageGroup.document:
        value = value.copyWith(
          docImages: [...value.docImages, ...fileUploadInfos],
        );
        break;
      case ImageGroup.truckCover:
        value = value.copyWith(
          coverImages: [...value.coverImages, ...fileUploadInfos],
        );
        break;
    }

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

    FileUploadState newState = FileUploadState(
      productImages: value.productImages,
      docImages: value.docImages,
      coverImages: value.coverImages,
    );

    for (final file in files) {
      // Reset progress
      final updatedItem = file.copyWith(
        status: const FileUploadInprogress(progress: 0),
      );

      switch (file.imageGroup) {
        case ImageGroup.product:
          newState = newState.copyWith(
            productImages: newState.productImages
                .map((e) => e.id == file.id ? updatedItem : e)
                .toList(),
          );
          break;
        case ImageGroup.document:
          newState = newState.copyWith(
            docImages: newState.docImages
                .map((e) => e.id == file.id ? updatedItem : e)
                .toList(),
          );
          break;
        case ImageGroup.truckCover:
          newState = newState.copyWith(
            coverImages: newState.coverImages
                .map((e) => e.id == file.id ? updatedItem : e)
                .toList(),
          );
          break;
      }
    }

    value = newState;
    _handleUploadStart(context, files);
  }

  Future<void> delete(FileUploadInfo fileUploadInfo) async {
    switch (fileUploadInfo.imageGroup) {
      case ImageGroup.product:
        value = value.copyWith(
          productImages: value.productImages
              .where((e) => e.id != fileUploadInfo.id)
              .toList(),
        );
        break;
      case ImageGroup.document:
        value = value.copyWith(
          docImages:
              value.docImages.where((e) => e.id != fileUploadInfo.id).toList(),
        );
        break;
      case ImageGroup.truckCover:
        value = value.copyWith(
          coverImages: value.coverImages
              .where((e) => e.id != fileUploadInfo.id)
              .toList(),
        );
        break;
    }

    if (fileUploadInfo.status is FileUploadSuccess) {
      final remoteId = (fileUploadInfo.status as FileUploadSuccess).remoteId;

      try {
        await _deleteProductImage(remoteId);
      } catch (e) {
        developer.log(e.toString());
      }
    }
  }

  /// Map<remoteId, url>
  void addUploadedFiles({
    required List<Map<String, String?>> files,
    required ImageGroup imageGroup,
  }) {
    final uploadedFiles = files.map(
      (e) => FileUploadInfo(
        id: _uuid.v4(),
        imageGroup: imageGroup,
        status: FileUploadSuccess(
          remoteId: e['id'] as String,
          url: e['url'],
        ),
      ),
    );

    switch (imageGroup) {
      case ImageGroup.product:
        value = value.copyWith(
          productImages: [...value.productImages, ...uploadedFiles],
        );
        break;
      case ImageGroup.document:
        value = value.copyWith(
          docImages: [...value.docImages, ...uploadedFiles],
        );
        break;
      case ImageGroup.truckCover:
        value = value.copyWith(
          coverImages: [...value.coverImages, ...uploadedFiles],
        );
        break;
    }
  }

  void _handleUploadStart(BuildContext context, List<FileUploadInfo> files) {
    final fileIds = files.map((e) => e.id).toList();
    value = value.copyWith(uploadingImageIds: fileIds);

    if (files.isEmpty) return;

    for (final file in files) {
      _doUpload(
        uploadFileInfo: file,
        onUploadProgress: _handleUploadProgress,
      );
    }

    _progressSnackBar.showSnackBar(context: context, controller: this);
  }

  void _handleUploadProgress(String id, double progress) {
    final item = value.allImages.firstWhereOrNull((e) => e.id == id);
    if (item == null) return;

    final updatedItem = item.copyWith(
      status: FileUploadInprogress(progress: progress),
    );

    switch (item.imageGroup) {
      case ImageGroup.product:
        value = value.copyWith(
          productImages: value.productImages
              .map((e) => e.id == id ? updatedItem : e)
              .toList(),
        );
        break;
      case ImageGroup.document:
        value = value.copyWith(
          docImages:
              value.docImages.map((e) => e.id == id ? updatedItem : e).toList(),
        );
        break;
      case ImageGroup.truckCover:
        value = value.copyWith(
          coverImages: value.coverImages
              .map((e) => e.id == id ? updatedItem : e)
              .toList(),
        );
        break;
    }
  }

  void _handleUploadComplete(String id, FileUploadStatus result) {
    final item = value.allImages.firstWhereOrNull((e) => e.id == id);
    if (item == null) return;

    final updatedItem = item.copyWith(
      status: result,
    );

    switch (item.imageGroup) {
      case ImageGroup.product:
        value = value.copyWith(
          productImages: value.productImages
              .map((e) => e.id == id ? updatedItem : e)
              .toList(),
        );
        break;
      case ImageGroup.document:
        value = value.copyWith(
          docImages:
              value.docImages.map((e) => e.id == id ? updatedItem : e).toList(),
        );
        break;
      case ImageGroup.truckCover:
        value = value.copyWith(
          coverImages: value.coverImages
              .map((e) => e.id == id ? updatedItem : e)
              .toList(),
        );
        break;
    }

    if (value.isUploadIdle) {
      _handleUploadCompleteAll();
    }
  }

  void _handleUploadCompleteAll() {
    _onUploadEnd?.call();
  }

  void closeSnackBar(BuildContext context) {
    _progressSnackBar.hideSnackBar(context);
  }

  Future<void> _doUpload({
    required FileUploadInfo uploadFileInfo,
    required void Function(String id, double progress) onUploadProgress,
  }) async {
    if (uploadFileInfo.status is FileUploadSuccess) return;

    try {
      final result = await _uploadProductImage(
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

  Future<FileUploadStatus> _uploadProductImage(
    FileUploadInfo fileUploadInfo,
    void Function(String id, double progress) onUploadProgress,
  ) async {
    double progress = 0;
    final rand = Random();

    while (progress < 1) {
      await Future.delayed(Duration(milliseconds: rand.nextInt(1000)));
      progress = progress + 0.1;
      onUploadProgress(fileUploadInfo.id, progress);
    }

    if (Random().nextBool()) {
      return FileUploadSuccess(remoteId: _uuid.v4(), url: null);
    } else {
      return FileUploadFailure(exception: Exception());
    }
  }

  Future<void> _deleteProductImage(String id) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
