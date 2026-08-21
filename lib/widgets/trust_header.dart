import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../data/recording/recording_snapshot.dart';

class TrustHeader extends StatelessWidget {
  const TrustHeader({super.key, required this.snapshot});

  final RecordingSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    final pending = s?.pendingChunks ?? 0;
    final synced = pending == 0 && (s?.pointCount ?? 0) > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _chip(
            Icons.signal_cellular_alt,
            '${BalmiCopy.gps} ${BalmiCopy.gpsStrength(s?.gpsStrength ?? 'none')}',
          ),
          _chip(Icons.save_outlined, '${BalmiCopy.localPoints} ${s?.pointCount ?? 0}'),
          _chip(Icons.cloud_queue, '${BalmiCopy.syncPending} $pending'),
          _chip(
            synced ? Icons.check_circle : Icons.hourglass_empty,
            synced ? '${BalmiCopy.syncDone} ✓' : BalmiCopy.syncDone,
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF3C9A78)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
