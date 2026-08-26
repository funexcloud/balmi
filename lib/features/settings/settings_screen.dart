import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/oem/battery_optimization.dart';
import '../../widgets/balmi_app_bar.dart';
import '../../widgets/balmi_wordmark.dart';
import 'brand_story_screen.dart';

/// App settings — about (OEM battery nested among app-info tiles),
/// brand story, credits. Health habits live on [HealthHabitsScreen].
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BalmiColors.paper,
      appBar: const BalmiAppBar(title: BalmiCopy.settings),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const BalmiWordmark(height: 34),
          const SizedBox(height: 10),
          Text(
            BalmiCopy.slogan,
            style: BalmiTheme.body(
              size: 15,
              weight: FontWeight.w800,
              height: 1.4,
              color: BalmiColors.potatoDk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            BalmiCopy.healthSlogan,
            style: BalmiTheme.body(
              size: 13,
              weight: FontWeight.w700,
              color: BalmiColors.potato,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            BalmiCopy.brandPhilosophy,
            style: BalmiTheme.body(size: 13, color: BalmiColors.sub, height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            BalmiCopy.subcopy,
            style: BalmiTheme.body(size: 13, color: BalmiColors.sub, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            BalmiCopy.about,
            style: BalmiTheme.body(size: 16, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${BalmiCopy.appName}  ·  ${BalmiCopy.versionLabel}',
            style: BalmiTheme.body(size: 13, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            BalmiCopy.aboutTitle,
            style: BalmiTheme.body(size: 14, weight: FontWeight.w800, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            BalmiCopy.aboutBody,
            style: BalmiTheme.body(
              size: 13,
              color: BalmiColors.sub,
              height: 1.5,
            ),
          ),
          // OEM battery among about / app-info — not above everything, not a bottom dump.
          const Divider(height: 28, color: BalmiColors.line),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              BalmiCopy.oemSettings,
              style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
            ),
            onTap: () => OemBattery.openOemSettings(),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              BalmiCopy.ignoreBattery,
              style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
            ),
            onTap: () => OemBattery.requestIgnore(),
          ),
          const SizedBox(height: 16),
          Text(
            'RECORDING STATUS',
            style: BalmiTheme.tracked(
              size: 10,
              color: BalmiColors.sub,
              trackingEm: 0.14,
            ),
          ),
          const SizedBox(height: 10),
          const _StatusRow(
            title: BalmiCopy.aboutStatusLocal,
            hint: BalmiCopy.aboutStatusLocalHint,
          ),
          const _StatusRow(
            title: BalmiCopy.aboutStatusOffline,
            hint: BalmiCopy.aboutStatusOfflineHint,
          ),
          const _StatusRow(
            title: BalmiCopy.aboutStatusRecovery,
            hint: BalmiCopy.aboutStatusRecoveryHint,
          ),
          const _StatusRow(
            title: BalmiCopy.aboutStatusSync,
            hint: BalmiCopy.aboutStatusSyncHint,
          ),
          const SizedBox(height: 14),
          Text(
            BalmiCopy.aboutTechLine,
            style: BalmiTheme.body(size: 13, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            BalmiCopy.actionLine,
            style: BalmiTheme.body(
              size: 14,
              weight: FontWeight.w800,
              color: BalmiColors.potatoDk,
            ),
          ),
          const Divider(height: 36, color: BalmiColors.line),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              BalmiCopy.brandStoryTitle,
              style: BalmiTheme.body(size: 16, weight: FontWeight.w800),
            ),
            subtitle: Text(
              BalmiCopy.brandStoryHook,
              style: BalmiTheme.body(
                size: 13,
                color: BalmiColors.potato,
                height: 1.4,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: BalmiColors.sub),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BrandStoryScreen()),
              );
            },
          ),
          const Divider(color: BalmiColors.line),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              BalmiCopy.mapCredit,
              style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
            ),
            subtitle: Text(
              '기록 지도는 OpenStreetMap 타일을 씁니다.',
              style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
            ),
          ),
          const Divider(color: BalmiColors.line),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              BalmiCopy.vasaCredit,
              style: BalmiTheme.body(size: 16, weight: FontWeight.w800),
            ),
            subtitle: Text(
              BalmiCopy.vasaCreditDetail,
              style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              title,
              style: BalmiTheme.body(size: 13, weight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              hint,
              style: BalmiTheme.body(size: 13, color: BalmiColors.sub, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
