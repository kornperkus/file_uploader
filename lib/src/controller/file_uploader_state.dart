part of 'file_uploader_controller.dart';

class FileUploadState extends Equatable {
  final List<FileUploadInfo> productImages;
  final List<FileUploadInfo> docImages;
  final List<FileUploadInfo> coverImages;
  final List<String> uploadingImageIds;

  List<FileUploadInfo> get allImages => productImages + docImages + coverImages;

  List<FileUploadInfo> get uploadingImages =>
      allImages.where((e) => uploadingImageIds.contains(e.id)).toList();

  List<FileUploadInfo> get errorImages {
    final result =
        allImages.where((e) => e.status is FileUploadFailure).toList();
    return result;
  }

  bool get isUploadInProgress {
    final result = allImages.any((e) => e.status is FileUploadInprogress);
    return result;
  }

  bool get isUploadIdle {
    final result = !isUploadInProgress;
    return result;
  }

  bool get hasError {
    final result = allImages.any((e) => e.status is FileUploadFailure);
    return result;
  }

  int get uploadingSuccessCount {
    final result =
        uploadingImages.where((e) => e.status is FileUploadSuccess).length;
    return result;
  }

  int get uploadingTotalCount {
    final result = uploadingImageIds.length;
    return result;
  }

  const FileUploadState({
    this.productImages = const [],
    this.docImages = const [],
    this.coverImages = const [],
    this.uploadingImageIds = const [],
  });

  @override
  List<Object> get props =>
      [productImages, docImages, coverImages, uploadingImageIds];

  FileUploadState copyWith({
    List<FileUploadInfo>? productImages,
    List<FileUploadInfo>? docImages,
    List<FileUploadInfo>? coverImages,
    List<String>? uploadingImageIds,
  }) {
    return FileUploadState(
      productImages: productImages ?? this.productImages,
      docImages: docImages ?? this.docImages,
      coverImages: coverImages ?? this.coverImages,
      uploadingImageIds: uploadingImageIds ?? this.uploadingImageIds,
    );
  }
}
