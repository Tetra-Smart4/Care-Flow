import 'package:flutter/material.dart';

import '../models/feature_models.dart';
import '../services/feature_service.dart';
import '../widgets/feature_widgets.dart';
import '../../../ui/theme/careflow_ui_theme.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({
    super.key,
    this.patientMode = false,
  });

  final bool patientMode;

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final service = CareFlowFeatureService.instance;

  final consultation = TextEditingController(text: '500');
  final medicine = TextEditingController(text: '0');
  final tests = TextEditingController(text: '0');
  final other = TextEditingController(text: '0');

  List<CareFlowAppointment> appointments = <CareFlowAppointment>[];
  List<Map<String, dynamic>> bills = <Map<String, dynamic>>[];

  bool loading = true;
  bool saving = false;

  CareFlowAppointment? selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
    });

    try {
      if (widget.patientMode) {
        bills = await service.patientBills();
      } else {
        appointments = await service.clinicAppointments();
        if (appointments.isNotEmpty) {
          selected = appointments.first;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load billing data: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final appointment = selected;
    if (appointment == null) {
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await service.createBill(
        appointmentId: appointment.id,
        consultationFee: _amount(consultation),
        medicineTotal: _amount(medicine),
        testTotal: _amount(tests),
        otherCharges: _amount(other),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill created successfully'),
        ),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create bill: $e'),
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

  double _amount(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const FeatureScaffold(
        title: 'Billing',
        subtitle: 'Clinic billing',
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return FeatureScaffold(
      title: widget.patientMode ? 'My bills' : 'Billing',
      subtitle: widget.patientMode
          ? 'Receipts from completed visits'
          : 'Clinic billing desk',
      child: widget.patientMode ? _patientView() : _clinicView(),
    );
  }

  Widget _patientView() {
    if (bills.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'No bills yet',
        message:
            'Your digital receipts will appear here after your clinic visits.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: bills.map((bill) {
        final paid = bill['paid'] == true;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(
              Icons.receipt_long_rounded,
              color: CareFlowUIColors.primary,
            ),
            title: Text(
              'Receipt ${bill['receipt_no'] ?? '-'}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              'Total ₹${bill['total'] ?? '0'}\n'
              '${bill['created_at'] ?? ''}',
            ),
            isThreeLine: true,
            trailing: StatusChip(
              paid ? 'Paid' : 'Pending',
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _clinicView() {
    if (appointments.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No appointments available',
        message: 'Appointments eligible for billing will appear here.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: <Widget>[
        const SectionTitle('Create a bill'),
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
                '${appointment.date}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selected = value;
            });
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: _money(
                'Consultation',
                consultation,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _money(
                'Medicine',
                medicine,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: _money(
                'Tests',
                tests,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _money(
                'Other',
                other,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CareFlowUIColors.softBlue,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Grand total',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '₹${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: CareFlowUIColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: selected == null || saving ? null : _save,
            icon: const Icon(
              Icons.receipt_long_rounded,
            ),
            label: Text(
              saving ? 'Creating...' : 'Create digital receipt',
            ),
          ),
        ),
      ],
    );
  }

  Widget _money(
    String label,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      onChanged: (_) {
        setState(() {});
      },
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₹ ',
      ),
    );
  }

  double get _total =>
      _amount(consultation) +
      _amount(medicine) +
      _amount(tests) +
      _amount(other);

  @override
  void dispose() {
    consultation.dispose();
    medicine.dispose();
    tests.dispose();
    other.dispose();
    super.dispose();
  }
}
