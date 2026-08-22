import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/models/sport.dart';
import '../../widgets/balmi_app_bar.dart';
import '../session_detail/session_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SessionRepository>();
    return Scaffold(
      backgroundColor: BalmiColors.paper,
      appBar: const BalmiAppBar(title: BalmiCopy.history),
      body: StreamBuilder<List<Session>>(
        stream: repo.watchHistory(),
        builder: (context, snap) {
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                '아직 끝난 기록이 없어요',
                style: BalmiTheme.body(size: 15, color: BalmiColors.sub),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = items[i];
              final recovered = s.status == SessionStatus.recovered.wire;
              return Card(
                child: ListTile(
                  title: Text(
                    formatDateTime(s.startedAt),
                    style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${formatKm(s.totalDistM)} km · ${BalmiCopy.walk} ${formatKm(s.walkDistM)} · ${BalmiCopy.run} ${formatKm(s.runDistM)}'
                    '${recovered ? ' · 복구 종료' : ''}',
                    style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SessionDetailScreen(sessionId: s.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
