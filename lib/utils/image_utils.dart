import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart'; // 임시 비활성화
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';

/// 이미지 관련 유틸리티 기능을 제공하는 클래스
class ImageUtils {
  /// 위젯을 이미지로 캡쳐
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      debugPrint('캡쳐 에러: $e');
      return null;
    }
  }

  /// Screenshot 위젯을 사용한 캡쳐
  static Future<Uint8List?> captureScreenshotWidget(
    ScreenshotController controller,
  ) async {
    try {
      return await controller.capture(pixelRatio: 3.0);
    } catch (e) {
      debugPrint('스크린샷 에러: $e');
      return null;
    }
  }

  /// 갤러리에 이미지 저장 - 임시로 Mock 구현
  static Future<String?> saveImageToGallery(Uint8List bytes) async {
    try {
      // 실제 저장 로직 대신 임시 처리
      debugPrint('갤러리 저장 기능이 일시적으로 비활성화되었습니다.');

      // 성공한 것처럼 처리
      return 'mock_file_path';

      // 아래는 원래 코드
      /*
      final status = await Permission.storage.request();
      if (status.isGranted) {
        final result = await ImageGallerySaver.saveImage(
          bytes,
          quality: 100,
          name: 'cupsy_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (result != null && result['isSuccess'] == true) {
          return result['filePath'];
        }
      }
      */
      return null;
    } catch (e) {
      debugPrint('갤러리 저장 에러: $e');
      return null;
    }
  }

  /// 저장 디렉토리 얻기
  static Future<Directory?> _getGalleryDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Android에서는 Pictures 디렉토리 사용
        return await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        // iOS에서는 Documents 디렉토리 사용
        return await getApplicationDocumentsDirectory();
      }
      return null;
    } catch (e) {
      debugPrint('갤러리 디렉토리 얻기 실패: $e');
      return null;
    }
  }

  /// 임시 파일로 저장 (공유용)
  static Future<File?> saveTempFile(Uint8List bytes, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint('임시 파일 저장 실패: $e');
      return null;
    }
  }

  /// 권한 요청 처리
  static Future<bool> _requestPermission() async {
    // 플랫폼별 권한 처리
    if (Platform.isAndroid) {
      // Android 13+ (API 33+)에서는 READ_MEDIA_IMAGES 사용
      if (await Permission.mediaLibrary.request().isGranted) {
        return true;
      }

      // 구버전 Android 또는 미디어 라이브러리 권한이 없는 경우 저장소 권한 요청
      if (await Permission.storage.request().isGranted) {
        return true;
      }
    } else if (Platform.isIOS) {
      // iOS에서는 사진 라이브러리 권한 확인
      if (await Permission.photos.request().isGranted) {
        return true;
      }
    }

    return false;
  }
}
