import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../data/pass_transit_data.dart';
import '../domain/pass_comparison.dart';
import 'osaka_amazing_pass_prototype_page.dart';
import 'pass_comparison_prototype_page.dart';

class PrototypePassSelectionPage extends StatefulWidget {
  const PrototypePassSelectionPage({this.initialTransitData, super.key});

  final PassTransitData? initialTransitData;

  @override
  State<PrototypePassSelectionPage> createState() =>
      _PrototypePassSelectionPageState();
}

class _PrototypePassSelectionPageState
    extends State<PrototypePassSelectionPage> {
  final PassTransitDataRepository _transitRepository =
      const PassTransitDataRepository();

  @override
  void initState() {
    super.initState();
    if (widget.initialTransitData == null) _transitRepository.warmUp();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('교통패스 비교 프로토타입')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Text(
            '검증할 패스를 선택해 주세요',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Web 프로토타입에서 검증된 상품만 Android 앱에 반영합니다.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          _PrototypePassCard(
            icon: Icons.subway_outlined,
            title: 'Tokyo Subway Ticket',
            subtitle: '24·48·72시간권 · 자동 운임',
            onTap: () => _openTokyo(context),
          ),
          const SizedBox(height: 12),
          _PrototypePassCard(
            icon: Icons.train_outlined,
            title: '도쿠나이 패스',
            subtitle: '1일권 · JR 파생 운임',
            onTap: () => _openTokunai(context),
          ),
          const SizedBox(height: 12),
          _PrototypePassCard(
            icon: Icons.confirmation_number_outlined,
            title: '오사카 주유패스',
            subtitle: '1일권 ¥3,500 · 2일권 ¥5,000 · 환승 자동 계산',
            badge: '프로토타입',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const OsakaAmazingPassPrototypePage(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const NoticeBanner(
            title: '오사카는 교통비만 비교합니다',
            text:
                '공개된 거리·운임 규칙으로 검증한 철도 운임과 오사카 시티버스 일반 운임을 자동 합산합니다. 관광시설 무료입장 가치는 포함하지 않습니다.',
            tone: NoticeTone.info,
          ),
        ],
      ),
    ),
  );

  Future<void> _openTokyo(BuildContext context) =>
      _open(context, PassProduct.tokyoSubway24);

  Future<void> _openTokunai(BuildContext context) =>
      _open(context, PassProduct.tokunai1Day);

  Future<void> _open(BuildContext context, PassProduct product) async {
    var data = widget.initialTransitData;
    if (data == null) {
      try {
        data = await _transitRepository.load();
      } catch (_) {
        // The destination page keeps its existing load-error treatment.
      }
    }
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PassComparisonPrototypePage(
          initialProduct: product,
          initialData: data,
        ),
      ),
    );
  }
}

class _PrototypePassCard extends StatelessWidget {
  const _PrototypePassCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.skySoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: AppColors.skyDark),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 7),
                        Text(
                          badge!,
                          style: const TextStyle(
                            color: AppColors.skyDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}
