import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/feature_service.dart';
import '../widgets/feature_widgets.dart';
import '../../../ui/theme/careflow_ui_theme.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final service = CareFlowFeatureService.instance;

  Timer? timer;

  List<Map<String, dynamic>> rows = const [];

  bool loading = true;

  String? error;

  String role = 'patient';

  String? clinicId;

  @override
  void initState() {
    super.initState();

    _load();

    timer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _load(silent: true),
    );
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final profile = await _profile();

      role = profile?['role']?.toString() ?? 'patient';

      if (role == 'patient') {
        final appointments = await service.patientAppointments();

        final active = appointments
            .where(
              (a) =>
                  a.tokenNo != null &&
                  a.status != 'cancelled' &&
                  a.status != 'completed',
            )
            .toList();

        if (active.isEmpty) {
          rows = [];
          clinicId = null;
        } else {
          clinicId = active.first.clinicId;

          rows = await service.queue(
            clinicId!,
            DateTime.now(),
          );
        }
      } else if (role == 'doctor') {
        final appointments = await service.doctorAppointments();

        final active = appointments
            .where(
              (a) =>
                  a.tokenNo != null &&
                  a.status != 'cancelled' &&
                  a.status != 'completed',
            )
            .toList();

        clinicId = active.isNotEmpty
            ? active.first.clinicId
            : (appointments.isNotEmpty ? appointments.first.clinicId : null);

        rows = active
            .map(
              (a) => <String, dynamic>{
                'token_no': a.tokenNo,
                'status': a.status,
                'patient_name': a.patientName ?? 'Patient',
                'doctor_name': a.doctorName ?? 'Doctor',
                'clinic_id': a.clinicId,
              },
            )
            .toList();
      } else {
        final appointments = await service.clinicAppointments();

        clinicId = service.userId;

        rows = appointments
            .where(
              (a) =>
                  a.tokenNo != null &&
                  a.status != 'cancelled' &&
                  a.status != 'completed',
            )
            .map(
              (a) => <String, dynamic>{
                'token_no': a.tokenNo,
                'status': a.status,
                'patient_name': a.patientName ?? 'Patient',
                'doctor_name': a.doctorName ?? 'Doctor',
                'clinic_id': a.clinicId,
              },
            )
            .toList();
      }

      rows.sort(
        (a, b) => ((a['token_no'] as num?) ?? 0).compareTo(
          (b['token_no'] as num?) ?? 0,
        ),
      );

      if (!mounted) return;

      setState(() {
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = '$e';
        loading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _profile() async {
    final user = service._client.auth.currentUser;

    if (user == null) return null;

    return await service._client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
  }

  Future<void> _advance() async {
    if (clinicId == null) return;

    try {
      final next = await service.advanceQueue(clinicId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Current token moved to #$next'),
        ),
      );

      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not advance queue: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAdvance = role == 'clinic' || role == 'doctor';

    return FeatureScaffold(
      title: 'Live queue',
      subtitle: 'Updates every few seconds',
      child: loading && rows.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null && rows.isEmpty
              ? EmptyState(
                  icon: Icons.wifi_tethering_error_rounded,
                  title: 'Queue unavailable',
                  message: error!,
                  action: FilledButton(
                    onPressed: _load,
                    child: const Text('Retry'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    8,
                    18,
                    40,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1D4ED8),
                            Color(0xFF0F9D8A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.groups_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Today's queue",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${rows.length} active tokens',
                                  style: const TextStyle(
                                    color: Color(0xE6FFFFFF),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (canAdvance)
                            IconButton(
                              onPressed: _advance,
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                color: Colors.white,
                              ),
                              tooltip: 'Next token',
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (rows.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(
                          top: 20,
                          bottom: 20,
                        ),
                        child: EmptyState(
                          icon: Icons.done_all_rounded,
                          title: 'Queue is clear',
                          message:
                              'There are no active checked-in patients right now.',
                        ),
                      ),
                    ...rows.asMap().entries.map(
                      (entry) {
                        final i = entry.key;
                        final r = entry.value;

                        final token = (r['token_no'] as num?)?.toInt() ?? 0;

                        final wait = i * 10;

                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: CareFlowUIColors.softBlue,
                              child: Text(
                                '$token',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: CareFlowUIColors.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              '${r['patient_name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              '${r['doctor_name']}\n'
                              'Estimated wait: $wait min',
                            ),
                            isThreeLine: true,
                            trailing: StatusChip(
                              '${r['status']}',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

extension on CareFlowFeatureService {
  SupabaseClient get _client => Supabase.instance.client;
}
