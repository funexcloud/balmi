import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/oem/battery_optimization.dart';
import '../../widgets/balmi_app_bar.dart';
import '../../widgets/balmi_wordmark.dart';
import '../meal_walk/meal_walk_controller.dart';
import '../meal_walk/meal_walk_onboarding.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meal = context.watch<MealWalkController>();
    final vasa = meal.vasa;
    final delay = vasa.meanReaction;
    return Scaffold(
      backgroundColor: BalmiColors.paper,
      appBar: const BalmiAppBar(title: BalmiCopy.settings),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const BalmiWordmark(height: 34),
          const SizedBox(height: 16),
          Text(
            BalmiCopy.mealWalkHealthSection,
            style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              BalmiCopy.mealWalkTitle,
              style: BalmiTheme.body(size: 16, weight: FontWeight.w800),
            ),
            subtitle: Text(
              meal.enabled ? BalmiCopy.mealWalkOn : BalmiCopy.mealWalkOff,
              style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
            ),
            value: meal.enabled,
            onChanged: (on) async {
              if (on) {
                await openMealWalkOnboarding(context, meal);
              } else {
                await meal.disable();
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline, color: BalmiColors.potato),
            title: Text(
              BalmiCopy.mealWalkWhatIs,
              style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
            ),
            onTap: () => showMealWalkDisclaimer(context),
          ),
          if (meal.badgeAt != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified, color: BalmiColors.sage),
              title: Text(
                BalmiCopy.mealWalkBadge,
                style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
              ),
              subtitle: Text(
                BalmiCopy.mealWalkBadgeHint,
                style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
              ),
            ),
          if (meal.enabled) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                BalmiCopy.mealWalkAdherence,
                style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
              ),
              subtitle: Text(
                '${(vasa.adherenceRate * 100).round()}% · ${vasa.completedSessions}/${vasa.promptedSessions}',
                style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                BalmiCopy.mealWalkReaction,
                style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
              ),
              subtitle: Text(
                delay == null ? '—' : formatElapsed(delay),
                style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
              ),
            ),
          ],
          const Divider(color: BalmiColors.line),
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
