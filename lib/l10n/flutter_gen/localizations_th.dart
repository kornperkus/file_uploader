import 'localizations.dart';

/// The translations for Thai (`th`).
class FileUploaderLocalizationsTh extends FileUploaderLocalizations {
  FileUploaderLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String filesUploaded(int uploaded, int total) {
    return '$uploaded/$total อัปโหลดเสร็จสิ้น';
  }

  @override
  String get uploadFailed => 'อัปโหลดไม่สำเร็จ';

  @override
  String get someFileFailToUpload => 'บางไฟล์อัปโหลดไม่สำเร็จ';

  @override
  String get retry => 'ลองใหม่';
}
