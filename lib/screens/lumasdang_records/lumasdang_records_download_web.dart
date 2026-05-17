import 'dart:typed_data';
import 'dart:html' as html;

Future<void> triggerLumasdangDownload(Uint8List bytes, String fileName) async {
  final blob = html.Blob(<dynamic>[bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

