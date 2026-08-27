import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/theme.dart';
import '../domain/engines/land_city.dart';
import 'circle_action.dart';

/// End-recording confirm as a Balmi bottom sheet (above the dock).
class EndRecordingDialog extends StatelessWidget {
  const EndRecordingDialog({super.key, required this.distM});

  final double distM;

  /// Returns `true` when the user confirms end; `false` / dismiss cancels.
  static Future<bool> confirm(BuildContext context, {required double distM}) async {
    final ok = await showBalmiSheet<bool>(
      context: context,
      builder: (ctx) => EndRecordingDialog(distM: distM),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final short = !qualifiesForLand(distM);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            BalmiCopy.endConfirmTitle,
            style: BalmiTheme.body(size: 18, weight: FontWeight.w800),
          ),
          if (short) ...[
            const SizedBox(height: 10),
            Text(
              BalmiCopy.endShortWalk,
              style: BalmiTheme.body(size: 14, color: BalmiColors.sub),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(BalmiCopy.endConfirmBack),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(BalmiCopy.endConfirmYes),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
