import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../widgets/activity_circle_picker.dart';
import '../../widgets/activity_pills.dart';
import '../../widgets/circle_action.dart';
import '../../widgets/end_recording_dialog.dart';
import '../../widgets/live_stats_sheet.dart';
import '../../widgets/osm_trace_map.dart';
import '../../widgets/path_spark.dart';
import '../../widgets/recording_alerts_sheet.dart';
import '../../widgets/trust_header.dart';
import '../../domain/engines/meal_walk.dart';
import '../../domain/models/activity.dart';
import '../meal_walk/meal_walk_cards.dart';
import '../meal_walk/meal_walk_controller.dart';
import '../session_detail/session_detail_screen.dart';
import 'recording_controller.dart';

/// Semantics label for the live activity control.
///
/// Must stay stable while auto walk↔run flips — embedding 걷기/뛰기 causes
/// Android to toast the new label when sport changes or the UI tears down.
@visibleForTesting
String recordingActivitySemanticsLabel(ActivityKind activity) =>
    activity.isAuto ? BalmiCopy.activityAuto : activity.label;

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with WidgetsBindingObserver {
  final _mapKey = GlobalKey<OsmTraceMapState>();
  Timer? _clock;
  var _sheetExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final rec = context.read<RecordingController>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      unawaited(rec.onAppBackground());
    }
    if (state == AppLifecycleState.resumed) {
      rec.nudgeGps();
      context.read<MealWalkController>().catchUp();
      rec.clearRecoveredBanner();
    }
  }

  Future<void> _confirmEnd(RecordingController rec) async {
    final dist = rec.snapshot?.totalDistM ?? 0;
    final ok = await EndRecordingDialog.confirm(context, distM: dist);
    if (!ok || !mounted) return;
    final meal = context.read<MealWalkController>();
    if (meal.open?.status == MealWalkStatus.walking) {
      await meal.abortWalk();
    }
    if (!mounted) return;
    // Drop leftover snackbars before leaving — Android may also surface a
    // Semantics toast when the live 걷기/뛰기 label flips or tears down.
    ScaffoldMessenger.of(context).clearSnackBars();
    // Ending the recording UI should not flash meal-walk feedback under the
    // session detail route when Home remounts beneath it.
    meal.lastFeedback = null;
    final nav = Navigator.of(context);
    if (!rec.isRecording) return;
    final id = await rec.stop();
    if (id == null) return;
    if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    await nav.push(
      MaterialPageRoute(builder: (_) => SessionDetailScreen(sessionId: id)),
    );
  }

  Future<void> _tune(RecordingController rec) async {
    await showBalmiSheet(
      context: context,
      builder: (ctx) {
        return ChangeNotifierProvider<RecordingController>.value(
          value: rec,
          child: Consumer<RecordingController>(
            builder: (ctx, live, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ActivityPills(
                      value: live.activity,
                      onChanged: live.setActivity,
                    ),
                    if (live.activity.isTrack) ...[
                      const SizedBox(height: 12),
                      TrackSpecPills(
                        value: live.trackSpecM,
                        onChanged: live.setTrackSpec,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecordingController>();
    final meal = context.watch<MealWalkController>();
    final snap = rec.snapshot;
    final speed = snap?.speedKmh ?? 0;
    final trail = rec.liveTrail;
    final waiting = (snap?.pointCount ?? 0) == 0;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Stack(
              children: [
                Positioned.fill(
                  child: SessionTraceMap(
                    osmKey: _mapKey,
                    points: trail,
                    lastPoint: rec.livePin,
                    emptyLabel: BalmiCopy.waitingGpsShort,
                    height: null,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: TrustHeader(
                    snapshot: snap,
                    waiting: waiting,
                    status: rec.survivalStatus,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Column(
                    children: [
                      CircleAction(
                        icon: Icons.explore_outlined,
                        label: BalmiCopy.resetNorth,
                        size: 44,
                        onTap: () => _mapKey.currentState?.resetNorth(),
                      ),
                      const SizedBox(height: 8),
                      CircleAction(
                        icon: Icons.gps_fixed,
                        label: BalmiCopy.recenterMap,
                        size: 44,
                        onTap: () => _mapKey.currentState?.recenterOnUser(),
                      ),
                      const SizedBox(height: 8),
                      CircleAction(
                        icon: Icons.notifications_outlined,
                        label: BalmiCopy.recordingAlerts,
                        size: 44,
                        onTap: () => showRecordingAlertsSheet(
                          context: context,
                          paused: rec.paused,
                          waitingGps: waiting,
                          lastError: rec.lastError,
                          status: rec.survivalStatus,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (btnCtx) {
                          final autoSport = (snap?.sport ?? 'walk') == 'run'
                              ? ActivityKind.run
                              : ActivityKind.walk;
                          final shown = rec.activity.isAuto
                              ? autoSport
                              : rec.activity;
                          return CircleAction(
                            glyph: ActivityPills.glyphOf(
                              shown,
                              size: 44 * 0.42,
                              color: BalmiColors.ink,
                            ),
                            // Glyph still reflects auto walk↔run; Semantics
                            // label stays stable via [recordingActivitySemanticsLabel].
                            label: recordingActivitySemanticsLabel(rec.activity),
                            size: 44,
                            onTap: () => _tune(rec),
                            onLongPress: () async {
                              final box = btnCtx.findRenderObject() as RenderBox?;
                              final origin = box?.localToGlobal(
                                box.size.center(Offset.zero),
                              );
                              final picked = await showActivityCirclePicker(
                                context: context,
                                selected: rec.activity,
                                origin: origin,
                              );
                              if (picked != null) rec.setActivity(picked);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (rec.lastError != null)
                  Positioned(
                    top: 48,
                    left: 10,
                    right: 64,
                    child: Text(
                      rec.lastError!,
                      style: BalmiTheme.body(
                        size: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (meal.open?.status == MealWalkStatus.walking)
                  Positioned(
                    left: 10,
                    right: 64,
                    bottom: 10,
                    child: MealWalkCountdownBanner(
                      remaining: meal.walkRemaining(rec.elapsed),
                      elapsed: rec.elapsed,
                    ),
                  ),
              ],
            ),
          ),
        ),
        LiveStatsSheet(
          expanded: _sheetExpanded,
          onToggle: () => setState(() => _sheetExpanded = !_sheetExpanded),
          elapsed: rec.elapsed,
          distM: snap?.totalDistM ?? 0,
          speedKmh: speed,
          paused: rec.paused,
          pauseHold: rec.pauseHold,
          altM: rec.liveAlt,
          spark: sparkFromTrail(trail),
          lapCount: snap?.lapCount ?? 0,
          trackMode: snap?.trackMode ?? false,
          showLaps: rec.activity.isAuto || rec.activity.isTrack,
          lastLapTimeS: snap?.lastLapTimeS,
          movingDuration: Duration(milliseconds: snap?.movingDurationMs ?? 0),
          onPause: rec.pause,
          onResume: rec.resumeLive,
          onEnd: () => _confirmEnd(rec),
        ),
      ],
    );
  }
}
