import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/clinic_service.dart';
import '../../../widgets/clinic/clinic_widgets.dart';
import 'patient_details_screen.dart';

class ClinicPatientsScreen extends StatefulWidget {
  const ClinicPatientsScreen({super.key});

  @override
  State<ClinicPatientsScreen> createState() => _ClinicPatientsScreenState();
}

class _ClinicPatientsScreenState extends State<ClinicPatientsScreen> {
  final service = ClinicService();
  final search = TextEditingController();
  late final RealtimeChannel channel;
  bool loading = true;
  String? error;
  String query = '';
  List<Map<String, dynamic>> patients = [];

  @override
  void initState() {
    super.initState();
    channel = service.subscribe(_refreshRealtime, tag: 'patients');
    search.addListener(() {
      if (mounted) setState(() => query = search.text.trim().toLowerCase());
    });
    _load();
  }

  @override
  void dispose() {
    channel.unsubscribe();
    search.dispose();
    super.dispose();
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
      final data = await service.getPatients();
      if (!mounted) return;
      setState(() {
        patients = data;
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
    if (query.isEmpty) return patients;
    return patients.where((patient) {
      final profile = patient['profiles'] is Map
          ? patient['profiles'] as Map
          : <String, dynamic>{};
      final haystack = [
        profile['full_name'],
        profile['phone'],
        profile['gender'],
        patient['id']
      ].map((value) => '${value ?? ''}'.toLowerCase()).join(' ');
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const ClinicLoadingState();

    return Column(
      children: [
        const ClinicHeader(
          title: 'Patients',
          subtitle: 'Search patient records and appointment history',
        ),
        ClinicSearchField(
          controller: search,
          hint: 'Search by name or phone',
        ),
        const SizedBox(height: 10),
        Expanded(
          child: error != null
              ? ClinicEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Unable to load patients',
                  message: error!,
                  onRetry: _load,
                )
              : filtered.isEmpty
                  ? ClinicEmptyState(
                      icon: Icons.groups_outlined,
                      title: query.isEmpty
                          ? 'No patients yet'
                          : 'No matching patients',
                      message: query.isEmpty
                          ? 'Patients connected to this clinic will appear here.'
                          : 'Try a different search term.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final patient = filtered[index];
                          return _PatientCard(
                            patient: patient,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PatientDetailsScreen(patient: patient),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;

  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final profile = patient['profiles'] is Map
        ? patient['profiles'] as Map
        : <String, dynamic>{};
    final name = '${profile['full_name'] ?? 'Patient'}';
    final phone = '${profile['phone'] ?? 'No phone'}';
    final age = profile['age'];

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
            border: Border.all(color: ClinicColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFEAF7F0),
                child: const Icon(Icons.person_rounded,
                    color: ClinicColors.success),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: ClinicColors.text)),
                    const SizedBox(height: 4),
                    Text(phone,
                        style: const TextStyle(
                            color: ClinicColors.muted, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(age == null ? 'Age not provided' : 'Age $age',
                        style: const TextStyle(
                            color: ClinicColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: ClinicColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
