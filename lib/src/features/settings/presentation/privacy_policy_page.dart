import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_ui.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const effectiveDate = '2026년 10월 27일';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(strings(context).privacyPolicy)),
    body: AppPage(
      children: [
        NoticeBanner(
          title: strings(context).privacyOverviewTitle,
          text: strings(context).privacyOverviewBody,
          tone: NoticeTone.privacy,
        ),
        SizedBox(height: 22),
        _PolicySection(
          title: strings(context).privacyNfcTitle,
          body: strings(context).privacyNfcBody,
        ),
        _PolicySection(
          title: strings(context).privacyOnDeviceTitle,
          body: strings(context).privacyOnDeviceBody,
        ),
        _PolicySection(
          title: strings(context).privacyReportsTitle,
          body: strings(context).privacyReportsBody,
        ),
        _PolicySection(
          title: strings(context).privacyNotSentTitle,
          body: strings(context).privacyNotSentBody,
        ),
        _PolicySection(
          title: strings(context).privacyServicesTitle,
          body: strings(context).privacyServicesBody,
        ),
        _PolicySection(
          title: strings(context).privacyMapsTitle,
          body: strings(context).privacyMapsBody,
        ),
        _PolicySection(
          title: strings(context).privacyStationDataTitle,
          body: strings(context).privacyStationDataBody,
        ),
        _PolicySection(
          title: strings(context).privacyRetentionTitle,
          body: strings(context).privacyRetentionBody,
        ),
        _PolicySection(
          title: strings(context).privacyContactTitle,
          body: strings(context).privacyContactBody,
        ),
        SizedBox(height: 4),
        Center(child: Text(strings(context).privacyEffectiveDate)),
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
