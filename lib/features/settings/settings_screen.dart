import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/oem/battery_optimization.dart';
import '../../widgets/balmi_app_bar.dart';
import '../../widgets/balmi_wordmark.dart';

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
          const BalmiWordmark(height: 28),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(BalmiCopy.about, style: BalmiTheme.body(size: 16, weight: FontWeight.w800)),
            subtitle: Text(
              '${BalmiCopy.appName} ${BalmiCopy.versionLabel}\n${BalmiCopy.oneLiner}',
              style: BalmiTheme.body(size: 13, color: BalmiColors.sub, height: 1.45),
            ),
          ),
          const Divider(color: BalmiColors.line),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(BalmiCopy.vasaCredit, style: BalmiTheme.body(size: 16, weight: FontWeight.w800)),
            subtitle: Text(
              BalmiCopy.vasaCreditDetail,
              style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
            ),
          ),
          const Divider(color: BalmiColors.line),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(BalmiCopy.oemSettings, style: BalmiTheme.body(size: 15, weight: FontWeight.w800)),
            onTap: () => OemBattery.openOemSettings(),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(BalmiCopy.ignoreBattery, style: BalmiTheme.body(size: 15, weight: FontWeight.w800)),
            onTap: () => OemBattery.requestIgnore(),
          ),
          const SizedBox(height: 24),
          Text(
            'HealthKit / Health Connect는 Release 1에 포함되지 않습니다.',
            style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
          ),
        ],
      ),
    );
  }
}
