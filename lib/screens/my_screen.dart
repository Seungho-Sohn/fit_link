import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

AppState get _s => AppState.I;

/* ================= 마이페이지 ================= */
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget menu(String k, String v, {VoidCallback? onTap, bool gold = false, Widget? kw}) => GestureDetector(
          onTap: onTap,
          child: Divided(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(children: [
              Expanded(child: kw ?? Text(k, style: F.inter(size: 13))),
              Text(v, style: F.inter(size: 11, color: gold ? C.goldBright : C.textFaint)),
            ]),
          ),
        );
    Widget badge(String ic, String l, bool earned) => Expanded(
          child: Column(children: [
            Opacity(
              opacity: earned ? 1 : .32,
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: C.panel, border: Border.all(color: earned ? C.gold : C.hairline)),
                child: Text(ic, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 6),
            Text(l, style: F.inter(size: 8.5, color: earned ? C.textDim : C.textFaint, h: 1.3)),
          ]),
        );
    return ScreenFrame(
      header: const StepTitle(eyebrow: 'My', title: '마이페이지'),
      children: [
        Divided(
          padding: const EdgeInsets.only(top: 4, bottom: 20),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.gold)),
              child: Text('F', style: F.serif(size: 18, color: C.goldBright)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('회원님', style: F.inter(size: 14.5, w: FontWeight.w500)),
                const SizedBox(height: 3),
                Text('짐비아 회원 · 🔥 12일 연속', style: F.serif(size: 12, w: FontWeight.w400, color: C.textDim)),
              ]),
            ),
          ]),
        ),
        const SectHead('내 배지', more: '전체 8개', top: 18),
        Row(children: [badge('🥇', '첫 운동', true), badge('🔥', '7일 연속', true), badge('💪', '챌린지 완주', true), badge('🏆', '랭킹 TOP3', false)]),
        const SizedBox(height: 6),
        menu('참여 중 챌린지', '2개 진행중'),
        menu('찜한 헬스장', '스틸핏 강남 외 2'),
        menu('기구 인식 이력', 'Hammer Strength 외 3'),
        menu('식단 기록', '오늘 1,642kcal'),
        menu('웨어러블 연동', 'Apple Health 연결됨'),
        menu('알림 설정', '›'),
        const SectHead('헬스장 운영자', top: 22),
        menu('🏢 헬스장 운영자 전용관', '보유 기구 등록 · 견적 ›', gold: true, onTap: () => _s.go(AppPage.b2b)),
        const SectHead('개인정보 · 데이터', top: 22),
        menu('개인정보 처리방침', '›', onTap: _openPrivacy),
        menu('내 기구 제보 지우기', _s.myReportCount == 0 ? '없음' : '${_s.myReportCount}건 ›', onTap: () => _confirmDelete(context)),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text('기구 제보("있어요/없어요")만 익명으로 서버에 저장돼 다른 회원과 공유돼요. 글·댓글·운영자 등록 등 나머지는 이 기기에만 저장돼요.',
              style: F.inter(size: 10, color: C.textFaint, h: 1.55)),
        ),
      ],
    );
  }

  Future<void> _openPrivacy() async {
    if (!await launchUrl(privacyPolicyUrl, mode: LaunchMode.externalApplication)) _s.toast('페이지를 열지 못했어요');
  }

  void _confirmDelete(BuildContext context) {
    showGoldSheet<void>(
      context,
      title: '내 기구 제보 지우기',
      body: (ctx, setS) => Text(
        '서버와 이 기기에 저장된 내 기구 제보를 모두 지워요. 지운 제보는 되돌릴 수 없고, 다른 회원의 매칭에서도 빠져요.',
        style: F.inter(size: 12, color: C.textDim, h: 1.65),
      ),
      foot: (ctx, setS) => Column(children: [
        GoldButton('모두 지우기', upper: false, onTap: () async {
          Navigator.of(ctx).pop();
          await _s.deleteMyReports();
        }),
        GoldButton('취소', ghost: true, upper: false, margin: const EdgeInsets.only(top: 10), onTap: () => Navigator.of(ctx).pop()),
      ]),
    );
  }
}

/// 개인정보 처리방침 (web/privacy.html 을 GitHub Pages로 게시)
final privacyPolicyUrl = Uri.parse('https://seungho-sohn.github.io/fit_link/privacy.html');
