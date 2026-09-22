import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/clinic_service.dart';
import '../../../widgets/clinic/clinic_widgets.dart';

class ClinicHomeScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const ClinicHomeScreen({super.key, required this.onNavigate});

  @override
  State<ClinicHomeScreen> createState() => _ClinicHomeScreenState();
}

class _ClinicHomeScreenState extends State<ClinicHomeScreen> {
  final _service = ClinicService();
  late final RealtimeChannel _channel;

  bool loading = true;
  String? error;
  String clinicName = 'Clinic';
  Map<String, int> counts = {'doctors': 0, 'patients': 0, 'appointments': 0};
  List<Map<String, dynamic>> appointments = [];

  @override
  void dispose() {
    _channel.unsubscribe();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _channel = _service.subscribe(_refreshRealtime, tag: 'home');
    _load();
  }

  void _refreshRealtime() {
    if (mounted) _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final profile = await _service.getClinicProfile();
      final data = await _service.getDashboardCounts();
      final today = await _service.getAppointments(todayOnly: true);

      if (!mounted) return;
      setState(() {
        clinicName = '${profile['clinic_name'] ?? 'Clinic'}';
        counts = data;
        appointments = today;
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
        title: 'Could not load clinic data',
        message: error!,
        onRetry: _load,
      );
    }

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: ClinicHeader(
              title: greeting,
              subtitle: clinicName,
              trailing: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ClinicColors.primarySoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.notifications_none_rounded,
                    color: ClinicColors.primary),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF4F8DF7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.local_hospital_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CareFlow Clinic',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage doctors, patients and appointments in real time.',
                            style:
                                TextStyle(color: Colors.white70, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
              child: ClinicSectionTitle(title: 'Today at a glance')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                ClinicStatCard(
                  label: 'Doctors',
                  value: '${counts['doctors'] ?? 0}',
                  icon: Icons.medical_services_rounded,
                  onTap: () => widget.onNavigate(1),
                ),
                ClinicStatCard(
                  label: 'Patients',
                  value: '${counts['patients'] ?? 0}',
                  icon: Icons.groups_rounded,
                  tint: const Color(0xFFEAF7F0),
                  onTap: () => widget.onNavigate(2),
                ),
                ClinicStatCard(
                  label: "Today's appointments",
                  value: '${counts['appointments'] ?? 0}',
                  icon: Icons.calendar_month_rounded,
                  tint: const Color(0xFFFFF1E8),
                ),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.08,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ClinicSectionTitle(
              title: "Today's appointments",
              actionLabel: appointments.isEmpty ? null : 'View all',
              onAction: () => widget.onNavigate(3),
            ),
          ),
          if (appointments.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 230,
                  child: ClinicEmptyState(
                    icon: Icons.event_available_rounded,
                    title: 'No appointments today',
                    message: 'New appointments will appear here automatically.',
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverList.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final item = appointments[index];
                  return _AppointmentCard(item: item);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _AppointmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final patient =
        item['patients'] is Map ? item['patients'] as Map : <String, dynamic>{};
    final doctor =
        item['doctors'] is Map ? item['doctors'] as Map : <String, dynamic>{};
    final patientProfile = patient['profiles'] is Map
        ? patient['profiles'] as Map
        : <String, dynamic>{};
    final doctorProfile = doctor['profiles'] is Map
        ? doctor['profiles'] as Map
        : <String, dynamic>{};
    final slot = item['doctor_slots'] is Map
        ? item['doctor_slots'] as Map
        : <String, dynamic>{};

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: ClinicColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ClinicColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: ClinicColors.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${patientProfile['full_name'] ?? 'Patient'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: ClinicColors.text),
                ),
                const SizedBox(height: 3),
                Text(
                  'Dr. ${doctorProfile['full_name'] ?? 'Doctor'}',
                  style:
                      const TextStyle(color: ClinicColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 7),
                Text(
                  '${slot['start_time'] ?? 'Time'}',
                  style: const TextStyle(
                      color: ClinicColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          ClinicStatusPill(text: '${item['status'] ?? 'pending'}'),
        ],
      ),
    );
  }
}
