import 'package:flutter/material.dart';

import '../../../services/payment_service.dart';

class DemoDoctorPaymentRequestsScreen extends StatefulWidget {
  const DemoDoctorPaymentRequestsScreen({super.key});

  @override
  State<DemoDoctorPaymentRequestsScreen> createState() =>
      _DemoDoctorPaymentRequestsScreenState();
}

class _DemoDoctorPaymentRequestsScreenState
    extends State<DemoDoctorPaymentRequestsScreen> {
  final PaymentService _paymentService = PaymentService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _paymentService.doctorPaidRequests();

      if (!mounted) return;

      setState(() {
        _requests = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e
            .toString()
            .replaceFirst('PostgrestException(message: ', '')
            .replaceFirst('Exception: ', '')
            .trim();
      });
    }
  }

  Future<void> _act(
    Map<String, dynamic> row,
    String action,
  ) async {
    final paymentId = row['payment_id']?.toString();

    if (paymentId == null || paymentId.isEmpty) {
      _showMessage('Payment ID is missing.');
      return;
    }

    final label = action == 'confirm' ? 'confirm' : 'reject';
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                action == 'confirm'
                    ? 'Confirm appointment?'
                    : 'Reject appointment?',
              ),
              content: Text(
                action == 'confirm'
                    ? 'This demo will simulate transferring the consultation fee to the doctor.'
                    : 'This demo will simulate a refund to the patient and cancel the appointment.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(label[0].toUpperCase() + label.substring(1)),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!ok || !mounted) return;

    try {
      await _paymentService.doctorDemoAction(
        paymentId: paymentId,
        action: action,
      );

      if (!mounted) return;

      _showMessage(
        action == 'confirm'
            ? 'Appointment confirmed. Demo payout recorded.'
            : 'Appointment rejected. Demo refund recorded.',
      );

      await _loadRequests();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e
            .toString()
            .replaceFirst('PostgrestException(message: ', '')
            .replaceFirst('Exception: ', '')
            .trim(),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _money(dynamic amountPaise) {
    final value = double.tryParse(amountPaise?.toString() ?? '') ?? 0;
    return '₹${(value / 100).toStringAsFixed(2)}';
  }

  String _prettyStatus(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return 'Unknown';
    return text.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F9FC),
        elevation: 0,
        title: const Text(
          'Paid appointment requests',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF10245C),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _loadRequests,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 54,
                color: Color(0xFF64748B),
              ),
              SizedBox(height: 12),
              Text(
                'No paid appointment requests',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF10245C),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'When a patient completes a demo payment, the request will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final row = _requests[index];
          final patient = row['patient_name']?.toString() ?? 'Patient';
          final clinic = row['clinic_name']?.toString() ?? 'Clinic';
          final date = row['appointment_date']?.toString() ?? '';
          final time = row['appointment_time']?.toString() ?? '';
          final reason = row['reason']?.toString() ?? '';
          final amount = _money(row['amount_paise']);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFEAF8F1),
                      child: Icon(
                        Icons.person_rounded,
                        color: Color(0xFF35B96F),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        patient,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10245C),
                        ),
                      ),
                    ),
                    Text(
                      amount,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1677E8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '$clinic • $date • $time',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Reason: $reason',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'Status: ${_prettyStatus(row['status'])}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _act(row, 'reject'),
                        child: const Text('Reject + Refund'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _act(row, 'confirm'),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
