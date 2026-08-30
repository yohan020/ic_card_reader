import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';

class PassDataSourcesPage extends StatelessWidget {
  const PassDataSourcesPage({super.key});

  static const _entries = [
    _PassDataSource(
      icon: Icons.subway_outlined,
      title: 'Tokyo Subway Ticket',
      subtitle: 'Tokyo Metro · 도에이 지하철',
      calculation: 'ODPT 역·성인 IC 운임 데이터로 도쿄메트로와 도에이 지하철의 적용 구간 운임을 계산합니다.',
      sources: [
        _SourceLink('ODPT 공개 교통 데이터 센터', 'https://developer.odpt.org/'),
        _SourceLink(
          'Tokyo Subway Ticket 공식 안내',
          'https://www.tokyometro.jp/tst/ko/',
        ),
      ],
      note: '운임과 패스 조건은 개정될 수 있으므로 구매 전 공식 안내를 확인해 주세요.',
    ),
    _PassDataSource(
      icon: Icons.train_outlined,
      title: '도쿠나이 패스',
      subtitle: 'JR 동일본 도쿄 23구 내 지정 구간',
      calculation:
          '도쿠나이 적용 77개 역의 영업거리와 JR 동일본 성인 IC 운임표를 바탕으로 만든 오프라인 운임표를 사용합니다.',
      sources: [
        _SourceLink(
          'JR 동일본 도쿠나이 패스 공식 안내',
          'https://www.jreast.co.jp/multi/ko/pass/tokunai_pass.html',
        ),
        _SourceLink('JR 동일본 운임·요금 안내', 'https://www.jreast.co.jp/ko/kippu/'),
        _SourceLink('Wikidata', 'https://www.wikidata.org/'),
      ],
      note: '참고용 계산 결과이므로 실제 이용 전 적용 구간과 최신 운임을 확인해 주세요.',
    ),
    _PassDataSource(
      icon: Icons.confirmation_number_outlined,
      title: '오사카 주유패스',
      subtitle: '오사카 메트로 · 사철 · 시티버스',
      calculation: '철도 사업자별 공개 운임 자료, 역간 거리와 환승 연결을 바탕으로 일반 운임을 계산합니다.',
      sources: [
        _SourceLink(
          '오사카 주유패스 공식 안내',
          'https://osaka-amazing-pass.com/en/howto_about_1day.html',
        ),
        _SourceLink(
          'Osaka Metro 운임 안내',
          'https://subway.osakametro.co.jp/guide/fare/conditions_carriage/unsoyakan.php',
        ),
        _SourceLink('오사카 시티버스 이용 안내', 'https://citybus-osaka.co.jp/howto/'),
      ],
      note:
          '시간표 기반 최속 경로, 관광시설 혜택, 제외 버스, 특급·좌석요금은 포함하지 않습니다. 일부 게이한 영업거리 자료는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다.',
    ),
    _PassDataSource(
      icon: Icons.directions_bus_filled_outlined,
      title: '교토 지하철·버스 1일권',
      subtitle: '교토시영 지하철 · 사용자 입력 버스 예상 운임',
      calculation:
          '교토시영 지하철은 역간 거리와 성인 운임대로 계산합니다. 버스는 일반 시내버스 ¥230·관광특급버스 ¥500의 입력 횟수만 예상 운임으로 합산합니다.',
      sources: [
        _SourceLink(
          '교토시 오픈데이터: 京都市営地下鉄 駅間距離・運賃',
          'https://data.city.kyoto.lg.jp/dataset/00024/',
        ),
        _SourceLink(
          '교토시 교통국 지하철 운임',
          'https://www2.city.kyoto.lg.jp/kotsu/webguide/ja/fare/fare_tika.html',
        ),
        _SourceLink(
          '교토 지하철·버스 1일권 공식 안내',
          'https://www.city.kyoto.lg.jp/kotsu/page/0000028378.html',
        ),
      ],
      note:
          '「京都市営地下鉄 駅間距離・運賃」(京都市)을 가공해 만들었습니다. CC BY 4.0. 버스 노선·사업자·조정 운임 구간·심야 할증·제외 노선은 자동 판정하지 않습니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('데이터 출처 및 운임 기준')),
    body: AppPage(
      children: [
        Text(
          '교통패스별 데이터 출처',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          '비교할 패스를 선택하면 운임 계산 기준, 출처와 제한사항을 확인할 수 있습니다.',
          style: TextStyle(color: AppColors.mutedText(context), height: 1.4),
        ),
        const SizedBox(height: 18),
        AppSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < _entries.length; index++) ...[
                _PassSourceTile(source: _entries[index]),
                if (index != _entries.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _PassSourceTile extends StatelessWidget {
  const _PassSourceTile({required this.source});
  final _PassDataSource source;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.skySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(source.icon, color: AppColors.skyDark, size: 21),
    ),
    title: Text(
      source.title,
      style: const TextStyle(fontWeight: FontWeight.w800),
    ),
    subtitle: Text(source.subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PassSourceDetailPage(source: source),
      ),
    ),
  );
}

class _PassSourceDetailPage extends StatelessWidget {
  const _PassSourceDetailPage({required this.source});
  final _PassDataSource source;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(source.title)),
    body: SelectionArea(
      child: AppPage(
        children: [
          AppSurface(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.softSurface(context),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(source.icon, color: AppColors.accent(context)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        source.subtitle,
                        style: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('운임 계산 기준'),
          AppSurface(
            child: Text(
              source.calculation,
              style: const TextStyle(height: 1.45),
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('데이터 출처'),
          AppSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < source.sources.length; index++) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 5,
                    ),
                    leading: const Icon(Icons.link_rounded),
                    title: Text(
                      source.sources[index].label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: SelectableText(source.sources[index].url),
                  ),
                  if (index != source.sources.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          NoticeBanner(
            title: '확인할 점',
            text: source.note,
            tone: NoticeTone.info,
          ),
        ],
      ),
    ),
  );
}

class _PassDataSource {
  const _PassDataSource({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.calculation,
    required this.sources,
    required this.note,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String calculation;
  final List<_SourceLink> sources;
  final String note;
}

class _SourceLink {
  const _SourceLink(this.label, this.url);
  final String label;
  final String url;
}
