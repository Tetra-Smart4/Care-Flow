import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/clinic_service.dart';
import '../../../widgets/clinic/clinic_widgets.dart';

class ClinicAnalyticsScreen extends StatefulWidget {
  const ClinicAnalyticsScreen({super.key});

  @override
  State<ClinicAnalyticsScreen> createState() => _ClinicAnalyticsScreenState();
}

class _ClinicAnalyticsScreenState extends State<ClinicAnalyticsScreen> {
  final service = ClinicService();
  late final RealtimeChannel channel;
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> appointments = [];
  List<Map<String, dynamic>> doctors = [];
  List<Map<String, dynamic>> patients = [];

  @override
  void initState() {
    super.initState();
    channel = service.subscribe(_refreshRealtime, tag: 'analytics');
    _load();
  }

  @override
  void dispose() {
    channel.unsubscribe();
    super.dispose();
  }

  void _refreshRealtime() {
    if (mounted) {
      _load(silent: true);
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final results = await Future.wait([
        service.getAppointments(),
        service.getDoctors(),
        service.getPatients(),
      ]);
      if (!mounted) return;
      setState(() {
        appointments = List<Map<String, dynamic>>.from(results[0]);
        doctors = List<Map<String, dynamic>>.from(results[1]);
        patients = List<Map<String, dynamic>>.from(results[2]);
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const ClinicLoadingState();
    if (error != null) {
      return ClinicEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Unable to load analytics',
          message: error!,
          onRetry: _load);
    }

    final completed = appointments
        .where((a) => '${a['status']}'.toLowerCase() == 'completed')
        .length;
    final confirmed = appointments
        .where((a) => '${a['status']}'.toLowerCase() == 'confirmed')
        .length;
    final pending = appointments
        .where((a) => '${a['status']}'.toLowerCase() == 'pending')
        .length;
    final cancelled = appointments
        .where((a) => '${a['status']}'.toLowerCase() == 'cancelled')
        .length;
    final activeDoctors =
        doctors.where((d) => d['is_available'] == true).length;

    final total = appointments.length;
    final completionRate = total == 0 ? 0.0 : completed / total;

    final doctorWorkload = <String, int>{};
    for (final item in appointments) {
      final doctor =
          item['doctors'] is Map ? item['doctors'] as Map : <String, dynamic>{};
      final profile = doctor['profiles'] is Map
          ? doctor['profiles'] as Map
          : <String, dynamic>{};
      final name = '${profile['full_name'] ?? 'Doctor'}';
      doctorWorkload[name] = (doctorWorkload[name] ?? 0) + 1;
    }
    final sortedWorkload = doctorWorkload.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
              child: ClinicHeader(
                  title: 'Analytics',
                  subtitle: 'Live clinic performance from Supabase')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                ClinicStatCard(
                    label: 'Total doctors',
                    value: '${doctors.length}',
                    icon: Icons.medical_services_rounded),
                ClinicStatCard(
                    label: 'Active doctors',
                    value: '$activeDoctors',
                    icon: Icons.verified_user_rounded,
                    tint: const Color(0xFFEAF7F0)),
                ClinicStatCard(
                    label: 'Clinic patients',
                    value: '${patients.length}',
                    icon: Icons.groups_rounded,
                    tint: const Color(0xFFFFF1E8)),
                ClinicStatCard(
                    label: 'Appointments',
                    value: '$total',
                    icon: Icons.calendar_month_rounded,
                    tint: const Color(0xFFF1ECFF)),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.08),
            ),
          ),
          const SliverToBoxAdapter(
              child: ClinicSectionTitle(title: 'Appointment status')),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.fromLTRB(17, 17, 17, 12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: ClinicColors.border)),
              child: Column(
                children: [
                  _bar('Completed', completed, total, ClinicColors.success),
                  _bar('Confirmed', confirmed, total, ClinicColors.primary),
                  _bar('Pending', pending, total, ClinicColors.warning),
                  _bar('Cancelled', cancelled, total, ClinicColors.danger),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
              child: ClinicSectionTitle(title: 'Completion rate')),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: ClinicColors.border)),
              child: Row(
                children: [
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                            value: completionRate,
                            strokeWidth: 9,
                            backgroundColor: ClinicColors.primarySoft),
                        Text('${(completionRate * 100).round()}%',
                            style: const TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  const Expanded(
                      child: Text(
                          'Completed appointments compared with all recorded clinic appointments.',
                          style: TextStyle(
                              color: ClinicColors.muted, height: 1.4))),
                ],
              ),
            ),
          ),
          if (sortedWorkload.isNotEmpty) ...[
            const SliverToBoxAdapter(
                child: ClinicSectionTitle(title: 'Doctor workload')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              sliver: SliverList.builder(
                itemCount: sortedWorkload.length,
                itemBuilder: (context, index) {
                  final item = sortedWorkload[index];
                  final max = sortedWorkload.first.value;
                  final ratio = max == 0 ? 0.0 : item.value / max;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: ClinicColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(item.key,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800))),
                          Text('${item.value}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: ClinicColors.primary))
                        ]),
                        const SizedBox(height: 9),
                        LinearProgressIndicator(
                            value: ratio,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(99),
                            backgroundColor: ClinicColors.primarySoft),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bar(String label, int value, int total, Color color) {
    final ratio = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700))),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800))
        ]),
        const SizedBox(height: 7),
        LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: color.withValues(alpha: 0.10),
            color: color),
      ]),
    );
  }
}
