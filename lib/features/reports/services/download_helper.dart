import 'download_helper_native.dart'
    if (dart.library.html) 'download_helper_web.dart';

Future<void> downloadExcelFile(
        List<int> bytes, String filename, String subject) =>
    downloadExcelFileImpl(bytes, filename, subject);
