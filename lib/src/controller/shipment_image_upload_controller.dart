import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:state_notifier/state_notifier.dart';
import 'package:uuid/uuid.dart';

import 'package:file_uploader/src/enum/image_group.dart';

import '../model/file_upload_info.dart';
import '../model/file_upload_status.dart';
import '../widgets/progress_snack_bar.dart';

part 'shipment_image_upload_state.dart';

class ShipmentImageUploadController
    extends StateNotifier<ShipmentImageUploadState> {
  ShipmentImageUploadController({
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
    UploadProgressSnackBarOptions? options,
  })  : _scaffoldMessengerKey = scaffoldMessengerKey,
        _options = options ?? const UploadProgressSnackBarOptions(),
        super(const ShipmentImageUploadState());

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;
  final UploadProgressSnackBarOptions _options;
  final _uuid = const Uuid();

  void uploadImages({
    required List<File> imageFiles,
    required ImageGroup imageGroup,
  }) async {
    if (state.isUploadInProgress) {
      developer.log('Cannot start upload while upload is inprogress');
      return;
    }

    final fileUploadInfos = imageFiles
        .map((e) => FileUploadInfo(
              id: _uuid.v4(),
              name: path.basename(e.path),
              file: e,
              imageGroup: imageGroup,
            ))
        .toList();

    switch (imageGroup) {
      case ImageGroup.product:
        state = state.copyWith(
          productImages: [...state.productImages, ...fileUploadInfos],
        );
        break;
      case ImageGroup.document:
        state = state.copyWith(
          docImages: [...state.docImages, ...fileUploadInfos],
        );
        break;
      case ImageGroup.cover:
        state = state.copyWith(
          coverImages: [...state.coverImages, ...fileUploadInfos],
        );
        break;
    }

    _handleUploadStart(fileUploadInfos);
  }

  void retryUploadImages({
    required List<FileUploadInfo> images,
  }) {
    if (state.isUploadInProgress) {
      developer.log('Cannot start retry while uploader inprogress');
      return;
    }

    ShipmentImageUploadState newState = ShipmentImageUploadState(
      productImages: state.productImages,
      docImages: state.docImages,
      coverImages: state.coverImages,
    );

    for (final image in images) {
      // Reset progress
      final updatedImage = image.copyWith(
        status: const FileUploadInprogress(progress: 0),
      );

      switch (image.imageGroup) {
        case ImageGroup.product:
          newState = newState.copyWith(
            productImages: newState.productImages
                .map((e) => e.id == image.id ? updatedImage : e)
                .toList(),
          );
          break;
        case ImageGroup.document:
          newState = newState.copyWith(
            docImages: newState.docImages
                .map((e) => e.id == image.id ? updatedImage : e)
                .toList(),
          );
          break;
        case ImageGroup.cover:
          newState = newState.copyWith(
            coverImages: newState.coverImages
                .map((e) => e.id == image.id ? updatedImage : e)
                .toList(),
          );
          break;
      }
    }

    state = newState;
    _handleUploadStart(images);
  }

  Future<void> deleteImage(FileUploadInfo image) async {
    switch (image.imageGroup) {
      case ImageGroup.product:
        state = state.copyWith(
          productImages:
              state.productImages.where((e) => e.id != image.id).toList(),
        );
        break;
      case ImageGroup.document:
        state = state.copyWith(
          docImages: state.docImages.where((e) => e.id != image.id).toList(),
        );
        break;
      case ImageGroup.cover:
        state = state.copyWith(
          coverImages:
              state.coverImages.where((e) => e.id != image.id).toList(),
        );
        break;
    }

    // Call delete image api
    if (image.status is FileUploadSuccess) {
      final remoteId = (image.status as FileUploadSuccess).remoteId;

      try {
        await _deleteProductImage(remoteId);
      } catch (e) {
        developer.log(e.toString());
      }
    }
  }

  /// Map<remoteId, url>
  void addUploadedImages({
    required List<Map<String, String?>> imageDataList,
    required ImageGroup imageGroup,
  }) {
    final images = imageDataList.map(
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
        state = state.copyWith(
          productImages: [...state.productImages, ...images],
        );
        break;
      case ImageGroup.document:
        state = state.copyWith(
          docImages: [...state.docImages, ...images],
        );
        break;
      case ImageGroup.cover:
        state = state.copyWith(
          coverImages: [...state.coverImages, ...images],
        );
        break;
    }
  }

  void _handleUploadStart(List<FileUploadInfo> images) {
    final imageIds = images.map((e) => e.id).toList();
    state = state.copyWith(uploadingImageIds: imageIds);

    if (images.isEmpty) return;

    for (final image in images) {
      _doUpload(
        image: image,
        onUploadProgress: _handleUploadProgress,
      );
    }

    _showSnackBar();
  }

  void _handleUploadProgress(String id, double progress) {
    final item = state.allImages.firstWhereOrNull((e) => e.id == id);
    if (item == null) return;

    final updatedItem = item.copyWith(
      status: FileUploadInprogress(progress: progress),
    );

    switch (item.imageGroup) {
      case ImageGroup.product:
        state = state.copyWith(
          productImages: state.productImages
              .map((e) => e.id == id ? updatedItem : e)
              .toList(),
        );
        break;
      case ImageGroup.document:
        state = state.copyWith(
          docImages:
              state.docImages.map((e) => e.id == id ? updatedItem : e).toList(),
        );
        break;
      case ImageGroup.cover:
        state = state.copyWith(
          coverImages: state.coverImages
              .map((e) => e.id == id ? updatedItem : e)
              .toList(),
        );
        break;
    }
  }

  void _handleUploadComplete(String id, FileUploadStatus result) {
    final item = state.allImages.firstWhereOrNull((e) => e.id == id);
    if (item == null) return;

    final updatedItem = item.copyWith(
      status: result,
    );

    switch (item.imageGroup) {
      case ImageGroup.product:
        state = state.copyWith(
          productImages: state.productImages
              .map((e) => e.id == id ? updatedItem : e)
              .toList(),
        );
        break;
      case ImageGroup.document:
        state = state.copyWith(
          docImages:
              state.docImages.map((e) => e.id == id ? updatedItem : e).toList(),
        );
        break;
      case ImageGroup.cover:
        state = state.copyWith(
          coverImages: state.coverImages
              .map((e) => e.id == id ? updatedItem : e)
              .toList(),
        );
        break;
    }
  }

  Future<void> _doUpload({
    required FileUploadInfo image,
    required void Function(String id, double progress) onUploadProgress,
  }) async {
    if (image.status is FileUploadSuccess) return;

    try {
      final result = await _uploadProductImage(
        image,
        onUploadProgress,
      );

      _handleUploadComplete(image.id, result);
    } catch (e, s) {
      _handleUploadComplete(
        image.id,
        FileUploadFailure(exception: e, stackTrace: s),
      );
    }
  }

  void _showSnackBar() {
    _scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: SnackBarContent(
            controller: this,
            options: _options,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _options.backgroundColor,
          dismissDirection: DismissDirection.none,
          padding: EdgeInsets.zero,
          duration: const Duration(hours: 1),
        ),
      );
  }

  void hideSnackBar() {
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  }

  Future<FileUploadStatus> _uploadProductImage(
    FileUploadInfo image,
    void Function(String id, double progress) onUploadProgress,
  ) async {
    double progress = 0;
    final rand = Random();

    while (progress < 1) {
      await Future.delayed(Duration(milliseconds: rand.nextInt(1000)));
      progress = progress + 0.1;
      onUploadProgress(image.id, progress);
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

  @override
  void dispose() {
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    super.dispose();
  }
}
