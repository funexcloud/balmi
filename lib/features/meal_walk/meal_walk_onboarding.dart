import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../domain/engines/meal_walk.dart';
import '../../widgets/safe_cta.dart';
import 'meal_walk_controller.dart';

class MealWalkOnboardingScreen extends StatefulWidget {
  const MealWalkOnboardingScreen({super.key, required this.controller});

  final MealWalkController controller;

  @override
  State<MealWalkOnboardingScreen> createState() =>
      _MealWalkOnboardingScreenState();
}

class _MealWalkOnboardingScreenState extends State<MealWalkOnboardingScreen> {
  final _page = PageController();
  var _index = 0;
  var _breakfast = DayMinutes.breakfastDefault;
  var _lunch = DayMinutes.lunchDefault;
  var _dinner = DayMinutes.dinnerDefault;

  @override
  void initState() {
    super.initState();
    final s = widget.controller.schedule;
    _breakfast = s.breakfast;
    _lunch = s.lunch;
    _dinner = s.dinner;
  }

  Future<void> _next() async {
    if (_index == 3) {
      await widget.controller.enable(
        acknowledgedAt: DateTime.now(),
        breakfast: _breakfast,
        lunch: _lunch,
        dinner: _dinner,
      );
      if (!mounted) return;
      await _page.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      return;
    }
    await _page.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BalmiColors.paper,
      appBar: AppBar(
        title: Text(
          BalmiCopy.mealWalkTitle,
          style: BalmiTheme.body(size: 18, weight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _IntroStep(),
                  _DisclaimerStep(onAck: _next),
                  _TimesStep(
                    breakfast: _breakfast,
                    lunch: _lunch,
                    dinner: _dinner,
                    onBreakfast: (v) => setState(() => _breakfast = v),
                    onLunch: (v) => setState(() => _lunch = v),
                    onDinner: (v) => setState(() => _dinner = v),
                  ),
                  _NotifStep(),
                  _ReadyStep(onDone: () => Navigator.of(context).pop(true)),
                ],
              ),
            ),
            if (_index != 1 && _index != 4)
              SafePrimaryButton(
                label: _index == 3 ? BalmiCopy.notificationPermission : BalmiCopy.continueLabel,
                onPressed: _next,
              ),
          ],
        ),
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.directions_walk, size: 72, color: BalmiColors.potato),
          const SizedBox(height: 20),
          Text(
            BalmiCopy.mealWalkIntro,
            style: BalmiTheme.body(size: 22, weight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            BalmiCopy.mealWalkIntroBody,
            style: BalmiTheme.body(size: 15, color: BalmiColors.sub),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerStep extends StatelessWidget {
  const _DisclaimerStep({required this.onAck});

  final VoidCallback onAck;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            BalmiCopy.mealWalkWhatIs,
            style: BalmiTheme.body(size: 20, weight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Text(
            BalmiCopy.mealWalkDisclaimer,
            style: BalmiTheme.body(size: 15, height: 1.55),
          ),
          const Spacer(),
          SafePrimaryButton(label: BalmiCopy.mealWalkAck, onPressed: onAck),
        ],
      ),
    );
  }
}

class _TimesStep extends StatelessWidget {
  const _TimesStep({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.onBreakfast,
    required this.onLunch,
    required this.onDinner,
  });

  final DayMinutes breakfast;
  final DayMinutes lunch;
  final DayMinutes dinner;
  final ValueChanged<DayMinutes> onBreakfast;
  final ValueChanged<DayMinutes> onLunch;
  final ValueChanged<DayMinutes> onDinner;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      children: [
        Text(
          BalmiCopy.mealWalkMealTimes,
          style: BalmiTheme.body(size: 20, weight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          BalmiCopy.mealWalkMealTimesHint,
          style: BalmiTheme.body(size: 14, color: BalmiColors.sub),
        ),
        const SizedBox(height: 16),
        _TimeTile(
          icon: Icons.wb_sunny_outlined,
          label: BalmiCopy.breakfast,
          value: breakfast,
          onChanged: onBreakfast,
        ),
        _TimeTile(
          icon: Icons.lunch_dining_outlined,
          label: BalmiCopy.lunch,
          value: lunch,
          onChanged: onLunch,
        ),
        _TimeTile(
          icon: Icons.nights_stay_outlined,
          label: BalmiCopy.dinner,
          value: dinner,
          onChanged: onDinner,
        ),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final DayMinutes value;
  final ValueChanged<DayMinutes> onChanged;

  @override
  Widget build(BuildContext context) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: BalmiColors.potato),
      title: Text(label, style: BalmiTheme.body(size: 16, weight: FontWeight.w800)),
      trailing: Text('$hh:$mm', style: BalmiTheme.num(size: 20)),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: value.hour, minute: value.minute),
        );
        if (picked != null) {
          onChanged(DayMinutes.fromHm(picked.hour, picked.minute));
        }
      },
    );
  }
}

class _NotifStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_outlined, size: 72, color: BalmiColors.potato),
          const SizedBox(height: 20),
          Text(
            BalmiCopy.mealWalkNotifNeed,
            style: BalmiTheme.body(size: 22, weight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ReadyStep extends StatelessWidget {
  const _ReadyStep({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 72, color: BalmiColors.sage),
          const SizedBox(height: 20),
          Text(
            BalmiCopy.mealWalkReady,
            style: BalmiTheme.body(size: 22, weight: FontWeight.w800),
          ),
          const Spacer(),
          SafePrimaryButton(label: BalmiCopy.done, onPressed: onDone),
        ],
      ),
    );
  }
}

Future<bool> openMealWalkOnboarding(
  BuildContext context,
  MealWalkController controller,
) async {
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => MealWalkOnboardingScreen(controller: controller),
    ),
  );
  return ok == true;
}

Future<void> showMealWalkDisclaimer(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: BalmiColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
      ),
      title: Text(
        BalmiCopy.mealWalkWhatIs,
        style: BalmiTheme.body(size: 18, weight: FontWeight.w800),
      ),
      content: Text(
        BalmiCopy.mealWalkDisclaimer,
        style: BalmiTheme.body(size: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(BalmiCopy.mealWalkAck),
        ),
      ],
    ),
  );
}
