import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../data/equipment.dart';
import '../data/mock_data.dart';
import '../services/directions.dart';
import '../services/gear_recognizer.dart';
import '../services/location.dart';
import '../services/photo_picker.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/gym_map.dart';

const _filters = ['동일 모델만', '거리순', '평점순', '24시간'];

/// 헬스장 찾기 탭 (시그니처 기능): 기구 사진(또는 직접 선택) → 기구 확인 → 같은 기구가 있는 헬스장 매칭 → 지도 → 확정
///
/// 1 사진 · 2 분석 · 3 기구 확인(인식 후보 또는 직접 찾기) · 4 헬스장 매칭 · 5 지도 · 6 확정.
/// 1단계에서 "오늘 할 운동으로 찾기"(F-SIG-7: 루틴의 운동을 모두 할 수 있는 헬스장)로 갈 수 있고,
/// "내 이용권"(F-SIG-8)으로 고른 체인 지점만 찾을 수 있다 (`AppState.myChains`).
/// 인식은 [GearRecognizer]가 후보를 주고 사용자가 고르는 방식이라, AI를 붙여도 화면은 그대로다.
/// 기구·헬스장 데이터와 매칭 규칙은 lib/data/equipment.dart.
class GearFlow extends StatefulWidget {
  final GearRecognizer recognizer;

  /// 테스트에서 주입: 사진 고르기(기본은 카메라·앨범), 위치 조회, 지도 타일 표시 여부
  final PhotoPick? pick;
  final Future<MyLocation> Function() locate;
  final bool mapTiles;
  const GearFlow({super.key, this.recognizer = const DemoGearRecognizer(), this.pick, this.locate = currentLocation, this.mapTiles = true});
  @override
  State<GearFlow> createState() => _GearFlowState();
}

class _GearFlowState extends State<GearFlow> {
  int step = 1;
  PickedPhoto? photo;
  List<GearCandidate>? candidates; // 분석 결과 (null이면 분석 중)
  String? error;
  bool browsing = false; // 3단계: 인식 후보 대신 카탈로그에서 직접 찾기
  GearCategory browseCategory = GearCategory.pulldown;
  GearModel? chosen;
  int filter = 1; // 거리순: 처음엔 모든 헬스장을 가까운 순으로
  MyLocation? loc;
  String? selectedGym;
  int _run = 0; // 오래된 분석 결과를 버리기 위한 번호
  // 오늘 할 운동으로 찾기 (F-SIG-7)
  bool routine = false, routineResults = false;
  final Set<String> plan = {}; // 고른 운동 id
  String? routineGym;

  AppState get s => AppState.I;
  LatLng get here => loc?.pos ?? gangnamStation;

  void go(int n) {
    setState(() => step = n);
    if (n >= 4 && loc == null) _locate();
  }

  Future<void> _locate() async {
    final l = await widget.locate();
    if (mounted) setState(() => loc = l);
  }

  /// 사진을 고르고 분석을 시작한다. 취소하면 그대로.
  Future<void> _pick() async {
    final p = await (widget.pick ?? pickPhoto)(context);
    if (p == null || !mounted) return;
    setState(() {
      photo = p;
      chosen = null;
      browsing = false;
      step = 2;
    });
    await _analyze();
  }

  Future<void> _analyze() async {
    final p = photo;
    if (p == null) return;
    final run = ++_run;
    setState(() {
      candidates = null;
      error = null;
    });
    try {
      final c = await widget.recognizer.recognize(p.bytes, p.mediaType);
      if (!mounted || run != _run) return;
      setState(() {
        candidates = c;
        chosen = c.isEmpty ? null : c.first.model;
        browsing = c.isEmpty; // 후보가 없으면 바로 직접 찾기
      });
    } catch (_) {
      if (mounted && run == _run) setState(() => error = '기구를 분석하지 못했어요. 다시 시도하거나 직접 찾아 주세요.');
    }
  }

  /// 사진 없이 카탈로그에서 직접 찾기
  void _browse() {
    _run++; // 진행 중인 분석은 버림
    setState(() {
      browsing = true;
      browseCategory = chosen?.category ?? browseCategory;
      step = 3;
    });
  }

  void _restart() {
    _run++;
    setState(() {
      step = 1;
      photo = null;
      candidates = null;
      error = null;
      chosen = null;
      browsing = false;
    });
  }

  /// 운영자 등록 · 이용자 제보 · 내 이용권(체인)까지 반영한 매칭
  List<GymMatch> _match(GearModel g) => matchGyms(g, from: s.gymsForMe, gear: s.gymGearNow);

  /// 고른 기구 기준 매칭 결과에 필터 적용
  List<GymMatch> get _results {
    final list = _match(chosen!);
    double dist(GymMatch m) => metersBetween(here, m.gym.pos);
    switch (_filters[filter]) {
      case '동일 모델만':
        list
          ..retainWhere((m) => m.level == MatchLevel.exact)
          ..sort((a, b) => dist(a).compareTo(dist(b)));
      case '거리순':
        list.sort((a, b) => dist(a).compareTo(dist(b)));
      case '평점순':
        list.sort((a, b) => b.gym.rating.compareTo(a.gym.rating));
      case '24시간':
        list
          ..retainWhere((m) => m.gym.hours == '24시간')
          ..sort((a, b) => dist(a).compareTo(dist(b)));
    }
    return list;
  }

  GymMatch get _selectedMatch {
    final all = _match(chosen!);
    return all.firstWhere((m) => m.gym.name == selectedGym, orElse: () => all.first);
  }

  Future<void> _directions(Gym g) async {
    // 네이버 지도 앱 도보 길찾기 (URL Scheme, 키 불필요) — lib/services/directions.dart
    switch (await openNaverDirections(g.pos.latitude, g.pos.longitude, g.name)) {
      case DirectionsResult.opened:
        break;
      case DirectionsResult.store:
        s.toast('네이버 지도 앱을 설치하면 길찾기가 열려요');
      case DirectionsResult.unsupported:
        s.toast('길찾기는 휴대폰의 네이버 지도 앱에서 열려요');
      case DirectionsResult.failed:
        s.toast('네이버 지도를 열지 못했어요');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // 6단계 진행 바 (운동으로 찾기에는 없음)
      if (!routine)
        Padding(
        padding: const EdgeInsets.fromLTRB(22, 2, 22, 16),
        child: Row(children: [
          for (int i = 1; i <= 6; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 6 ? 5 : 0),
                height: 1.5,
                color: i < step ? C.goldDim : (i == step ? C.gold : C.goldA(.16)),
              ),
            ),
        ]),
      ),
      if (routine) const SizedBox(height: 17),
      Expanded(child: KeyedSubtree(key: ValueKey('$step-$browsing-$routine-$routineResults'), child: _screen())),
    ]);
  }

  Widget _screen() => routine ? (routineResults ? _routineResults() : _routinePick()) : switch (step) {
        2 => _analyzing(),
        3 => _confirm(),
        4 => _matching(),
        5 => _mapStep(),
        6 => _confirmed(),
        _ => _capture(),
      };

  /* ---------------- 1. 사진 ---------------- */
  Widget _capture() => ScreenFrame(
        header: const StepTitle(eyebrow: '헬스장 찾기 · Signature', title: '운동기구 사진을 올려주세요', desc: '기구 전체가 보이게 촬영하면 인식 정확도가 올라갑니다.'),
        footer: [
          GoldButton('사진으로 계속하기', onTap: _pick),
          GoldButton('사진 없이 직접 찾기', ghost: true, margin: const EdgeInsets.only(top: 10), onTap: _browse),
        ],
        children: [
          DropZone('사진 선택 또는 촬영', onTap: _pick),
          const HintCard('Tip.', '브랜드 로고나 각인이 보이면 모델까지 더 정확하게 인식됩니다. 사진 속 다른 사람은 나오지 않게 찍어 주세요.'),
          Box(
            onTap: () => setState(() {
              routine = true;
              routineResults = false;
            }),
            margin: const EdgeInsets.only(top: 16),
            border: C.goldDim,
            gradient: softGold(.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              const Text('🏋️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('오늘 할 운동으로 찾기', style: F.inter(size: 13.5, w: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text('고른 운동을 모두 할 수 있는 헬스장을 가까운 순으로', style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300)),
                ]),
              ),
              Text('›', style: F.inter(size: 18, color: C.gold)),
            ]),
          ),
          _chainPicker(),
        ],
      );

  /// 내 이용권: 고른 체인 지점에서만 찾기 (F-SIG-8)
  Widget _chainPicker() {
    final mine = s.myChains;
    Widget chip(String label, bool on, VoidCallback onTap) => Semantics(selected: on, child: SelChip(label, on: on, onTap: onTap));
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('내 이용권', style: F.inter(size: 12.5, w: FontWeight.w500, ls: .04)),
        const SizedBox(height: 4),
        Text(mine.isEmpty ? '모든 헬스장에서 찾아요. 이용권이 있는 체인을 고르면 그 지점만 보여드려요.' : '${mine.join(' · ')} 지점에서만 찾아요.',
            style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300, h: 1.5)),
        const SizedBox(height: 10),
        Wrap(runSpacing: 7, children: [
          chip('전체 헬스장', mine.isEmpty, () => setState(s.clearChains)),
          for (final c in gymChains) chip(c, mine.contains(c), () => setState(() => s.toggleChain(c))),
        ]),
        const SizedBox(height: 8),
        Text('이용 가능한 지점 범위는 체인마다 달라요. 방문 전에 체인에 확인해 주세요.', style: F.inter(size: 9.5, color: C.textFaint, h: 1.5)),
      ]),
    );
  }

  /// 이용권을 골랐을 때 결과 위에 보여주는 안내 (전체 보기로 되돌리기)
  Widget _chainNote() {
    if (s.myChains.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(child: Text('내 이용권 · ${s.myChains.join(' · ')} 지점만', style: F.inter(size: 10.5, color: C.goldBright))),
        TapArea(
          onTap: () => setState(s.clearChains),
          label: '모든 헬스장 보기',
          minSize: 36,
          alignment: Alignment.centerRight,
          child: Text('전체 보기 ›', style: F.inter(size: 10.5, color: C.gold)),
        ),
      ]),
    );
  }

  /* ---------------- 오늘 할 운동으로 찾기 (F-SIG-7) ---------------- */
  List<Exercise> get _plan => [for (final e in exercises) if (plan.contains(e.id)) e];

  /// 할 수 있는 운동이 많은 순, 같으면 가까운 순
  List<RoutineMatch> get _routine {
    final list = routineGyms(_plan, from: s.gymsForMe, gear: s.gymGearNow);
    double d(RoutineMatch m) => metersBetween(here, m.gym.pos);
    list.sort((a, b) {
      final c = b.ok.length.compareTo(a.ok.length);
      return c != 0 ? c : d(a).compareTo(d(b));
    });
    return list;
  }

  Widget _routinePick() {
    final parts = {for (final e in exercises) e.part};
    return ScreenFrame(
      header: StepTitle(
        eyebrow: '← 헬스장 찾기',
        onBack: () => setState(() => routine = false),
        title: '오늘 할 운동을 고르세요',
        desc: '고른 운동을 모두 할 수 있는 헬스장을 가까운 순으로 찾아요.',
      ),
      footer: [
        GoldButton(plan.isEmpty ? '운동을 골라 주세요' : '운동 ${plan.length}개가 되는 헬스장 찾기',
            onTap: plan.isEmpty
                ? null
                : () {
                    setState(() {
                      routineResults = true;
                      routineGym = null;
                    });
                    if (loc == null) _locate();
                  }),
      ],
      children: [
        for (final part in parts) ...[
          Padding(padding: const EdgeInsets.only(top: 6, bottom: 9), child: Text(part, style: F.inter(size: 11, color: C.textDim, ls: .06))),
          Wrap(runSpacing: 7, children: [
            for (final e in exercises.where((e) => e.part == part))
              Semantics(
                selected: plan.contains(e.id),
                child: SelChip(e.name, on: plan.contains(e.id), onTap: () => setState(() => plan.contains(e.id) ? plan.remove(e.id) : plan.add(e.id))),
              ),
          ]),
          const SizedBox(height: 8),
        ],
        const HintCard('기구 기준.', '같은 종류의 기구가 있으면 브랜드가 달라도 할 수 있는 운동으로 봐요. 회원들의 "없어요" 제보도 반영돼요.', top: 12),
      ],
    );
  }

  Widget _routineResults() {
    final list = _routine;
    final n = plan.length;
    final full = list.where((m) => m.missing.isEmpty).length;
    final sel = list.where((m) => m.gym.name == routineGym).firstOrNull ?? list.firstOrNull;
    final where = loc == null ? '내 위치를 확인하고 있어요…' : (loc!.real ? '내 위치 기준 거리예요.' : '위치를 확인할 수 없어 강남역 기준 거리예요.');
    return ScreenFrame(
      header: StepTitle(
        eyebrow: '← 운동 다시 고르기',
        onBack: () => setState(() => routineResults = false),
        title: full > 0 ? '오늘 루틴이 전부 되는 헬스장 $full곳' : (list.isEmpty ? '루틴이 되는 헬스장이 없어요' : '루틴 일부가 되는 헬스장 ${list.length}곳'),
        desc: '${_plan.map((e) => e.name).join(' · ')} · $where',
      ),
      footer: [
        GoldButton(sel == null ? '헬스장이 없어요' : '${sel.gym.name} 길찾기', upper: false, onTap: sel == null ? null : () => _directions(sel.gym)),
      ],
      children: [
        _chainNote(),
        if (sel != null)
          GymMap(
            key: ValueKey('routine-$here'),
            me: here,
            meIsReal: loc?.real ?? false,
            pins: [for (final m in list) (id: m.gym.name, pos: m.gym.pos, label: '${m.gym.name.split(' ').first} · ${m.ok.length}/$n')],
            selectedId: sel.gym.name,
            onSelect: (id) => setState(() => routineGym = id),
            showTiles: widget.mapTiles,
          ),
        const SizedBox(height: 8),
        for (final m in list) _routineRow(m, n, m.gym.name == sel?.gym.name),
        if (list.isEmpty) Padding(padding: const EdgeInsets.only(top: 20), child: Text('고른 운동을 할 수 있는 헬스장이 없어요. 운동을 바꾸거나 이용권을 "전체 헬스장"으로 바꿔 보세요.', style: F.inter(size: 11, color: C.textFaint, h: 1.5))),
      ],
    );
  }

  Widget _routineRow(RoutineMatch m, int n, bool on) => GestureDetector(
        onTap: () => setState(() => routineGym = m.gym.name),
        child: Semantics(
          selected: on,
          child: Divided(
            top: true,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 2),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(border: Border.all(color: on ? C.gold : (m.missing.isEmpty ? C.goldDim : C.hairline))),
                padding: const EdgeInsets.all(3),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('${m.ok.length}/$n', style: F.gnum(size: 14)),
                    Text('운동', style: F.inter(size: 7, color: C.textFaint)),
                  ]),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.gym.name, style: F.inter(size: 14, w: on ? FontWeight.w600 : FontWeight.w500, color: on ? C.goldBright : C.ivory)),
                  const SizedBox(height: 4),
                  Text('${distanceLabel(here, m.gym.pos)} · ${m.gym.rating}', style: F.inter(size: 11, color: C.textDim, w: FontWeight.w300)),
                  const SizedBox(height: 9),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    if (m.missing.isEmpty)
                      Tag('✓ 오늘 루틴 전부 가능', color: C.cLow, border: C.cLow.op(.42))
                    else
                      Tag('기구 없음 · ${m.missing.map((e) => e.name).join(', ')}', color: C.textDim, border: C.hairlineSoft),
                    if (m.gym.chain.isNotEmpty) Tag(m.gym.chain, color: C.goldBright, border: C.goldDim),
                    Tag(m.gym.perk),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      );

  /* ---------------- 2. 분석 ---------------- */
  Widget _analyzing() {
    final p = photo;
    final done = candidates != null;
    return ScreenFrame(
      header: const StepTitle(eyebrow: '02 · Recognition · 03 · Analysis', title: '기구를 분석하고 있습니다', desc: '이미지 특징을 추출해 기구의 종류와 모델을 식별합니다.'),
      footer: error != null
          ? [
              GoldButton('다시 시도', onTap: _analyze),
              GoldButton('직접 찾기', ghost: true, margin: const EdgeInsets.only(top: 10), onTap: _browse),
            ]
          : [GoldButton(done ? '분석 결과 보기' : '분석 중…', onTap: done ? () => go(3) : null)],
      children: [
        Viewfinder(
          child: p != null
              ? SizedBox(width: 160, height: 196, child: Image.memory(p.bytes, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()))
              : const SizedBox(width: 140, height: 196, child: CustomPaint(painter: _MachinePainter())),
        ),
        if (error != null) HintCard('분석하지 못했어요.', error!) else const AnalyzeLog(['이미지 전처리', '객체 탐지', '기구 유형 분류', '브랜드 · 모델 대조']),
      ],
    );
  }

  /* ---------------- 3. 기구 확인 (후보 또는 직접 찾기) ---------------- */
  Widget _confirm() {
    final g = chosen;
    final demo = widget.recognizer.isDemo && !browsing;
    return ScreenFrame(
      header: browsing
          ? const StepTitle(eyebrow: '03 · 직접 찾기', title: '어떤 기구를 찾으세요?', desc: '종류를 고른 뒤 브랜드·모델을 선택하세요.')
          : StepTitle(
              eyebrow: '03 · 기구 확인',
              title: '이 기구가 맞나요?',
              desc: demo ? 'AI 인식 연결 전이라 예시 후보를 보여드려요. 실제 기구를 골라 주세요.' : '가장 비슷한 기구부터 보여드려요. 맞는 기구를 골라 주세요.',
            ),
      footer: [
        GoldButton(g == null ? '기구를 골라 주세요' : '이 기구가 있는 헬스장 찾기', onTap: g == null ? null : () => go(4)),
        GoldButton(photo == null ? '사진으로 찾기' : '다시 촬영하기', ghost: true, margin: const EdgeInsets.only(top: 10), onTap: _restart),
      ],
      children: [
        if (browsing) ..._catalog() else ..._candidateList(demo),
        if (g != null) ...[
          const SizedBox(height: 16),
          FlexGrid(
            columns: 2,
            ratio: 2.8,
            hSpacing: 1,
            vSpacing: 1,
            children: [
              _cell('제조사', g.brand),
              _cell('제품 라인', g.line),
              _cell('타겟 부위', g.targetMuscle),
              _cell('구동 방식', g.drive.label),
            ],
          ),
          _matchSummary(g),
        ],
      ],
    );
  }

  List<Widget> _candidateList(bool demo) => [
        if (demo) const Padding(padding: EdgeInsets.only(bottom: 10), child: Align(alignment: Alignment.centerLeft, child: Tag('데모 후보', color: C.live, border: C.live, size: 9.5))),
        for (final c in candidates ?? const <GearCandidate>[]) _gearTile(c.model, confidence: c.confidence),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TapArea(
            onTap: _browse,
            label: '목록에 없어요, 직접 고르기',
            minSize: 36,
            alignment: Alignment.centerLeft,
            child: Text('목록에 없어요 · 직접 고르기 ›', style: F.inter(size: 11.5, color: C.gold)),
          ),
        ),
      ];

  List<Widget> _catalog() => [
        ChipRow(
          items: [for (final c in GearCategory.values) c.label],
          selected: browseCategory.label,
          solid: true,
          onSelect: (v) => setState(() => browseCategory = GearCategory.values.firstWhere((c) => c.label == v)),
        ),
        const SizedBox(height: 12),
        for (final m in gearCatalog.where((m) => m.category == browseCategory)) _gearTile(m),
      ];

  /// 고를 수 있는 기구 한 줄 (후보면 확신도 링 포함)
  Widget _gearTile(GearModel m, {double? confidence}) {
    final on = chosen?.id == m.id;
    return Box(
      onTap: () => setState(() => chosen = m),
      margin: const EdgeInsets.only(bottom: 8),
      border: on ? C.gold : C.hairlineSoft,
      gradient: on ? softGold(.10) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Semantics(
        selected: on,
        child: Row(children: [
          if (confidence != null) ...[
            Ring(size: 46, stroke: 2.5, segments: [MapEntry(confidence, on ? C.gold : C.goldDim)], child: Text('${(confidence * 100).round()}%', style: F.gnum(size: 12))),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.brandLine.toUpperCase(), style: F.inter(size: 9, color: C.gold, ls: .12, w: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(m.nameKo, style: F.inter(size: 13.5, w: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('${m.nameEn} · ${m.drive.label}', style: F.inter(size: 10, color: C.textFaint)),
            ]),
          ),
          Icon(on ? Icons.radio_button_checked : Icons.radio_button_off, size: 18, color: on ? C.goldBright : C.textFaint),
        ]),
      ),
    );
  }

  /// 고른 기구로 몇 곳이 맞는지 미리 보여준다
  Widget _matchSummary(GearModel g) {
    final all = _match(g);
    int n(MatchLevel l) => all.where((m) => m.level == l).length;
    return HintCard(
      '동일 모델 ${n(MatchLevel.exact)}곳.',
      '같은 브랜드 ${n(MatchLevel.sameBrand)}곳 · 같은 종류 대체 기구 ${n(MatchLevel.alternative)}곳을 함께 찾았어요.',
      top: 16,
    );
  }

  /* ---------------- 4. 헬스장 매칭 ---------------- */
  Widget _matching() {
    final g = chosen!;
    final all = _match(g);
    final list = _results;
    final exact = all.where((m) => m.level == MatchLevel.exact).length;
    final where = loc == null ? '내 위치를 확인하고 있어요…' : (loc!.real ? '내 위치 기준 거리예요.' : '위치를 확인할 수 없어 강남역 기준 거리예요.');
    return ScreenFrame(
      header: StepTitle(
        eyebrow: '04 · Matching',
        title: exact > 0 ? '같은 기구가 있는 헬스장 $exact곳' : '비슷한 기구가 있는 헬스장 ${all.length}곳',
        desc: '${g.brand} ${g.nameKo} 기준 · $where',
      ),
      footer: [GoldButton('지도에서 보기', onTap: all.isEmpty ? null : () => go(5))],
      children: [
        _chainNote(),
        ChipRow(items: _filters, selected: _filters[filter], solid: true, onSelect: (v) => setState(() => filter = _filters.indexOf(v))),
        const SizedBox(height: 16),
        for (final m in list) _gymRow(m),
        if (list.isEmpty) Padding(padding: const EdgeInsets.only(top: 20), child: Text('조건에 맞는 헬스장이 없어요.', style: F.inter(size: 11, color: C.textFaint))),
      ],
    );
  }

  GearSource _source(GymMatch m) => s.gearSource(m.gym.name, m.gear.id);

  String _levelTag(GymMatch m) => m.level == MatchLevel.exact ? '동일 모델 보유' : '${m.level.label} · ${m.gear.brand} ${m.gear.nameKo}';

  Widget _gymRow(GymMatch m) => GestureDetector(
        onTap: () {
          setState(() => selectedGym = m.gym.name);
          go(5);
        },
        child: Divided(
          top: true,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(border: Border.all(color: m.level == MatchLevel.exact ? C.goldDim : C.hairline)),
              padding: const EdgeInsets.all(3),
              child: FittedBox(
                fit: BoxFit.scaleDown, // 고정 크기 배지: 큰 글자 설정에서는 배지 안에 맞춰 줄임
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${m.level.score}', style: F.gnum(size: 14)),
                  Text('MATCH', style: F.inter(size: 7, color: C.textFaint, ls: .1)),
                ]),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.gym.name, style: F.inter(size: 14, w: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('${distanceLabel(here, m.gym.pos)} · ${m.gym.rating}', style: F.inter(size: 11, color: C.textDim, w: FontWeight.w300)),
                const SizedBox(height: 9),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  Tag(_levelTag(m), color: m.level == MatchLevel.exact ? C.goldBright : C.textDim, border: m.level == MatchLevel.exact ? C.goldDim : C.hairlineSoft),
                  if (_source(m) case final src when src != GearSource.listed) Tag('✓ ${src.label}', color: C.cLow, border: C.cLow.op(.42)),
                  Tag(m.gym.perk),
                ]),
              ]),
            ),
          ]),
        ),
      );

  /* ---------------- 5. 지도 ---------------- */
  Widget _mapStep() {
    final sel = _selectedMatch;
    return ScreenFrame(
      header: StepTitle(eyebrow: '05 · Map', title: '지도에서 위치 확인', desc: loc?.real == true ? '내 위치 기준으로 매칭된 헬스장입니다.' : '위치 권한이 없으면 강남역을 기준으로 보여드려요.'),
      footer: [
        GoldButton('이 헬스장 선택', onTap: () => go(6)),
        GoldButton('리스트로 돌아가기', ghost: true, margin: const EdgeInsets.only(top: 10), onTap: () => go(4)),
      ],
      children: [
        GymMap(
          key: ValueKey(here),
          me: here,
          meIsReal: loc?.real ?? false,
          pins: [for (final m in _match(chosen!)) (id: m.gym.name, pos: m.gym.pos, label: '${m.gym.name.split(' ').first} · ${m.level.score}')],
          selectedId: sel.gym.name,
          onSelect: (id) => setState(() => selectedGym = id),
          showTiles: widget.mapTiles,
        ),
        Box(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: C.hairline,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sel.gym.name, style: F.inter(size: 13, w: FontWeight.w500)),
            const SizedBox(height: 3),
            Text('${distanceLabel(here, sel.gym.pos)} · ${_levelTag(sel)} · ${sel.level.score} 매칭', style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300)),
          ]),
        ),
      ],
    );
  }

  /* ---------------- 6. 확정 ---------------- */
  Widget _confirmed() {
    final m = _selectedMatch;
    final d = distanceLabel(here, m.gym.pos);
    final dist = d.split(' · ').first;
    final name = m.gear.nameKo, obj = objectParticle(name);
    final what = switch (m.level) {
      MatchLevel.exact => '찾는 ${m.gear.brand} $name$obj 보유 중이며,',
      MatchLevel.sameBrand => '같은 브랜드의 $name$obj 보유 중이며,',
      MatchLevel.alternative => '같은 종류의 ${m.gear.brand} $name$obj 보유 중이며,',
    };
    return ScreenFrame(
      header: const StepTitle(eyebrow: '06 · Confirmed', title: '헬스장이 선택됐습니다'),
      footer: [
        GoldButton('길찾기 시작 (네이버 지도)', onTap: () => _directions(m.gym)),
        GoldButton('헬스장 운영자이신가요? 보유 기구 등록하기', ghost: true, upper: false, margin: const EdgeInsets.only(top: 10), onTap: () => s.go(AppPage.b2b)),
      ],
      children: [
        ConfirmHero(m.gym.name, '$what\n현재 위치에서 $dist 거리입니다.'),
        DetailList([
          ('기구 매칭', '${m.level.label} · ${m.level.score}'),
          ('보유 기구', '${m.gear.brand} ${m.gear.nameKo}'),
          ('거리', dist),
          ('예상 도보', d.contains('도보') ? d.split('도보 ').last : '도보 1시간 이상'),
          ('운영 시간', m.gym.hours),
          ('정보 출처', _source(m).label),
        ]),
        _verify(m),
      ],
    );
  }

  /// 6단계: 회원이 기구가 실제로 있는지 알려 주는 카드 (데이터 루프)
  Widget _verify(GymMatch m) {
    final r = s.gearReport(m.gym.name, m.gear.id);
    void report(bool present) {
      s.reportGear(m.gym.name, m.gear.id, present: present);
      // 없다고 하면 이 헬스장은 매칭에서 빠지므로 목록으로 돌아간다
      if (!present) {
        setState(() => selectedGym = null);
        go(4);
      } else {
        setState(() {});
      }
    }

    return Box(
      margin: const EdgeInsets.only(top: 16),
      border: C.hairline,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('이 기구가 실제로 있나요?', style: F.inter(size: 13, w: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          r == null ? '다녀오셨다면 알려 주세요. 다른 회원의 헬스장 찾기에 반영돼요.' : '알려 주셔서 고마워요. 기구 매칭에 반영됐어요.',
          style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300, h: 1.5),
        ),
        const SizedBox(height: 11),
        Row(children: [
          Expanded(child: LineButton(r == true ? '✓ 있어요' : '있어요', done: r == true, expand: true, padding: const EdgeInsets.symmetric(vertical: 10), onTap: r == true ? null : () => report(true))),
          const SizedBox(width: 8),
          Expanded(child: LineButton('없어요', expand: true, padding: const EdgeInsets.symmetric(vertical: 10), onTap: () => report(false))),
        ]),
        const SizedBox(height: 10),
        Text('제보는 이름 없이 익명으로 모든 회원과 공유돼요 · 마이 탭에서 언제든 지울 수 있어요', style: F.inter(size: 9.5, color: C.textFaint, h: 1.5)),
      ]),
    );
  }

  Widget _cell(String k, String v) => Container(
        color: C.hairlineSoft,
        padding: const EdgeInsets.all(0.5),
        child: Container(
          color: C.charcoal,
          padding: const EdgeInsets.all(13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k.toUpperCase(), style: F.inter(size: 9.5, color: C.textFaint, ls: .1)),
            const SizedBox(height: 5),
            Text(v, style: F.inter(size: 13.5)),
          ]),
        ),
      );
}

/// 분석 화면의 기구 라인 일러스트 (사진이 없을 때, 원본 viewBox 100x140)
class _MachinePainter extends CustomPainter {
  const _MachinePainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 140);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xD9C9BFA0);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 20, 60, 14), const Radius.circular(2)), p);
    canvas.drawLine(const Offset(50, 34), const Offset(50, 90), p);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(35, 90, 30, 10), const Radius.circular(1)), p);
    canvas.drawLine(const Offset(30, 100), const Offset(30, 120), p);
    canvas.drawLine(const Offset(70, 100), const Offset(70, 120), p);
    canvas.drawLine(const Offset(20, 120), const Offset(80, 120), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
