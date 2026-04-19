import 'package:flutter/services.dart';

class NativeShareService {
  NativeShareService._();

  static const MethodChannel _channel = MethodChannel(
    'study_pomodoro_record/share',
  );

  static Future<void> shareFiles(
    List<String> paths, {
    String? text,
    String? subject,
  }) async {
    if (paths.isEmpty) {
      throw ArgumentError('至少需要一个可分享的文件');
    }

    await _channel.invokeMethod<void>('shareFiles', {
      'paths': paths,
      'text': text,
      'subject': subject,
    });
  }
}
