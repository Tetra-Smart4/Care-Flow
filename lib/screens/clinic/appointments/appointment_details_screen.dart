import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/appointment_model.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final SupabaseClient _db = Supabase.instance.client;

  bool saving = false;

  Future<void> _updateStatus(String status) async {
    setState(() {
      saving = true;
    });

    try {
      await _db.rpc(
        'careflow_set_appointment_status',
        params: {
          'p_appointment_id': widget.appointment.id,
          'p_status': status,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Appointment marked as $status.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update appointment: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _InfoTile(
            label: 'Appointment ID',
            value: appointment.id,
          ),
          _InfoTile(
            label: 'Patient ID',
            value: appointment.patientId ?? 'Not available',
          ),
          _InfoTile(
            label: 'Doctor ID',
            value: appointment.doctorId ?? 'Not available',
          ),
          _InfoTile(
            label: 'Status',
            value: appointment.displayStatus,
          ),
          _InfoTile(
            label: 'Reason',
            value: appointment.reason ?? 'Not provided',
          ),
          const SizedBox(height: 18),
          const Text(
            'Update status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in const [
                'pending',
                'confirmed',
                'completed',
                'cancelled',
              ])
                FilledButton.tonal(
                  onPressed: saving ? null : () => _updateStatus(status),
                  child: Text(status),
                ),
            ],
          ),
          if (saving) ...[
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
