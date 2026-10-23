import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import 'enoden_noriorikun_pass_page.dart';
import 'fukuoka_city_subway_pass_page.dart';
import 'nagasaki_electric_tramway_pass_page.dart';
import 'sapporo_subway_pass_page.dart';
import 'yui_rail_pass_page.dart';
import 'hokkaido_rail_pass_page.dart';
import 'hakone_freepass_page.dart';
import 'hiroden_pass_page.dart';
import 'enokama_pass_page.dart';
import '../data/pass_comparison_data_preloader.dart';
import '../data/pass_transit_data.dart';
import '../domain/pass_comparison.dart';
import 'hankyu_1day_pass_page.dart';
import 'kyoto_subway_bus_pass_page.dart';
import 'kyoto_subway_1day_pass_page.dart';
import 'kintetsu_rail_pass_5day_page.dart';
import 'osaka_amazing_pass_prototype_page.dart';
import 'okayama_kurashiki_gururin_pass_page.dart';
import 'pass_comparison_prototype_page.dart';

enum PassRegion {
  hokkaido,
  tohoku,
  kanto,
  chubu,
  kansai,
  chugoku,
  shikoku,
  kyushu,
  okinawa,
}

extension on PassRegion {
  String get label => switch (this) {
    PassRegion.hokkaido => '홋카이도',
    PassRegion.tohoku => '도호쿠',
    PassRegion.kanto => '도쿄·간토',
    PassRegion.chubu => '주부',
    PassRegion.kansai => '간사이',
    PassRegion.chugoku => '주고쿠',
    PassRegion.shikoku => '시코쿠',
    PassRegion.kyushu => '규슈',
    PassRegion.okinawa => '오키나와',
  };

  String get description => switch (this) {
    PassRegion.hokkaido => '삿포로·하코다테 등',
    PassRegion.tohoku => '센다이·아오모리 등',
    PassRegion.kanto => '도쿄·가나가와 지역 패스',
    PassRegion.chubu => '나고야·호쿠리쿠 등',
    PassRegion.kansai => '오사카·교토·나라 지역 패스',
    PassRegion.chugoku => '히로시마·오카야마 등',
    PassRegion.shikoku => '마쓰야마·다카마쓰 등',
    PassRegion.kyushu => '후쿠오카 지역 패스',
    PassRegion.okinawa => '나하·오키나와 지역',
  };
}

class PassSelectionPage extends StatefulWidget {
  const PassSelectionPage({this.initialTransitData, this.region, super.key});

  final PassTransitData? initialTransitData;
  final PassRegion? region;

  @override
  State<PassSelectionPage> createState() => _PassSelectionPageState();
}

class _PassSelectionPageState extends State<PassSelectionPage> {
  final PassTransitDataRepository _transitRepository =
      const PassTransitDataRepository();

  @override
  void initState() {
    super.initState();
    final dataGroup = _dataGroupFor(widget.region);
    if (dataGroup != null && widget.initialTransitData == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        PassComparisonDataPreloader.warmUpRegion(dataGroup);
        PassComparisonDataPreloader.warmUpRemainingAfter(dataGroup);
      });
    }
  }

  PassComparisonDataGroup? _dataGroupFor(PassRegion? region) =>
      switch (region) {
        PassRegion.hokkaido => PassComparisonDataGroup.hokkaido,
        PassRegion.kanto => PassComparisonDataGroup.kanto,
        PassRegion.kansai => PassComparisonDataGroup.kansai,
        PassRegion.chugoku => PassComparisonDataGroup.chugoku,
        PassRegion.kyushu => PassComparisonDataGroup.kyushu,
        PassRegion.okinawa => PassComparisonDataGroup.okinawa,
        _ => null,
      };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('교통패스 비교')),
    body: widget.region == null
        ? _RegionSelection(
            passEntries: _passEntries(),
            onSelected: (region) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PassSelectionPage(
                  initialTransitData: widget.initialTransitData,
                  region: region,
                ),
              ),
            ),
          )
        : SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                const _ProgressSteps(activeStep: 1),
                const SizedBox(height: 26),
                Text(
                  '${widget.region!.label}의\n교통패스를 선택해 주세요',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
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
                ..._passCardsForRegion(context),
                const SizedBox(height: 6),
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

  List<Widget> _passCardsForRegion(BuildContext context) {
    final entries = _passEntries()
        .where((entry) => entry.region == widget.region)
        .toList(growable: false);
    return [
      for (final entry in entries) ...[
        entry.cardBuilder(context),
        const SizedBox(height: 14),
      ],
    ];
  }

  List<_PassListEntry> _passEntries() => [
    _PassListEntry(
      region: PassRegion.hokkaido,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.subway_outlined,
        title: '삿포로 지하철 1일권',
        subtitle: '삿포로시 지하철 · 전 구간',
        description: '지하철 전 구간의 일반 운임과 비교합니다.',
        periods: const ['1일권 · ¥830'],
        teal: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const SapporoSubwayPassPage(),
          ),
        ),
      ),
    ),
    _PassListEntry(
      region: PassRegion.hokkaido,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.train_outlined,
        title: '홋카이도 레일패스',
        subtitle: 'JR 홋카이도선 · 보통차 지정석',
        description: '5·7·10일권과 철도·버스 이동 예상 운임을 비교합니다.',
        periods: const ['5일권 · ¥23,000', '7일권 · ¥29,000', '10일권 · ¥38,000'],
        teal: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HokkaidoRailPassPage()),
        ),
      ),
    ),
    _PassListEntry(
      region: PassRegion.kanto,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.subway_outlined,
        title: 'Tokyo Subway Ticket',
        subtitle: 'Tokyo Metro · 도에이 지하철',
        description: '24·48·72시간권의 손익을 비교합니다.',
        periods: const ['24시간', '48시간', '72시간'],
        onTap: () => _open(context, PassProduct.tokyoSubway24),
      ),
    ),
    _PassListEntry(
      region: PassRegion.kanto,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.confirmation_number_outlined,
        title: '에노시마·가마쿠라 프리패스',
        subtitle: '에노덴 · 오다큐 전철',
        description: '출발역별 가격과 프리구간 운임을 비교합니다.',
        periods: const ['1일권 · 발역별 가격'],
        teal: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const EnokamaPassPage()),
        ),
      ),
    ),
    _PassListEntry(
      region: PassRegion.kanto,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.train_outlined,
        title: '에노덴 1일 승차권',
        subtitle: '에노시마 전철 · 에노덴 전선',
        description: '에노덴 내부 이동의 일반 운임과 비교합니다.',
        periods: const ['1일권 · ¥800'],
        teal: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const EnodenNoriorikunPassPage(),
          ),
        ),
      ),
    ),
    _PassListEntry(
      region: PassRegion.kanto,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.landscape_outlined,
        title: '하코네 프리패스',
        subtitle: '오다큐 70개 출발역 · 하코네 교통수단',
        description: '출발역별 성인 가격과 하코네 현지 운임을 비교합니다.',
        periods: const ['2일권', '3일권'],
        teal: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HakoneFreepassPage()),
        ),
      ),
    ),
    _PassListEntry(
      region: PassRegion.kanto,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.train_outlined,
        title: '도쿠나이 패스',
        subtitle: '도쿄 23구 내 지정 JR 구간',
        description: '1일권과 적용 JR 구간의 일반 운임을 비교합니다.',
        periods: const ['1일권 · ¥870'],
        teal: true,
        onTap: () => _open(context, PassProduct.tokunai1Day),
      ),
    ),
    _PassListEntry(
      region: PassRegion.kansai,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.subway_outlined,
        title: '교토 지하철 1일권',
        subtitle: '교토시영 지하철 · 전 구간',
        description: '지하철 전 구간의 일반 운임과 비교합니다.',
        periods: const ['1일권 · ¥800'],
        teal: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const KyotoSubway1DayPassPage(),
          ),
        ),
      ),
    ),
    _PassListEntry(
      region: PassRegion.kansai,
      cardBuilder: (context) => _PassChoiceCard(
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
    ),
    _PassListEntry(
      region: PassRegion.kansai,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.directions_bus_filled_outlined,
        title: '교토 지하철·버스 1일권',
        subtitle: '교토시영 지하철 · 버스 예상 운임',
        description: '지하철 자동 운임과 버스 이용 추정을 비교합니다.',
        periods: const ['1일권 · ¥1,100'],
        teal: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const KyotoSubwayBusPassPage(),
          ),
        ),
      ),
    ),
    _PassListEntry(
      region: PassRegion.kansai,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.train_outlined,
        title: '한큐패스 1일권',
        subtitle: '한큐 전철 전 노선',
        description: '한큐 전철 내부 이동의 일반 운임과 비교합니다.',
        periods: const ['1일권 · ¥1,300'],
        teal: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const Hankyu1DayPassPage()),
        ),
      ),
    ),
    _PassListEntry(
      region: PassRegion.kansai,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.confirmation_number_outlined,
        title: '긴테쓰 레일 패스 5일권',
        subtitle: '긴테쓰 전철 · 이가철도 · 케이블카',
        description: '5일권과 기본 승차운임 합계를 비교합니다.',
        periods: const ['5일권 · ¥4,900'],
        teal: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const KintetsuRailPass5DayPage(),
          ),
        ),
      ),
    ),
    _PassListEntry(
      region: PassRegion.chugoku,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.confirmation_number_outlined,
        title: '오카야마·구라시키 tabiwa 구루링 패스',
        subtitle: 'JR 서일본 · 오카야마 전기궤도 · 시모덴 버스',
        description: '3일권과 철도·노면전차·버스 이동 운임을 비교합니다.',
        periods: const ['3일권 · ¥3,800'],
        teal: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const OkayamaKurashikiGururinPassPage(),
          ),
        ),
      ),
    ),
    _PassListEntry(
      region: PassRegion.chugoku,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.tram_outlined,
        title: '히로덴 전차 패스',
        subtitle: '히로시마 전철 · 전차 전 노선',
        description: '일반 운임과 1일·8시간·24시간권을 비교합니다.',
        periods: const ['1일권 · ¥700', '8시간권 · ¥600', '24시간권 · ¥700'],
        teal: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HirodenPassPage()),
        ),
      ),
    ),
    _PassListEntry(
      region: PassRegion.kyushu,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.tram_outlined,
        title: '나가사키 전기궤도 패스',
        subtitle: '나가사키 전기궤도 · 노면전차 전 노선',
        description: 'IC·터치 기준 일반 운임과 1일·24시간권을 비교합니다.',
        periods: const ['1일권 · ¥600', '24시간권 · ¥700'],
        teal: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const NagasakiElectricTramwayPassPage(),
          ),
        ),
      ),
    ),
    _PassListEntry(
      region: PassRegion.kyushu,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.subway_outlined,
        title: '후쿠오카 지하철 1일권',
        subtitle: '후쿠오카시 지하철 · 3개 노선',
        description: '지하철 전 구간의 일반 운임과 비교합니다.',
        periods: const ['1일권 · ¥640'],
        teal: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const FukuokaCitySubwayPassPage(),
          ),
        ),
      ),
    ),
    _PassListEntry(
      region: PassRegion.okinawa,
      cardBuilder: (context) => _PassChoiceCard(
        icon: Icons.train_outlined,
        title: '유이레일 패스',
        subtitle: '오키나와 도시 모노레일 · 전 노선',
        description: '24·48시간권과 유이레일 일반 운임을 비교합니다.',
        periods: const ['24시간 · ¥1,000', '48시간 · ¥1,800'],
        teal: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const YuiRailPassPage()),
        ),
      ),
    ),
  ];
}

class _PassListEntry {
  const _PassListEntry({required this.region, required this.cardBuilder});

  final PassRegion region;
  final WidgetBuilder cardBuilder;
}

class _RegionSelection extends StatelessWidget {
  const _RegionSelection({required this.passEntries, required this.onSelected});

  final List<_PassListEntry> passEntries;
  final ValueChanged<PassRegion> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        const _ProgressSteps(activeStep: 1),
        const SizedBox(height: 26),
        Text(
          '비교할 지역을\n선택해 주세요',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '여행할 지역을 먼저 선택하면 해당 지역의 교통패스를 볼 수 있습니다.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        for (final region in _orderedRegions()) ...[
          _RegionChoiceCard(
            region: region,
            passCount: _passCountFor(region),
            onSelected: onSelected,
          ),
          const SizedBox(height: 12),
        ],
      ],
    ),
  );

  int _passCountFor(PassRegion region) =>
      passEntries.where((entry) => entry.region == region).length;

  List<PassRegion> _orderedRegions() {
    final regions = [...PassRegion.values];
    regions.sort((left, right) {
      final leftSupported = _passCountFor(left) > 0;
      final rightSupported = _passCountFor(right) > 0;
      if (leftSupported != rightSupported) return leftSupported ? -1 : 1;
      return left.index.compareTo(right.index);
    });
    return regions;
  }
}

class _RegionChoiceCard extends StatelessWidget {
  const _RegionChoiceCard({
    required this.region,
    required this.passCount,
    required this.onSelected,
  });

  final PassRegion region;
  final int passCount;
  final ValueChanged<PassRegion> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAvailable = passCount > 0;
    final accent = AppColors.accent(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final surface = isDark
        ? const Color(0xFF17242A)
        : Theme.of(context).colorScheme.surface;
    final border = isAvailable
        ? (isDark ? accent.withValues(alpha: .38) : AppColors.skySoft)
        : (isDark ? Colors.white.withValues(alpha: .12) : AppColors.border);

    return Semantics(
      button: isAvailable,
      enabled: isAvailable,
      label: isAvailable
          ? '${region.label} 교통패스 $passCount개 보기'
          : '${region.label} 교통패스 준비 중',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: InkWell(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            hoverColor: accent.withValues(alpha: .05),
            onTap: isAvailable ? () => onSelected(region) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          region.label,
                          style: TextStyle(
                            color: isAvailable ? null : muted,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          region.description,
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? (isDark
                                ? accent.withValues(alpha: .18)
                                : AppColors.skySoft)
                          : (isDark
                                ? Colors.white.withValues(alpha: .08)
                                : AppColors.softSurface(context)),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      isAvailable ? '$passCount개' : '준비 중',
                      style: TextStyle(
                        color: isAvailable ? accent : muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isAvailable) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: accent),
                  ],
                ],
              ),
            ),
          ),
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
                        : AppColors.softSurface(context),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${index + 1}. ${labels[index]}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: index + 1 == activeStep
                        ? AppColors.accent(context)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = teal
        ? isDark
              ? const Color(0xFF35C4C7)
              : const Color(0xFF008E9B)
        : AppColors.accent(context);
    return Semantics(
      button: true,
      label: '$title 비교 시작',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF17242A)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? color.withValues(alpha: .56) : AppColors.skySoft,
            ),
          ),
          child: InkWell(
            // Cards must move as one unit when pressed. A separate splash on
            // the Ink background made the border and content appear detached.
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            hoverColor: color.withValues(alpha: .05),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(17),
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
                                    color: isDark
                                        ? color.withValues(alpha: .18)
                                        : AppColors.skySoft,
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
        ),
      ),
    );
  }
}
