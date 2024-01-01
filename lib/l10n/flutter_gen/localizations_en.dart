import 'localizations.dart';

/// The translations for English (`en`).
class FileUploaderLocalizationsEn extends FileUploaderLocalizations {
  FileUploaderLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String filesUploaded(int uploaded, int total) {
    return '$uploaded/$total files uploaded';
  }

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get someFileFailToUpload => 'Some file fail to upload';

  @override
  String get retry => 'Retry';
}
