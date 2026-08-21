import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../data/oem/battery_optimization.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(BalmiCopy.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(BalmiCopy.about),
            subtitle: Text('${BalmiCopy.appName} 0.1.1\n${BalmiCopy.oneLiner}'),
          ),
          const Divider(),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(BalmiCopy.vasaCredit),
            subtitle: Text(BalmiCopy.vasaCreditDetail),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(BalmiCopy.oemSettings),
            onTap: () => OemBattery.openOemSettings(),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(BalmiCopy.ignoreBattery),
            onTap: () => OemBattery.requestIgnore(),
          ),
          const SizedBox(height: 24),
          Text(
            'HealthKit / Health Connect는 Release 1에 포함되지 않습니다.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
