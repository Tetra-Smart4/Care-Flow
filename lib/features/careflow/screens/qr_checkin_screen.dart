import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/feature_models.dart';
import '../services/feature_service.dart';
import '../widgets/feature_widgets.dart';
import '../../../ui/theme/careflow_ui_theme.dart';

class QrCheckinScreen extends StatefulWidget {
  const QrCheckinScreen({super.key});

  @override
  State<QrCheckinScreen> createState() => _QrCheckinScreenState();
}

class _QrCheckinScreenState extends State<QrCheckinScreen> {
  final service = CareFlowFeatureService.instance;

  List<CareFlowAppointment> appointments = <CareFlowAppointment>[];

  bool loading = true;
  String? error;

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
      final result = await service.patientAppointments();

      if (!mounted) return;

      setState(() {
        appointments = result
            .where(
              (appointment) =>
                  appointment.qrToken != null &&
                  appointment.qrToken!.isNotEmpty &&
                  appointment.status != 'cancelled',
            )
            .toList();

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = '$e';
      });
    }
  }

  Future<void> _showQr(
    CareFlowAppointment appointment,
  ) async {
    final token = appointment.qrToken;

    if (token == null || token.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            36,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Clinic check-in QR',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${appointment.doctorName ?? 'Doctor'} • '
                '${appointment.date} • '
                '${appointment.time}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CareFlowUIColors.muted,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: QrImageView(
                  data: 'CARE-FLOW|$token',
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Use this code only for your appointment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: CareFlowUIColors.muted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (loading) {
      body = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (error != null) {
      body = EmptyState(
        icon: Icons.qr_code_rounded,
        title: 'QR unavailable',
        message: error!,
        action: FilledButton(
          onPressed: _load,
          child: const Text('Retry'),
        ),
      );
    } else if (appointments.isEmpty) {
      body = const EmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'No active appointments',
        message:
            'Book an appointment first. Your check-in QR will appear here.',
      );
    } else {
      final cards = appointments.map<Widget>((appointment) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: CareFlowUIColors.softBlue,
              child: const Icon(
                Icons.qr_code_rounded,
                color: CareFlowUIColors.primary,
              ),
            ),
            title: Text(
              appointment.doctorName ?? 'Doctor',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              '${appointment.date} • '
              '${appointment.time}\n'
              '${appointment.status}',
            ),
            isThreeLine: true,
            trailing: const Icon(
              Icons.chevron_right_rounded,
            ),
            onTap: () => _showQr(appointment),
          ),
        );
      }).toList();

      body = ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          28,
        ),
        children: <Widget>[
          const SectionTitle(
            'Select an appointment',
          ),
          ...cards,
        ],
      );
    }

    return FeatureScaffold(
      title: 'My check-in QR',
      subtitle: 'Show this at reception',
      child: body,
    );
  }
}

// ============================================================
// CLINIC / RECEPTION QR SCANNER
// ============================================================

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();

  bool handled = false;
  bool processing = false;

  Future<void> _onCapture(
    BarcodeCapture capture,
  ) async {
    if (handled || processing) {
      return;
    }

    if (capture.barcodes.isEmpty) {
      return;
    }

    String? raw;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();

      if (value != null && value.isNotEmpty) {
        raw = value;
        break;
      }
    }

    if (raw == null) {
      return;
    }

    if (raw.isEmpty) {
      return;
    }

    final scannedValue = raw.trim();

    debugPrint(
      'CareFlow QR detected: $scannedValue',
    );

    String token;

    // Normal CareFlow QR format:
    //
    // CARE-FLOW|<appointment-qr-token>
    //
    if (scannedValue.toUpperCase().startsWith('CARE-FLOW|')) {
      token = scannedValue.substring('CARE-FLOW|'.length).trim();
    }

    // Also accept CARE_FLOW|...
    else if (scannedValue.toUpperCase().startsWith('CARE_FLOW|')) {
      token = scannedValue.substring('CARE_FLOW|'.length).trim();
    }

    // Also accept a plain UUID/token.
    else {
      token = scannedValue;
    }

    if (token.isEmpty) {
      return;
    }

    debugPrint(
      'CareFlow appointment token: $token',
    );

    setState(() {
      handled = true;
      processing = true;
    });

    try {
      // Stop scanning while the check-in request is running.
      await controller.stop();

      final result = await CareFlowFeatureService.instance.checkInByQr(
        token,
      );

      if (!mounted) {
        return;
      }

      final tokenNo = result['token_no']?.toString() ?? '-';

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Check-in successful',
                  ),
                ),
              ],
            ),
            content: Text(
              'Patient check-in completed successfully.\n\n'
              'Token #$tokenNo has been issued.\n\n'
              'The patient has been added to the live queue.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      // Return to clinic queue/dashboard.
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint(
        'CareFlow QR check-in error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        handled = false;
        processing = false;
      });

      // Allow another scan after an error.
      try {
        await controller.start();
      } catch (_) {}

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Could not check in: $e',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Scan patient QR',
      subtitle: 'Reception / clinician check-in',
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera
          MobileScanner(
            controller: controller,
            onDetect: _onCapture,
          ),

          // Scanner frame
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),

          // Flash button
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Material(
                color: Colors.black.withValues(
                  alpha: 0.55,
                ),
                borderRadius: BorderRadius.circular(14),
                child: IconButton(
                  tooltip: 'Toggle flash',
                  color: Colors.white,
                  icon: const Icon(
                    Icons.flash_on_rounded,
                  ),
                  onPressed: () {
                    controller.toggleTorch();
                  },
                ),
              ),
            ),
          ),

          // Processing indicator
          if (processing)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.78,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Checking in...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom instruction
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.65,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  processing
                      ? 'Checking patient appointment...'
                      : 'Place the appointment QR inside the frame.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
