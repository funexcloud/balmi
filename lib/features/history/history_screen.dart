import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/sport.dart';
import '../../widgets/balmi_app_bar.dart';
import '../../widgets/session_row.dart';
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: BalmiColors.line),
            itemBuilder: (context, i) {
              final s = items[i];
              final recovered = s.status == SessionStatus.recovered.wire;
              return SessionRow(
                startedAt: s.startedAt,
                activityLabel: ActivityKind.fromWire(s.activity).label,
                distM: s.totalDistM,
                trailing: recovered ? '복구 종료' : null,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SessionDetailScreen(sessionId: s.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
