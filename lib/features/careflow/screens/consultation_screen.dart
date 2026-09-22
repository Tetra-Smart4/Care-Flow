import 'package:flutter/material.dart';

import '../models/feature_models.dart';
import '../services/feature_service.dart';
import '../widgets/feature_widgets.dart';
import 'followup_screen.dart';
import '../../../ui/theme/careflow_ui_theme.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final service = CareFlowFeatureService.instance;

  final symptoms = TextEditingController();
  final diagnosis = TextEditingController();
  final notes = TextEditingController();

  final medicine = TextEditingController();

  final dosage = TextEditingController(
    text: 'As prescribed',
  );

  final frequency = TextEditingController(
    text: 'Once daily',
  );

  final duration = TextEditingController(
    text: '5',
  );

  List<CareFlowAppointment> appointments = <CareFlowAppointment>[];
  CareFlowAppointment? selected;

  List<Map<String, dynamic>> meds = <Map<String, dynamic>>[];

  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ------------------------------------------------------------
  // LOAD ACTIVE PATIENTS
  // ------------------------------------------------------------

  Future<void> _load() async {
    try {
      final result = await service.doctorAppointments();

      final active = result
          .where(
            (appointment) => <String>[
              'confirmed',
              'checked_in',
              'in_queue',
              'consulting',
            ].contains(appointment.status),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        appointments = active;
        selected = active.isEmpty ? null : active.first;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = '$e';
      });
    }
  }

  // ------------------------------------------------------------
  // SAVE CONSULTATION
  // ------------------------------------------------------------

  Future<void> _save() async {
    final appointment = selected;

    if (appointment == null) {
      return;
    }

    if (saving) {
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      // 1. Save consultation + prescription
      await service.saveConsultation(
        appointmentId: appointment.id,
        symptoms: symptoms.text.trim(),
        diagnosis: diagnosis.text.trim(),
        notes: notes.text.trim(),
        medicines: meds,
      );

      // 2. Complete the appointment
      await service.setAppointmentStatus(
        appointment.id,
        'completed',
      );

      if (!mounted) return;

      // 3. Clear the completed patient's form
      symptoms.clear();
      diagnosis.clear();
      notes.clear();

      setState(() {
        meds = <Map<String, dynamic>>[];
        saving = false;
      });

      // 4. Show success confirmation
      await _showSuccessDialog(
        patientName: appointment.patientName ?? 'Patient',
      );

      if (!mounted) return;

      // 5. Reload queue / active patients.
      // The completed patient will disappear automatically.
      await _load();

      if (!mounted) return;

      // 6. Tell doctor who is next.
      if (selected != null) {
        await _showNextPatientMessage(
          selected!.patientName ?? 'Patient',
        );
      } else {
        await _showQueueClearMessage();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Could not save consultation: $e',
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // SUCCESS DIALOG
  // ------------------------------------------------------------

  Future<void> _showSuccessDialog({
    required String patientName,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            28,
            24,
            20,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 46,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Consultation sent successfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$patientName\'s consultation and prescription '
                'have been saved successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: CareFlowUIColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // NEXT PATIENT MESSAGE
  // ------------------------------------------------------------

  Future<void> _showNextPatientMessage(
    String patientName,
  ) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: <Widget>[
              Icon(
                Icons.people_alt_rounded,
                color: CareFlowUIColors.primary,
              ),
              SizedBox(width: 10),
              Text('Next patient'),
            ],
          ),
          content: Text(
            '$patientName is ready for consultation.',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Start consultation'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // QUEUE CLEAR MESSAGE
  // ------------------------------------------------------------

  Future<void> _showQueueClearMessage() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: <Widget>[
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
              ),
              SizedBox(width: 10),
              Text('Queue clear'),
            ],
          ),
          content: const Text(
            'Consultation sent successfully.\n\n'
            'There are no more patients waiting.',
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // ADD MEDICINE
  // ------------------------------------------------------------

  void _addMed() {
    final name = medicine.text.trim();

    if (name.isEmpty) {
      return;
    }

    setState(() {
      meds.add(
        <String, dynamic>{
          'medicine_name': name,
          'dosage': dosage.text.trim(),
          'frequency': frequency.text.trim(),
          'duration_days': int.tryParse(duration.text.trim()) ?? 1,
          'instructions': 'Use as directed',
        },
      );
    });

    medicine.clear();
  }

  // ------------------------------------------------------------
  // MEDICINE SHEET
  // ------------------------------------------------------------

  Future<void> _openMedicineSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _medicineSheet(),
    );
  }

  Widget _medicineSheet() {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 8),
          const Text(
            'Add medicine',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: medicine,
            decoration: const InputDecoration(
              labelText: 'Medicine name',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: dosage,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: frequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: duration,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duration (days)',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () {
                _addMed();
                Navigator.pop(context);
              },
              child: const Text(
                'Add to prescription',
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (loading) {
      body = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (error != null) {
      body = EmptyState(
        icon: Icons.medical_services_outlined,
        title: 'Could not load appointments',
        message: error!,
        action: FilledButton(
          onPressed: _load,
          child: const Text('Retry'),
        ),
      );
    } else if (appointments.isEmpty) {
      body = const EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No appointments ready',
        message: 'Confirmed or checked-in appointments will appear here.',
      );
    } else {
      final prescriptionWidgets = meds.map<Widget>((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              '${item['medicine_name']}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              '${item['dosage']} • '
              '${item['frequency']} • '
              '${item['duration_days']} days',
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.close_rounded,
              ),
              onPressed: () {
                setState(() {
                  meds.remove(item);
                });
              },
            ),
          ),
        );
      }).toList();

      body = ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          30,
        ),
        children: <Widget>[
          const SectionTitle(
            'Patient / appointment',
          ),

          DropdownButtonFormField<CareFlowAppointment>(
            initialValue: selected,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Appointment',
            ),
            items: appointments.map((appointment) {
              return DropdownMenuItem<CareFlowAppointment>(
                value: appointment,
                child: Text(
                  '${appointment.patientName ?? 'Patient'} • '
                  '${appointment.date} • '
                  'Token ${appointment.tokenNo ?? '-'}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: saving
                ? null
                : (value) {
                    setState(() {
                      selected = value;

                      // Start fresh when switching patients.
                      symptoms.clear();
                      diagnosis.clear();
                      notes.clear();
                      meds = <Map<String, dynamic>>[];
                    });
                  },
          ),

          const SizedBox(height: 14),

          TextField(
            controller: symptoms,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Symptoms',
              prefixIcon: Icon(
                Icons.sick_outlined,
              ),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: diagnosis,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Diagnosis',
              prefixIcon: Icon(
                Icons.health_and_safety_outlined,
              ),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: notes,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Clinical notes',
              prefixIcon: Icon(
                Icons.notes_rounded,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: <Widget>[
              const Expanded(
                child: SectionTitle(
                  'Prescription',
                ),
              ),
              IconButton(
                onPressed: saving ? null : _openMedicineSheet,
                icon: const Icon(
                  Icons.add_circle_rounded,
                  color: CareFlowUIColors.primary,
                ),
              ),
            ],
          ),

          if (prescriptionWidgets.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No medicines added yet.',
                  style: TextStyle(
                    color: CareFlowUIColors.muted,
                  ),
                ),
              ),
            )
          else
            ...prescriptionWidgets,

          const SizedBox(height: 14),

          // --------------------------------------------------
          // SAVE
          // --------------------------------------------------

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.check_circle_outline_rounded,
                    ),
              label: Text(
                saving ? 'Sending consultation...' : 'Send consultation',
              ),
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------
          // FOLLOW-UP
          // --------------------------------------------------

          OutlinedButton.icon(
            onPressed: saving || selected == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FollowUpScreen(
                          appointment: selected,
                        ),
                      ),
                    );
                  },
            icon: const Icon(
              Icons.event_repeat_rounded,
            ),
            label: const Text(
              'Schedule follow-up',
            ),
          ),
        ],
      );
    }

    return FeatureScaffold(
      title: 'Consultation',
      subtitle: 'Doctor workspace',
      child: body,
    );
  }

  @override
  void dispose() {
    symptoms.dispose();
    diagnosis.dispose();
    notes.dispose();
    medicine.dispose();
    dosage.dispose();
    frequency.dispose();
    duration.dispose();
    super.dispose();
  }
}
