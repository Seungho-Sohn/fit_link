import 'dart:typed_data';

import '../data/equipment.dart';

/// 인식 후보 하나: 기구 모델과 확신도(0~1)
typedef GearCandidate = ({GearModel model, double confidence});

/// 기구 사진 → 후보 목록(확신도 높은 순). 사용자가 후보 중에서 고르거나 직접 찾는다.
///
/// 지금은 [DemoGearRecognizer]뿐이다. AI 인식(서버)을 붙일 때는 이 인터페이스를 구현해
/// [GearFlow]에 넘기면 되고, 후보 확인 화면은 그대로 쓴다.
abstract interface class GearRecognizer {
  /// true면 화면에 "데모 후보"라고 표시한다.
  bool get isDemo;
  Future<List<GearCandidate>> recognize(Uint8List image, String mediaType);
}

/// AI 연결 전 데모: 사진과 관계없이 정해진 후보를 돌려준다 (분석 화면 연출과 맞춰 잠시 기다림).
class DemoGearRecognizer implements GearRecognizer {
  final Duration delay;
  const DemoGearRecognizer({this.delay = const Duration(milliseconds: 2800)});

  @override
  bool get isDemo => true;

  @override
  Future<List<GearCandidate>> recognize(Uint8List image, String mediaType) async {
    await Future<void>.delayed(delay);
    return [
      (model: gearById('hs-pl-pulldown'), confidence: .82),
      (model: gearById('newtech-pulldown'), confidence: .41),
      (model: gearById('hs-sel-pulldown'), confidence: .23),
    ];
  }
}
