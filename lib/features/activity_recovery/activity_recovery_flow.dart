import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../domain/engines/activity_recovery.dart';
import '../../domain/models/activity.dart';
import '../../widgets/circle_action.dart';
import 'activity_recovery_controller.dart';

/// Compact entry on session summary / detail.
class ActivityRecoveryEntryCard extends StatelessWidget {
  const ActivityRecoveryEntryCard({
    super.key,
    required this.workoutSessionId,
    required this.activity,
    required this.distanceM,
    required this.duration,
    this.avgSpeedKmh,
    this.existingStatus,
    required this.onStart,
    this.onContinue,
  });

  final String workoutSessionId;
  final ActivityKind activity;
  final double distanceM;
  final Duration duration;
  final double? avgSpeedKmh;
  final RecoveryCheckStatus? existingStatus;
  final VoidCallback onStart;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final done = existingStatus == RecoveryCheckStatus.recovered ||
        existingStatus == RecoveryCheckStatus.stillUnwell ||
        existingStatus == RecoveryCheckStatus.dismissed;
    final pending = existingStatus == RecoveryCheckStatus.recheckPending;
    final inFlight = existingStatus != null && !done;

    return Material(
      color: BalmiColors.mist,
      borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
        onTap: done
            ? null
            : (pending || inFlight)
                ? (onContinue ?? onStart)
                : onStart,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              Icon(
                done
                    ? Icons.check_circle_outline
                    : Icons.favorite_outline,
                color: BalmiColors.potato,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BalmiCopy.activityRecoveryTitle,
                      style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      done
                          ? BalmiCopy.activityRecoveryDoneHint
                          : pending
                              ? BalmiCopy.activityRecoveryPending
                              : inFlight
                                  ? BalmiCopy.activityRecoveryInProgress
                                  : BalmiCopy.activityRecoveryCardHint,
                      style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
                    ),
                  ],
                ),
              ),
              if (!done)
                const Icon(Icons.chevron_right, color: BalmiColors.potato),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openActivityRecoveryFlow(
  BuildContext context, {
  required String workoutSessionId,
  required ActivityKind activity,
  required double distanceM,
  required Duration duration,
  double? avgSpeedKmh,
  String? resumeCheckId,
}) {
  return showBalmiSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<ActivityRecoveryController>(),
      child: ActivityRecoveryFlowSheet(
        workoutSessionId: workoutSessionId,
        activity: activity,
        distanceM: distanceM,
        duration: duration,
        avgSpeedKmh: avgSpeedKmh,
        resumeCheckId: resumeCheckId,
      ),
    ),
  );
}

enum _FlowStep { symptom, guidance, food, recheck, done }

class ActivityRecoveryFlowSheet extends StatefulWidget {
  const ActivityRecoveryFlowSheet({
    super.key,
    required this.workoutSessionId,
    required this.activity,
    required this.distanceM,
    required this.duration,
    this.avgSpeedKmh,
    this.resumeCheckId,
  });

  final String workoutSessionId;
  final ActivityKind activity;
  final double distanceM;
  final Duration duration;
  final double? avgSpeedKmh;
  final String? resumeCheckId;

  @override
  State<ActivityRecoveryFlowSheet> createState() =>
      _ActivityRecoveryFlowSheetState();
}

class _ActivityRecoveryFlowSheetState extends State<ActivityRecoveryFlowSheet> {
  _FlowStep _step = _FlowStep.symptom;
  RecoverySymptom? _symptom;
  RecoveryGuidance? _guidance;
  var _busy = false;
  String? _checkId;
  String? _doneMessage;
  var _suggestMedical = false;
  RecoverySymptom? _recheckPick;

  @override
  void initState() {
    super.initState();
    final id = widget.resumeCheckId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resume(id));
    }
  }

  Future<void> _resume(String id) async {
    final ctrl = context.read<ActivityRecoveryController>();
    final record = await ctrl.store.byId(id);
    if (!mounted || record == null) return;
    setState(() {
      _checkId = record.id;
      _symptom = record.symptom;
      _guidance = guidanceFor(
        symptom: record.symptom,
        metrics: record.metrics,
      );
      if (record.status == RecoveryCheckStatus.recheckPending) {
        _step = _FlowStep.recheck;
      } else if (record.status == RecoveryCheckStatus.guided) {
        _step = _guidance!.offerFoodIntake ? _FlowStep.food : _FlowStep.done;
        if (!_guidance!.offerFoodIntake && !_guidance!.scheduleRecheck) {
          _doneMessage = BalmiCopy.activityRecoveryComplete;
        }
      } else if (record.status.isTerminal) {
        _step = _FlowStep.done;
        _doneMessage = record.notes ?? BalmiCopy.activityRecoveryComplete;
        _suggestMedical =
            record.status == RecoveryCheckStatus.stillUnwell;
      } else {
        _step = _FlowStep.guidance;
      }
    });
  }

  Future<void> _pickSymptom(RecoverySymptom symptom) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ctrl = context.read<ActivityRecoveryController>();
      final record = await ctrl.start(
        workoutSessionId: widget.workoutSessionId,
        activity: widget.activity,
        distanceM: widget.distanceM,
        duration: widget.duration,
        avgSpeedKmh: widget.avgSpeedKmh,
        symptom: symptom,
      );
      final guide = guidanceFor(
        symptom: symptom,
        metrics: record.metrics,
      );
      if (!mounted) return;
      setState(() {
        _checkId = record.id;
        _symptom = symptom;
        _guidance = guide;
        _step = _FlowStep.guidance;
        _suggestMedical = guide.suggestMedicalCare;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _afterGuidance() async {
    final g = _guidance;
    if (g == null) return;
    if (g.offerFoodIntake) {
      setState(() => _step = _FlowStep.food);
      return;
    }
    if (g.scheduleRecheck && _checkId != null) {
      setState(() => _busy = true);
      try {
        final ctrl = context.read<ActivityRecoveryController>();
        final record = await ctrl.store.byId(_checkId!);
        if (record == null) return;
        await ctrl.finishWithoutFood(record: record);
        if (!mounted) return;
        setState(() {
          _step = _FlowStep.done;
          _doneMessage = BalmiCopy.activityRecoveryScheduled;
        });
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }
    setState(() {
      _step = _FlowStep.done;
      _doneMessage = BalmiCopy.activityRecoveryComplete;
    });
  }

  Future<void> _pickFood(RecoveryFood food) async {
    if (_busy || _checkId == null) return;
    setState(() => _busy = true);
    try {
      final ctrl = context.read<ActivityRecoveryController>();
      final record = await ctrl.store.byId(_checkId!);
      if (record == null) return;
      final updated = await ctrl.logFood(record: record, food: food);
      if (!mounted) return;
      setState(() {
        if (updated.status == RecoveryCheckStatus.recheckPending) {
          _step = _FlowStep.done;
          _doneMessage = BalmiCopy.activityRecoveryScheduled;
        } else {
          _step = _FlowStep.done;
          _doneMessage = BalmiCopy.activityRecoveryComplete;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _answerRecheck(bool ok) async {
    if (_busy || _checkId == null) return;
    if (!ok && _recheckPick == null) {
      setState(() => _recheckPick = _symptom);
    }
    setState(() => _busy = true);
    try {
      final ctrl = context.read<ActivityRecoveryController>();
      final record = await ctrl.store.byId(_checkId!);
      if (record == null) return;
      final updated = await ctrl.answerRecheck(
        record: record,
        feelingOk: ok,
        stillSymptom: ok ? null : (_recheckPick ?? record.symptom),
      );
      if (!mounted) return;
      setState(() {
        _step = _FlowStep.done;
        _doneMessage = updated.notes ??
            (ok
                ? BalmiCopy.activityRecoveryComplete
                : BalmiCopy.activityRecoveryMedical);
        _suggestMedical = !ok;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Drag handle, keyboard inset, and dock clearance come from [showBalmiSheet].
    final maxH = MediaQuery.sizeOf(context).height * 0.85;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              BalmiCopy.activityRecoveryTitle,
              style: BalmiTheme.body(size: 18, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              BalmiCopy.activityRecoveryDisclaimer,
              style: BalmiTheme.body(size: 12, color: BalmiColors.sub, height: 1.4),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: _body(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_busy && _step == _FlowStep.symptom) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    switch (_step) {
      case _FlowStep.symptom:
        return _symptomStep();
      case _FlowStep.guidance:
        return _guidanceStep();
      case _FlowStep.food:
        return _foodStep();
      case _FlowStep.recheck:
        return _recheckStep();
      case _FlowStep.done:
        return _doneStep();
    }
  }

  Widget _symptomStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          BalmiCopy.activityRecoveryHowFeel,
          style: BalmiTheme.body(size: 16, weight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in RecoverySymptom.selectable)
              ActionChip(
                label: Text(s.label),
                onPressed: _busy ? null : () => _pickSymptom(s),
                backgroundColor: BalmiColors.mist,
                side: const BorderSide(color: BalmiColors.line),
                labelStyle: BalmiTheme.body(size: 14, weight: FontWeight.w700),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _guidanceStep() {
    final g = _guidance;
    if (g == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          g.title,
          style: BalmiTheme.body(size: 16, weight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          g.contextNote,
          style: BalmiTheme.body(size: 14, height: 1.45),
        ),
        const SizedBox(height: 12),
        for (final step in g.steps)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('· ', style: TextStyle(fontWeight: FontWeight.w800)),
                Expanded(
                  child: Text(step, style: BalmiTheme.body(size: 14, height: 1.4)),
                ),
              ],
            ),
          ),
        if (g.suggestMedicalCare) ...[
          const SizedBox(height: 8),
          Text(
            BalmiCopy.activityRecoveryMedical,
            style: BalmiTheme.body(
              size: 13,
              weight: FontWeight.w700,
              color: BalmiColors.plum,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _afterGuidance,
          child: Text(
            g.offerFoodIntake
                ? BalmiCopy.activityRecoveryNext
                : BalmiCopy.activityRecoveryDone,
          ),
        ),
      ],
    );
  }

  Widget _foodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          BalmiCopy.activityRecoveryFoodAsk,
          style: BalmiTheme.body(size: 16, weight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in RecoveryFood.chips)
              ActionChip(
                label: Text(f.label),
                onPressed: _busy ? null : () => _pickFood(f),
                backgroundColor: BalmiColors.mist,
                side: const BorderSide(color: BalmiColors.line),
                labelStyle: BalmiTheme.body(size: 14, weight: FontWeight.w700),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => _pickFood(RecoveryFood.later),
          child: const Text(BalmiCopy.activityRecoveryFoodSkip),
        ),
      ],
    );
  }

  Widget _recheckStep() {
    final prompt = _symptom?.recheckPrompt ?? BalmiCopy.activityRecoveryHowFeel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          prompt,
          style: BalmiTheme.body(size: 16, weight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : () => _answerRecheck(true),
          child: const Text(BalmiCopy.activityRecoveryOk),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () {
                  setState(() => _recheckPick ??= _symptom);
                },
          child: const Text(BalmiCopy.activityRecoveryStillBad),
        ),
        if (_recheckPick != null) ...[
          const SizedBox(height: 12),
          Text(
            BalmiCopy.activityRecoveryHowFeel,
            style: BalmiTheme.body(size: 14, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in RecoverySymptom.selectable.where(
                (e) => e != RecoverySymptom.normal,
              ))
                ChoiceChip(
                  label: Text(s.label),
                  selected: _recheckPick == s,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() => _recheckPick = s),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : () => _answerRecheck(false),
            child: const Text(BalmiCopy.activityRecoveryDone),
          ),
        ],
      ],
    );
  }

  Widget _doneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _doneMessage ?? BalmiCopy.activityRecoveryComplete,
          style: BalmiTheme.body(size: 15, height: 1.45),
        ),
        if (_suggestMedical) ...[
          const SizedBox(height: 12),
          Text(
            BalmiCopy.activityRecoveryMedical,
            style: BalmiTheme.body(
              size: 13,
              weight: FontWeight.w700,
              color: BalmiColors.plum,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(BalmiCopy.activityRecoveryDone),
        ),
      ],
    );
  }
}
