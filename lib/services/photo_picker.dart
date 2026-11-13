import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';

typedef PickedPhoto = ({Uint8List bytes, String mediaType});

/// 사진 고르기 함수 형태 (테스트에서 바꿔 끼우기용)
typedef PhotoPick = Future<PickedPhoto?> Function(BuildContext context);

/// 인식에 충분한 최대 변 길이. 더 크게 보내도 정확도는 비슷하고 전송량만 늘어난다.
const _maxEdge = 1568.0;

/// 카메라(모바일만) 또는 앨범에서 사진 한 장을 고른다. 취소하면 null.
Future<PickedPhoto?> pickPhoto(BuildContext context) async {
  final canUseCamera = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  var source = ImageSource.gallery;
  if (canUseCamera) {
    final picked = await showGoldSheet<ImageSource>(
      context,
      title: '사진 가져오기',
      body: (ctx, _) => Column(children: [
        GoldButton('카메라로 촬영', upper: false, onTap: () => Navigator.pop(ctx, ImageSource.camera)),
        GoldButton('앨범에서 선택', ghost: true, upper: false, margin: const EdgeInsets.only(top: 10), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
      ]),
    );
    if (picked == null) return null;
    source = picked;
  }
  final file = await ImagePicker().pickImage(source: source, maxWidth: _maxEdge, maxHeight: _maxEdge, imageQuality: 85);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final type = imageMediaType(bytes);
  if (type == null) {
    AppState.I.toast('JPG·PNG·WEBP 사진만 인식할 수 있어요');
    return null;
  }
  return (bytes: bytes, mediaType: type);
}

/// 파일 앞부분(매직 넘버)으로 이미지 형식을 판별. JPG·PNG·GIF·WEBP 외에는 null.
String? imageMediaType(Uint8List b) {
  bool at(int i, List<int> sig) => b.length >= i + sig.length && [for (var k = 0; k < sig.length; k++) b[i + k] == sig[k]].every((x) => x);
  if (at(0, [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (at(0, [0x89, 0x50, 0x4E, 0x47])) return 'image/png';
  if (at(0, [0x47, 0x49, 0x46, 0x38])) return 'image/gif';
  if (at(0, [0x52, 0x49, 0x46, 0x46]) && at(8, [0x57, 0x45, 0x42, 0x50])) return 'image/webp';
  return null;
}
