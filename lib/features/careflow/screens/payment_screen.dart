import 'package:flutter/material.dart';

import '../../../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.appointmentId,
    required this.paymentId,
    required this.amountPaise,
    required this.doctorName,
    required this.clinicName,
    required this.appointmentDate,
    required this.appointmentTime,
  });

  final String appointmentId;
  final String paymentId;
  final int amountPaise;
  final String doctorName;
  final String clinicName;
  final String appointmentDate;
  final String appointmentTime;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();

  bool _processing = false;
  String? _error;

  double get _amountInr => widget.amountPaise / 100.0;

  Future<void> _payDemo() async {
    if (_processing) return;

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      await _paymentService.captureDemoPayment(
        paymentId: widget.paymentId,
      );

      if (!mounted) return;

      setState(() {
        _processing = false;
      });

      await _showPaidPendingConfirmation();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _processing = false;
        _error = _cleanError(e);
      });
    }
  }

  Future<void> _showPaidPendingConfirmation() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                color: Color(0xFF1677E8),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Payment successful'),
              ),
            ],
          ),
          content: Text(
            'Demo payment of â‚¹${_amountInr.toStringAsFixed(2)} recorded.\n\n'
            '${widget.doctorName} now has to confirm your appointment.\n\n'
            'Confirmation window: 15 minutes.\n'
            'If the doctor rejects the appointment, CareFlow marks the payment as refunded.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  String _cleanError(Object error) {
    final text = error.toString();

    return text
        .replaceFirst('PostgrestException(message: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F9FC),
        elevation: 0,
        title: const Text(
          'Appointment payment',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF10245C),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFF0D28A),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.science_outlined,
                  color: Color(0xFF9A6700),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'DEMO PAYMENT MODE\n'
                    'No real money is charged. This is for CareFlow project testing only.',
                    style: TextStyle(
                      color: Color(0xFF6F4D00),
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10245C),
                  ),
                ),
                const SizedBox(height: 20),
                _row(
                  Icons.medical_services_rounded,
                  'Doctor',
                  widget.doctorName,
                ),
                const SizedBox(height: 14),
                _row(
                  Icons.local_hospital_rounded,
                  'Clinic',
                  widget.clinicName,
                ),
                const SizedBox(height: 14),
                _row(
                  Icons.calendar_month_rounded,
                  'Date',
                  widget.appointmentDate,
                ),
                const SizedBox(height: 14),
                _row(
                  Icons.schedule_rounded,
                  'Time',
                  _formatTime(widget.appointmentTime),
                ),
                const Divider(height: 30),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Consultation fee',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      'â‚¹${_amountInr.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10245C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF3B2B2),
                ),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFF9B1C1C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            height: 58,
            child: FilledButton.icon(
              onPressed: _processing ? null : _payDemo,
              icon: _processing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_rounded),
              label: Text(
                _processing
                    ? 'Processing...'
                    : 'Pay â‚¹${_amountInr.toStringAsFixed(2)} (Demo)',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'After payment, the doctor must confirm the appointment. '
            'Rejection is recorded as a demo refund.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String value) {
    final text = value.trim();

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$',
    ).firstMatch(text);

    if (match == null) {
      return text;
    }

    final hour24 = int.tryParse(match.group(1)!) ?? 0;
    final minute = int.tryParse(match.group(2)!) ?? 0;

    if (hour24 < 0 || hour24 > 23 || minute < 0 || minute > 59) {
      return text;
    }

    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;

    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  Widget _row(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1677E8),
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF10245C),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
