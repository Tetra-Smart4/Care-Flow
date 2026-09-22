import 'package:flutter/material.dart';

import '../../../models/appointment_model.dart';
import '../../../services/clinic_service.dart';
import '../../../widgets/clinic/clinic_appointment_card.dart';

class ClinicAppointmentsScreen extends StatefulWidget {
  const ClinicAppointmentsScreen({super.key});

  @override
  State<ClinicAppointmentsScreen> createState() =>
      _ClinicAppointmentsScreenState();
}

class _ClinicAppointmentsScreenState extends State<ClinicAppointmentsScreen> {
  final ClinicService service = ClinicService();

  bool loading = true;
  String? error;

  List<AppointmentModel> appointments = [];

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
      final rows = await service.getAppointments();

      if (!mounted) return;

      setState(() {
        appointments =
            rows.map(AppointmentModel.fromMap).toList(growable: false);
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

  String _dateText(DateTime? date) {
    if (date == null) {
      return 'Date not available';
    }

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (appointments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(
              child: Text('No appointments yet'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          30,
        ),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final item = appointments[index];

          return ClinicAppointmentCard(
            patientName: item.patientId ?? 'Patient',
            doctorName: item.doctorId ?? 'Doctor',
            status: item.displayStatus,
            dateText: _dateText(item.scheduledAt),
          );
        },
      ),
    );
  }
}
