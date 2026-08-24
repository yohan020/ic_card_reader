import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../data/pass_transit_data.dart';
import '../domain/pass_comparison.dart';
import 'osaka_amazing_pass_prototype_page.dart';
import 'pass_comparison_prototype_page.dart';

class PassSelectionPage extends StatefulWidget {
  const PassSelectionPage({this.initialTransitData, super.key});

  final PassTransitData? initialTransitData;

  @override
  State<PassSelectionPage> createState() => _PassSelectionPageState();
}

class _PassSelectionPageState extends State<PassSelectionPage> {
  final PassTransitDataRepository _transitRepository =
      const PassTransitDataRepository();

  @override
  void initState() {
    super.initState();
    if (widget.initialTransitData == null) _transitRepository.warmUp();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('교통패스 비교')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          const _ProgressSteps(activeStep: 1),
          const SizedBox(height: 26),
          Text(
            '비교할 교통패스를\n선택해 주세요',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '입력한 이동 계획을 기준으로 일반 운임과 패스 가격을 비교합니다.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _PassChoiceCard(
            icon: Icons.subway_outlined,
            title: 'Tokyo Subway Ticket',
            subtitle: 'Tokyo Metro · 도에이 지하철',
            description: '24·48·72시간권의 손익을 비교합니다.',
            periods: const ['24시간', '48시간', '72시간'],
            onTap: () => _open(context, PassProduct.tokyoSubway24),
          ),
          const SizedBox(height: 14),
          _PassChoiceCard(
            icon: Icons.train_outlined,
            title: '도쿠나이 패스',
            subtitle: '도쿄 23구 내 지정 JR 구간',
            description: '1일권과 적용 JR 구간의 일반 운임을 비교합니다.',
            periods: const ['1일권 · ¥870'],
            teal: true,
            onTap: () => _open(context, PassProduct.tokunai1Day),
          ),
          const SizedBox(height: 14),
          _PassChoiceCard(
            icon: Icons.confirmation_number_outlined,
            title: '오사카 주유패스',
            subtitle: '오사카 메트로 · 사철 · 시티버스',
            description: '1·2일권과 환승 경로의 일반 운임을 비교합니다.',
            periods: const ['1일권 · ¥3,500', '2일권 · ¥5,000'],
            teal: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const OsakaAmazingPassPrototypePage(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const NoticeBanner(
            title: '계산 기준',
            text:
                '지원 데이터로 확인되는 이동만 계산합니다. 확인할 수 없는 운임은 합산하지 않으며, 구매 전 공식 상품 조건과 운임을 확인해 주세요.',
            tone: NoticeTone.info,
          ),
        ],
      ),
    ),
  );

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

class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps({required this.activeStep});

  final int activeStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['패스 선택', '이용 계획', '비교 결과'];
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: index + 1 <= activeStep
                        ? AppColors.skyDark
                        : AppColors.skySoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${index + 1}. ${labels[index]}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: index + 1 == activeStep
                        ? AppColors.skyDark
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: index + 1 == activeStep
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (index != labels.length - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }
}

class _PassChoiceCard extends StatelessWidget {
  const _PassChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.periods,
    required this.onTap,
    this.teal = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<String> periods;
  final VoidCallback onTap;
  final bool teal;

  @override
  Widget build(BuildContext context) {
    final color = teal ? const Color(0xFF008E9B) : AppColors.skyDark;
    return Semantics(
      button: true,
      label: '$title 비교 시작',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.skySoft),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 82,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: .72)],
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12, height: 1.35),
                    ),
                    const SizedBox(height: 11),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: periods
                          .map(
                            (period) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.skySoft,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                period,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
