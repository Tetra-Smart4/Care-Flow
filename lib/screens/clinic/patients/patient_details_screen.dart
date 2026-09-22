import 'package:flutter/material.dart';
import '../../../services/clinic_service.dart';
import '../../../widgets/clinic/clinic_widgets.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final service = ClinicService();
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data =
          await service.getPatientAppointments('${widget.patient['id']}');
      if (!mounted) return;
      setState(() {
        appointments = data;
        loading = false;
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
    final profile = widget.patient['profiles'] is Map
        ? widget.patient['profiles'] as Map
        : <String, dynamic>{};
    final name = '${profile['full_name'] ?? 'Patient'}';

    return Scaffold(
      backgroundColor: ClinicColors.background,
      appBar: AppBar(
          title: const Text('Patient details'),
          backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ClinicColors.border)),
            child: Row(
              children: [
                CircleAvatar(
                    radius: 31,
                    backgroundColor: ClinicColors.primarySoft,
                    child: const Icon(Icons.person_rounded,
                        size: 34, color: ClinicColors.primary)),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: ClinicColors.text)),
                      const SizedBox(height: 5),
                      Text('${profile['phone'] ?? 'No phone'}',
                          style: const TextStyle(color: ClinicColors.muted))
                    ])),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _info('Age', '${profile['age'] ?? 'Not provided'}',
              Icons.cake_outlined),
          _info('Gender', '${profile['gender'] ?? 'Not provided'}',
              Icons.wc_outlined),
          const ClinicSectionTitle(title: 'Appointment history'),
          if (loading)
            const SizedBox(height: 220, child: ClinicLoadingState())
          else if (error != null)
            SizedBox(
                height: 260,
                child: ClinicEmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Unable to load history',
                    message: error!,
                    onRetry: _load))
          else if (appointments.isEmpty)
            const SizedBox(
                height: 220,
                child: ClinicEmptyState(
                    icon: Icons.event_note_outlined,
                    title: 'No appointment history',
                    message:
                        'Completed and upcoming appointments will appear here.'))
          else
            ...appointments.map(_appointmentCard),
        ],
      ),
    );
  }

  Widget _info(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ClinicColors.border)),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: ClinicColors.primarySoft,
                borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: ClinicColors.primary)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 12, color: ClinicColors.muted)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: ClinicColors.text))
        ]))
      ]),
    );
  }

  Widget _appointmentCard(Map<String, dynamic> item) {
    final doctor =
        item['doctors'] is Map ? item['doctors'] as Map : <String, dynamic>{};
    final profile = doctor['profiles'] is Map
        ? doctor['profiles'] as Map
        : <String, dynamic>{};
    final slot = item['doctor_slots'] is Map
        ? item['doctor_slots'] as Map
        : <String, dynamic>{};

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ClinicColors.border)),
      child: Row(children: [
        Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: ClinicColors.primarySoft,
                borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.calendar_month_outlined,
                color: ClinicColors.primary)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dr. ${profile['full_name'] ?? 'Doctor'}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
              '${slot['slot_date'] ?? 'Date'} • ${slot['start_time'] ?? 'Time'}',
              style: const TextStyle(color: ClinicColors.muted, fontSize: 12))
        ])),
        ClinicStatusPill(text: '${item['status'] ?? 'pending'}')
      ]),
    );
  }
}
