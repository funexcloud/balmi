import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/oem/battery_optimization.dart';
import '../../widgets/balmi_app_bar.dart';
import '../../widgets/balmi_wordmark.dart';

/// App settings — about, credits, OEM battery. Health habits live on
/// [HealthHabitsScreen].
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
            BalmiCopy.heroLine,
            style: BalmiTheme.body(size: 13, color: BalmiColors.sub, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            BalmiCopy.about,
            style: BalmiTheme.body(size: 16, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${BalmiCopy.aboutTitle}  ·  ${BalmiCopy.versionLabel}',
            style: BalmiTheme.body(size: 13, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            BalmiCopy.oneLiner,
            style: BalmiTheme.body(
              size: 13,
              color: BalmiColors.sub,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          const _AboutBullet(BalmiCopy.aboutBulletModes),
          const _AboutBullet(BalmiCopy.aboutBulletOffline),
          const _AboutBullet(BalmiCopy.aboutBulletRecovery),
          const SizedBox(height: 16),
          Text(
            BalmiCopy.aboutClosing,
            style: BalmiTheme.body(size: 14, weight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            BalmiCopy.subcopy,
            style: BalmiTheme.body(size: 13, color: BalmiColors.potatoDk),
          ),
          const Divider(height: 36, color: BalmiColors.line),
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
          const Divider(color: BalmiColors.line),
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
        ],
      ),
    );
  }
}

class _AboutBullet extends StatelessWidget {
  const _AboutBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '·',
            style: BalmiTheme.body(
              size: 14,
              weight: FontWeight.w800,
              color: BalmiColors.potato,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: BalmiTheme.body(size: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
