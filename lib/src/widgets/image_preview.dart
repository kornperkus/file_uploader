import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_uploader/l10n/flutter_gen/localizations.dart';
import 'package:file_uploader/l10n/flutter_gen/localizations_en.dart';

import '../model/file_upload_info.dart';
import '../model/file_upload_status.dart';

class UploadImageThumbnail extends StatelessWidget {
  final File? file;
  final String? imageUrl;

  const UploadImageThumbnail({
    Key? key,
    this.file,
    this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, boxConstraints) {
        final width = boxConstraints.maxHeight;
        final cacheWidth = _getImageCacheSize(context, width);

        if (file != null) {
          return Image.file(
            file!,
            fit: BoxFit.cover,
            width: width,
            cacheWidth: cacheWidth,
          );
        }

        if (imageUrl != null) {
          return Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            width: width,
            cacheWidth: cacheWidth,
          );
        }

        return SizedBox(
          width: width,
          height: width,
          child: const Icon(
            Icons.warning,
            size: 30,
          ),
        );
      },
    );
  }

  int _getImageCacheSize(BuildContext context, double widgetSize) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    return (devicePixelRatio * widgetSize).round();
  }
}

class UploadImagePreview extends StatelessWidget {
  final FileUploadInfo fileUploadInfo;
  final VoidCallback? onRetryUploadPressed;
  final VoidCallback? onDeletedPressed;

  const UploadImagePreview({
    Key? key,
    required this.fileUploadInfo,
    required this.onRetryUploadPressed,
    required this.onDeletedPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (fileUploadInfo.status is FileUploadFailure) {
      return _ImageItemUploadFailed(
        onRetryPressed: onRetryUploadPressed,
        onImagesDeleted: onDeletedPressed,
      );
    }

    if (fileUploadInfo.status is FileUploadSuccess) {
      return _ImageItemUploadSuccess(
        file: fileUploadInfo.file,
        url: (fileUploadInfo.status as FileUploadSuccess).url,
        onImagesDeleted: onDeletedPressed,
      );
    }

    return _ImageItemUploading(
      file: fileUploadInfo.file,
    );
  }
}

/// กำลังอัปโหลด
class _ImageItemUploading extends StatelessWidget {
  final File? file;

  const _ImageItemUploading({
    Key? key,
    required this.file,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          children: [
            Center(
              child: Opacity(
                opacity: 0.5,
                child: UploadImageThumbnail(
                  file: file,
                  imageUrl: null,
                ),
              ),
            ),
            const Center(
              child: Icon(
                Icons.cloud_upload,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// อัปโหลดล้มเหลว
class _ImageItemUploadFailed extends StatelessWidget {
  final VoidCallback? onRetryPressed;
  final VoidCallback? onImagesDeleted;

  const _ImageItemUploadFailed({
    Key? key,
    required this.onRetryPressed,
    required this.onImagesDeleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations =
        FileUploaderLocalizations.of(context) ?? FileUploaderLocalizationsEn();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    localizations.uploadFailed,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onRetryPressed,
                    child: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: onImagesDeleted,
              child: Container(
                margin: const EdgeInsets.all(4.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// อัปโหลดสำเร็จ (แสดงรูปภาพ)
class _ImageItemUploadSuccess extends StatelessWidget {
  final File? file;
  final String? url;
  final VoidCallback? onImagesDeleted;

  const _ImageItemUploadSuccess({
    Key? key,
    required this.file,
    required this.url,
    required this.onImagesDeleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          children: [
            Center(
              child: UploadImageThumbnail(
                file: file,
                imageUrl: url,
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: onImagesDeleted,
                child: Container(
                  margin: const EdgeInsets.all(4.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
