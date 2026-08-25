import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/theme.dart';
import '../domain/engines/land_city.dart';

class EndRecordingDialog extends StatelessWidget {
  const EndRecordingDialog({super.key, required this.distM});

  final double distM;

  static Future<bool> confirm(BuildContext context, {required double distM}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => EndRecordingDialog(distM: distM),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final short = !qualifiesForLand(distM);
    return AlertDialog(
      backgroundColor: BalmiColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
      ),
      title: Text(
        BalmiCopy.endConfirmTitle,
        style: BalmiTheme.body(size: 18, weight: FontWeight.w800),
      ),
      content: short
          ? Text(
              BalmiCopy.endShortWalk,
              style: BalmiTheme.body(size: 14, color: BalmiColors.sub),
            )
          : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            BalmiCopy.endConfirmBack,
            style: BalmiTheme.body(size: 15, weight: FontWeight.w800, color: BalmiColors.ink),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(BalmiCopy.endConfirmYes),
        ),
      ],
    );
  }
}
