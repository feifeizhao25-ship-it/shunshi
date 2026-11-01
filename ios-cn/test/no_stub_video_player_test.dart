// 复测 B29：视频播放器是桩实现（VideoPlayerController 调用被注释掉、界面写着「需安装 video_player」），
// 仓库里没有任何视频素材，也没有任何页面使用它。没有视频功能就不能留一个假的播放器。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no stub video player is shipped in lib/', () {
    final stubs = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = entity.readAsStringSync();
      if (entity.path.endsWith('video_player.dart') ||
          text.contains('ShunshiVideoPlayer') ||
          text.contains('需安装 video_player') ||
          text.contains('// _innerController = VideoPlayerController')) {
        stubs.add(entity.path);
      }
    }
    expect(stubs, isEmpty);
  });

  test('no unused video_player dependency is declared', () {
    expect(File('pubspec.yaml').readAsStringSync(), isNot(contains('video_player')));
  });
}
