import 'package:flutter/material.dart';
import 'package:fitness_coach/database/session_dao.dart';
import 'package:fitness_coach/models/workout_session.dart';
import 'package:fitness_coach/pages/history_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  static HistoryPageState? of(BuildContext context) {
    return context.findAncestorStateOfType<HistoryPageState>();
  }

  @override
  State<HistoryPage> createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  final SessionDao _dao = SessionDao();
  List<WorkoutSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await _dao.getAll();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  /// 供外部调用以刷新列表（如训练完成后）
  void refresh() {
    _loading = true;
    if (mounted) setState(() {});
    _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('训练历史')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('还没有训练记录',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('去完成第一次训练吧！',
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                            session.finishedAt != null
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                            color: session.finishedAt != null
                                ? Colors.green
                                : Colors.orange),
                        title: Text(session.finishedAt != null
                            ? session.planName
                            : '${session.planName} (未完成)'),
                        subtitle: Text(
                            '${session.formattedDate} · ${session.completedExercises.length}动作 · ${session.formattedDuration}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  HistoryDetailPage(session: session),
                            ),
                          );
                          _loadSessions();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
