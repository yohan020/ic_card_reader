import 'package:flutter/material.dart';

import '../../../core/widgets/app_ui.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const effectiveDate = '2026년 8월 10일';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('개인정보처리방침')),
    body: const AppPage(
      children: [
        NoticeBanner(
          title: '카드 정보는 기본적으로 기기 안에서 처리됩니다',
          text:
              '교통카드의 최근 이용내역은 NFC로 읽어 화면에 표시하며, 앱을 종료하면 유지하지 않습니다. 카드 IDm 원문은 NFC 통신 중에만 일시적으로 사용하고 저장·표시·전송하지 않습니다.',
          tone: NoticeTone.privacy,
        ),
        SizedBox(height: 22),
        _PolicySection(
          title: '1. NFC 사용 목적',
          body:
              'NFC 권한은 사용자가 스캔을 시작했을 때 일본 교통계 IC 카드의 이용내역을 읽는 용도로만 사용합니다. 앱은 카드에 정보를 기록하거나 변경하지 않습니다.',
        ),
        _PolicySection(
          title: '2. 기기 안에서 처리하는 정보',
          body:
              '최근 이용내역의 원본 16바이트 기록, 날짜, 거래 유형, 역 코드·역명, 금액과 잔액을 기기 안에서 해석해 표시합니다. 이용내역은 영구 저장하지 않으며 다른 카드를 읽으면 현재 결과로 교체됩니다.',
        ),
        _PolicySection(
          title: '3. 오류 제보 시 전송하는 정보',
          body:
              '오류 제보는 선택 사항입니다. 사용자가 미리보기를 확인하고 동의한 경우에만 선택한 이용내역 1건의 원본 기록과 코드·해석 결과, 이용 날짜, 금액·잔액, 입력한 설명, 앱·파서·역 데이터 버전, 플랫폼과 OS 버전을 Supabase로 전송합니다. 전송된 내용은 앱 개선을 위해 사용합니다.',
        ),
        _PolicySection(
          title: '4. 전송하지 않는 정보',
          body:
              '카드 IDm 원문, 선택하지 않은 다른 이용내역, 이름, 이메일 주소, 기기 고유 식별자, 현재 위치와 이동 경로는 제보 데이터에 포함하지 않습니다.',
        ),
        _PolicySection(
          title: '5. 외부 처리 서비스',
          body:
              '오류 제보 접수에는 Supabase의 익명 인증·서버·데이터베이스 기능을 사용합니다. 익명 인증 ID는 10분당 5건의 반복 제보 제한에만 사용하며 제보 내용과 연결하지 않습니다. 제보 내용은 Supabase 인프라를 통해 처리되고, 네트워크 연결 과정의 기술 정보는 해당 서비스 운영 정책에 따라 처리될 수 있습니다.',
        ),
        _PolicySection(
          title: '6. 역 코드 데이터',
          body:
              '역명 조회에는 허가받아 앱에 포함한 Yoiko 역 코드 데이터를 사용합니다. 조회는 기기 안에서 수행되며, 역명을 확인하기 위해 카드 기록을 외부 서버로 보내지 않습니다. 이용 조건은 오픈소스 라이선스 화면에서 확인할 수 있습니다.',
        ),
        _PolicySection(
          title: '7. 보관과 삭제',
          body:
              '기기에서 읽은 이용내역은 앱이 영구 저장하지 않습니다. 선택적으로 전송된 오류 제보는 접수 후 최대 1년, 제보 제한용 익명 인증 정보는 마지막 활동 후 최대 1년간 보관하고 매월 정리합니다. 법령상 보존 의무가 있는 경우에는 해당 기간 동안 보관할 수 있습니다.',
        ),
        _PolicySection(
          title: '8. 정책 변경과 문의',
          body:
              '데이터 처리 방식이 변경되면 이 방침과 시행일을 함께 갱신합니다. 개인정보 확인·삭제 요청, 앱 오류, 이용 방법과 기타 문의는 iccardreader10@gmail.com으로 접수합니다. 공개 방침: https://yohan020.github.io/ic_card_reader/',
        ),
        SizedBox(height: 4),
        Center(child: Text('시행일: $effectiveDate')),
      ],
    ),
  );
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Text(
          body,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.55,
          ),
        ),
      ],
    ),
  );
}
