import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadExcelFileImpl(
    List<int> bytes, String filename, String subject) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      ],
      subject: subject,
      text: 'Workly Work Report: $subject',
    ),
  );
}
