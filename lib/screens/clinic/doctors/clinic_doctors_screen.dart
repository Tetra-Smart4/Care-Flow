import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/clinic_service.dart';
import '../../../widgets/clinic/clinic_widgets.dart';
import 'add_doctor_screen.dart';
import 'doctor_details_screen.dart';

class ClinicDoctorsScreen extends StatefulWidget {
  const ClinicDoctorsScreen({super.key});

  @override
  State<ClinicDoctorsScreen> createState() =>
      _ClinicDoctorsScreenState();
}

class _ClinicDoctorsScreenState extends State<ClinicDoctorsScreen> {
  final ClinicService _service = ClinicService();
  final TextEditingController _search = TextEditingController();

  late final RealtimeChannel _channel;

  bool loading = true;
  String? error;
  String query = '';

  List<Map<String, dynamic>> doctors = [];

  @override
  void initState() {
    super.initState();

    _channel = _service.subscribe(
      _refreshRealtime,
      tag: 'doctors',
    );

    _load();

    _search.addListener(() {
      if (!mounted) return;

      setState(() {
        query = _search.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _channel.unsubscribe();
    _search.dispose();
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
      final data = await _service.getDoctors();

      if (!mounted) return;

      setState(() {
        doctors = data;
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

  List<Map<String, dynamic>> get filtered {
    if (query.isEmpty) {
      return doctors;
    }

    return doctors.where((doctor) {
      final profile = doctor['profiles'] is Map
          ? doctor['profiles'] as Map
          : <String, dynamic>{};

      final values = [
        profile['full_name'],
        doctor['doctor_id'],
        doctor['specialization'],
        doctor['qualification'],
      ].map(
        (value) => '${value ?? ''}'.toLowerCase(),
      ).join(' ');

      return values.contains(query);
    }).toList();
  }

  Future<void> _addDoctor() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddDoctorScreen(),
      ),
    );

    if (created == true && mounted) {
      await _load();
    }
  }

  Future<void> _openDoctor(
    Map<String, dynamic> doctor,
  ) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorDetailsScreen(
          doctor: doctor,
        ),
      ),
    );

    // Refresh ONLY when the details screen reports a change.
    if (changed == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const ClinicLoadingState();
    }

    return Column(
      children: [
        ClinicHeader(
          title: 'Doctors',
          subtitle: '${doctors.length} registered doctors',
          trailing: FilledButton.icon(
            onPressed: _addDoctor,
            icon: const Icon(
              Icons.add_rounded,
              size: 19,
            ),
            label: const Text('Add'),
          ),
        ),

        ClinicSearchField(
          controller: _search,
          hint: 'Search doctor, ID or specialization',
          onChanged: (_) {
            setState(() {});
          },
        ),

        const SizedBox(height: 10),

        Expanded(
          child: error != null
              ? ClinicEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Unable to load doctors',
                  message: error!,
                  onRetry: _load,
                )
              : filtered.isEmpty
                  ? ClinicEmptyState(
                      icon: Icons.medical_services_outlined,
                      title: query.isEmpty
                          ? 'No doctors yet'
                          : 'No matching doctors',
                      message: query.isEmpty
                          ? 'Doctors added by this clinic will appear here.'
                          : 'Try a different name, ID or specialization.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          28,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doctor = filtered[index];

                          return _DoctorCard(
                            doctor: doctor,
                            onTap: () => _openDoctor(doctor),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback onTap;

  const _DoctorCard({
    required this.doctor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final profile = doctor['profiles'] is Map
        ? doctor['profiles'] as Map
        : <String, dynamic>{};

    final name =
        '${profile['full_name'] ?? 'Doctor'}';

    final specialization =
        '${doctor['specialization'] ?? 'General medicine'}';

    final available =
        doctor['is_available'] == true;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ClinicColors.border,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    ClinicColors.primarySoft,
                child: const Icon(
                  Icons.person_rounded,
                  color: ClinicColors.primary,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: ClinicColors.text,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      specialization,
                      style: const TextStyle(
                        color: ClinicColors.muted,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'ID: ${doctor['doctor_id'] ?? '—'}',
                      style: const TextStyle(
                        color: ClinicColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              ClinicStatusPill(
                text: available
                    ? 'Active'
                    : 'Inactive',
              ),

              const SizedBox(width: 3),

              const Icon(
                Icons.chevron_right_rounded,
                color: ClinicColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}