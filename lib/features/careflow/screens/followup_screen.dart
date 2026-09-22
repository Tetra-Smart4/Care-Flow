import 'package:flutter/material.dart';

import '../models/feature_models.dart';
import '../services/feature_service.dart';
import '../widgets/feature_widgets.dart';
import '../../../ui/theme/careflow_ui_theme.dart';

class FollowUpScreen extends StatefulWidget {
  const FollowUpScreen({
    super.key,
    this.appointment,
  });

  final CareFlowAppointment? appointment;

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> {
  final service = CareFlowFeatureService.instance;
  final notes = TextEditingController();

  DateTime date = DateTime.now().add(const Duration(days: 7));

  bool loading = true;
  bool saving = false;

  List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await service.patientFollowups();

      if (!mounted) return;

      setState(() {
        rows = result;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load follow-ups: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final appointment = widget.appointment;
    if (appointment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Open follow-up from a consultation or appointment.',
          ),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await service.addFollowUp(
        appointmentId: appointment.id,
        patientId: appointment.patientId,
        date: date,
        notes: notes.text.trim(),
      );

      notes.clear();
      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Follow-up scheduled',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: date,
    );

    if (picked != null && mounted) {
      setState(() {
        date = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = <Widget>[];

    if (widget.appointment != null) {
      final appointment = widget.appointment!;

      content.add(
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.event_rounded,
              color: CareFlowUIColors.primary,
            ),
            title: Text(
              appointment.patientName ?? 'Patient',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              'Appointment ${appointment.date} • '
              '${appointment.time}',
            ),
          ),
        ),
      );

      content.add(const SizedBox(height: 12));

      content.add(
        Card(
          child: ListTile(
            title: const Text(
              'Follow-up date',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              '${date.day}/${date.month}/${date.year}',
            ),
            trailing: const Icon(
              Icons.calendar_month_rounded,
            ),
            onTap: _pickDate,
          ),
        ),
      );

      content.add(const SizedBox(height: 12));

      content.add(
        TextField(
          controller: notes,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Follow-up notes',
            hintText: 'What should the patient do before the next visit?',
          ),
        ),
      );

      content.add(const SizedBox(height: 16));

      content.add(
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: const Icon(
              Icons.event_repeat_rounded,
            ),
            label: Text(
              saving ? 'Saving...' : 'Schedule follow-up',
            ),
          ),
        ),
      );
    }

    content.add(const SizedBox(height: 22));
    content.add(
      const SectionTitle('Existing follow-ups'),
    );

    if (loading) {
      content.add(
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    } else if (rows.isEmpty) {
      content.add(
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No follow-ups yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CareFlowUIColors.muted,
            ),
          ),
        ),
      );
    } else {
      for (final row in rows) {
        content.add(
          Card(
            margin: const EdgeInsets.only(
              bottom: 8,
            ),
            child: ListTile(
              leading: const Icon(
                Icons.notifications_active_rounded,
                color: CareFlowUIColors.teal,
              ),
              title: Text(
                '${row['followup_date'] ?? '-'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                '${row['notes'] ?? ''}',
              ),
            ),
          ),
        );
      }
    }

    return FeatureScaffold(
      title: 'Follow-ups',
      subtitle: 'Post-consultation care plan',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: content,
      ),
    );
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }
}
