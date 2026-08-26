import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../widgets/balmi_app_bar.dart';
import '../meal_walk/meal_walk_controller.dart';
import '../meal_walk/meal_walk_onboarding.dart';
import 'daily_goals_picker.dart';

/// Health habits only — meal walk + daily goals. Not general settings.
class HealthHabitsScreen extends StatelessWidget {
  const HealthHabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meal = context.watch<MealWalkController>();
    final vasa = meal.vasa;
    final delay = vasa.meanReaction;
    return Scaffold(
      backgroundColor: BalmiColors.paper,
      appBar: const BalmiAppBar(title: BalmiCopy.mealWalkHealthSection),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
            activeThumbColor: BalmiColors.potato,
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
          const SizedBox(height: 8),
          const Divider(color: BalmiColors.line),
          const DailyGoalsPicker(),
        ],
      ),
    );
  }
}
