import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/engines/meal_walk.dart';
import '../settings/health_habits_screen.dart';
import 'meal_walk_cards.dart';
import 'meal_walk_controller.dart';

/// Dedicated Hub screen for managing daily post-meal walks.
/// Allows users to view all 3 meals today (Breakfast, Lunch, Dinner),
/// start 30-min timers, and catch up on 15-min walks at any time during the day.
class MealWalkHubScreen extends StatefulWidget {
  const MealWalkHubScreen({super.key});

  @override
  State<MealWalkHubScreen> createState() => _MealWalkHubScreenState();
}

class _MealWalkHubScreenState extends State<MealWalkHubScreen> {
  Map<MealType, MealWalkSession?> _todaySessions = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTodaySessions();
  }

  Future<void> _loadTodaySessions() async {
    final mealController = context.read<MealWalkController>();
    final allSessions = await mealController.store.listSessions();
    final today = DateTime.now();
    
    final map = <MealType, MealWalkSession?>{};
    for (final meal in MealType.values) {
      MealWalkSession? match;
      for (final s in allSessions) {
        if (s.mealType == meal && sameLocalDay(s.mealStartedAt, today)) {
          match = s;
          break;
        }
      }
      map[meal] = match;
    }

    if (!mounted) return;
    setState(() {
      _todaySessions = map;
      _loading = false;
    });
  }

  Future<void> _onStartMeal(MealWalkController mealCtrl, MealType meal) async {
    await mealCtrl.confirmMealStart(meal);
    await _loadTodaySessions();
    if (!mounted) return;
    await snackMealWalk(context, mealCtrl);
  }

  Future<void> _onStartWalk(MealWalkController mealCtrl, MealType meal) async {
    final session = _todaySessions[meal];
    if (session != null) {
      await mealCtrl.beginWalk(session.id);
    } else {
      final newSession = await mealCtrl.confirmMealStart(meal);
      if (newSession != null) {
        await mealCtrl.beginWalk(newSession.id);
      }
    }
    await _loadTodaySessions();
    if (!mounted) return;
    await snackMealWalk(context, mealCtrl);
  }

  @override
  Widget build(BuildContext context) {
    final mealCtrl = context.watch<MealWalkController>();

    return Scaffold(
      backgroundColor: BalmiColors.paper,
      appBar: AppBar(
        backgroundColor: BalmiColors.paper,
        elevation: 0,
        title: Text(
          BalmiCopy.mealWalkHubTitle,
          style: BalmiTheme.body(size: 18, weight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined, color: BalmiColors.ink),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HealthHabitsScreen()),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                // Header Hero Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: BalmiColors.ink,
                    borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🍚', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              BalmiCopy.mealWalkHubTitle,
                              style: BalmiTheme.body(
                                size: 18,
                                color: BalmiColors.paper,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: BalmiColors.potato,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              mealCtrl.enabled ? '활성화됨' : '비활성',
                              style: BalmiTheme.body(
                                size: 11,
                                color: Colors.white,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        BalmiCopy.mealWalkHubSubtitle,
                        style: BalmiTheme.body(
                          size: 13,
                          color: const Color(0xFFD9CFC2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.stars, color: BalmiColors.amber, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '참여율: ${(mealCtrl.vasa.adherenceRate * 100).round()}%',
                            style: BalmiTheme.body(
                              size: 12,
                              color: BalmiColors.amber,
                              weight: FontWeight.w700,
                            ),
                          ),
                          if (mealCtrl.badgeAt != null) ...[
                            const SizedBox(width: 12),
                            const Text('🏅', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              BalmiCopy.mealWalkBadge,
                              style: BalmiTheme.body(
                                size: 12,
                                color: BalmiColors.paper,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Catch-up / Notice Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF2E8),
                    border: Border.all(color: BalmiColors.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: BalmiColors.potato, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          BalmiCopy.mealWalkCatchUpHint,
                          style: BalmiTheme.body(size: 12, color: BalmiColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Today's 3 Meals Cards
                Text(
                  '오늘의 식후 혈당 산책 (아침 · 점심 · 저녁)',
                  style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
                ),
                const SizedBox(height: 12),

                for (final meal in MealType.values) ...[
                  _MealSlotCard(
                    meal: meal,
                    session: _todaySessions[meal],
                    onStartMeal: () => _onStartMeal(mealCtrl, meal),
                    onStartWalk: () => _onStartWalk(mealCtrl, meal),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _MealSlotCard extends StatelessWidget {
  const _MealSlotCard({
    required this.meal,
    required this.session,
    required this.onStartMeal,
    required this.onStartWalk,
  });

  final MealType meal;
  final MealWalkSession? session;
  final VoidCallback onStartMeal;
  final VoidCallback onStartWalk;

  @override
  Widget build(BuildContext context) {
    final hasSession = session != null;
    final status = session?.status;
    final isCompleted = status == MealWalkStatus.completed;
    final isPending = status == MealWalkStatus.pending;
    final isPromptedOrWalking = status == MealWalkStatus.prompted || status == MealWalkStatus.walking;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isCompleted
              ? BalmiColors.sage
              : isPromptedOrWalking
                  ? BalmiColors.potato
                  : BalmiColors.line,
          width: isPromptedOrWalking || isCompleted ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _mealIcon(meal),
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 8),
              Text(
                meal.label,
                style: BalmiTheme.body(size: 16, weight: FontWeight.w800),
              ),
              const Spacer(),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 10),

          if (isCompleted) ...[
            Text(
              '✅ 식후 15분 걷기 완수! (기록 및 VASA 반응 완료)',
              style: BalmiTheme.body(size: 13, color: BalmiColors.sage, weight: FontWeight.w700),
            ),
            if (session?.walkDurationSec != null || session?.distanceM != null) ...[
              const SizedBox(height: 4),
              Text(
                '${formatElapsed(Duration(seconds: session!.walkDurationSec ?? 0))} · ${formatKm(session?.distanceM ?? 0)}km',
                style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
              ),
            ],
          ] else if (isPending) ...[
            Builder(
              builder: (context) {
                final diff = walkPromptAt(session!.mealStartedAt).difference(DateTime.now());
                final left = diff.isNegative ? Duration.zero : diff;
                return Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, color: BalmiColors.potato, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '식후 30분 대기 중',
                        style: BalmiTheme.body(size: 13, weight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      formatElapsed(left),
                      style: BalmiTheme.num(size: 16, color: BalmiColors.potatoDk),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BalmiColors.potato,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.directions_walk, size: 20),
                label: Text(
                  BalmiCopy.mealWalkStartWalkNow,
                  style: BalmiTheme.body(size: 14, color: Colors.white, weight: FontWeight.w800),
                ),
                onPressed: onStartWalk,
              ),
            ),
          ] else if (isPromptedOrWalking) ...[
            Text(
              '🔔 식후 30분이 되었습니다! 15분 걸어보세요.',
              style: BalmiTheme.body(size: 13, color: BalmiColors.potatoDk, weight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BalmiColors.potato,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(
                  BalmiCopy.mealWalkGoShort,
                  style: BalmiTheme.body(size: 14, color: Colors.white, weight: FontWeight.w800),
                ),
                onPressed: onStartWalk,
              ),
            ),
          ] else ...[
            // Not started or missed/catch-up
            Text(
              hasSession
                  ? '⚠️ 알림 시간이 지났지만, 언제라도 15분 걷기를 수행할 수 있습니다.'
                  : '식사를 하셨거나 시작 시 식사 시작 버튼을 눌러주세요.',
              style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BalmiColors.ink,
                      side: const BorderSide(color: BalmiColors.line),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.restaurant, size: 18),
                    label: Text(
                      BalmiCopy.mealWalkStartBtn,
                      style: BalmiTheme.body(size: 13, weight: FontWeight.w700),
                    ),
                    onPressed: onStartMeal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BalmiColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.directions_walk, size: 18),
                    label: Text(
                      BalmiCopy.mealWalkStartWalkNow,
                      style: BalmiTheme.body(size: 13, color: Colors.white, weight: FontWeight.w700),
                    ),
                    onPressed: onStartWalk,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _mealIcon(MealType type) => switch (type) {
        MealType.breakfast => '🥣',
        MealType.lunch => '🍱',
        MealType.dinner => '🍲',
      };

  Widget _statusChip(MealWalkStatus? status) {
    final text = switch (status) {
      MealWalkStatus.completed => '완료',
      MealWalkStatus.mealCountdown => '30분 대기 중',
      MealWalkStatus.readyToWalk => '지금 걷기 가능',
      MealWalkStatus.walking => '걷기 진행 중',
      MealWalkStatus.paused => '이어 걷기 가능',
      MealWalkStatus.expired => '목표 미달성',
      _ => '미시작',
    };

    final color = switch (status) {
      MealWalkStatus.completed => BalmiColors.sage,
      MealWalkStatus.mealCountdown => BalmiColors.potato,
      MealWalkStatus.readyToWalk || MealWalkStatus.walking || MealWalkStatus.paused => BalmiColors.amber,
      MealWalkStatus.expired => BalmiColors.sub,
      _ => BalmiColors.sub,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: BalmiTheme.body(size: 11, color: color, weight: FontWeight.w800),
      ),
    );
  }
}

/// Helper function to open the Meal Walk Hub screen.
void openMealWalkHub(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const MealWalkHubScreen()),
  );
}
