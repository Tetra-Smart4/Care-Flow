import 'package:flutter/material.dart';
import '../services/feature_service.dart';
import '../widgets/feature_widgets.dart';
import '../../../ui/theme/careflow_ui_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final service = CareFlowFeatureService.instance;
  bool loading = true;
  List<Map<String, dynamic>> rows = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      rows = await service.patientNotifications();
    } catch (_) {
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
      title: 'Notifications',
      subtitle: 'Your latest CareFlow updates',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'You are all caught up',
                  message:
                      'Appointment, queue and care updates will appear here.')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  children: rows
                      .map((r) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                              onTap: () => service
                                  .markNotificationRead('${r['id']}')
                                  .then((_) => _load()),
                              leading: CircleAvatar(
                                  backgroundColor: CareFlowUIColors.softBlue,
                                  child: const Icon(Icons.notifications_rounded,
                                      color: CareFlowUIColors.primary)),
                              title: Text('${r['title'] ?? ''}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900)),
                              subtitle: Text(
                                  '${r['body'] ?? ''}\n${r['created_at'] ?? ''}'),
                              isThreeLine: true,
                              trailing: r['read_at'] == null
                                  ? const CircleAvatar(
                                      radius: 4,
                                      backgroundColor: CareFlowUIColors.primary)
                                  : null)))
                      .toList()));
}
