import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/oem/battery_optimization.dart';
import '../../widgets/balmi_app_bar.dart';
import '../../widgets/balmi_wordmark.dart';
import 'brand_story_screen.dart';

/// App settings — about, brand story, credits, OEM battery.
/// Health habits live on [HealthHabitsScreen].
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
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              BalmiCopy.about,
              style: BalmiTheme.body(size: 16, weight: FontWeight.w800),
            ),
            subtitle: Text(
              '${BalmiCopy.appName} ${BalmiCopy.versionLabel}\n${BalmiCopy.oneLiner}',
              style: BalmiTheme.body(
                size: 13,
                color: BalmiColors.sub,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            BalmiCopy.subcopy,
            style: BalmiTheme.body(size: 13, color: BalmiColors.potatoDk),
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
