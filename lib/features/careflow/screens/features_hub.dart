import 'package:flutter/material.dart';

import '../widgets/feature_widgets.dart';
import 'appointment_booking_screen.dart';
import 'billing_screen.dart';
import 'consultation_screen.dart';
import 'followup_screen.dart';
import 'medicine_info_screen.dart';
import 'notifications_screen.dart';
import 'qr_checkin_screen.dart';
import 'queue_screen.dart';
import 'records_screen.dart';
import '../../../ui/theme/careflow_ui_theme.dart';

class CareFlowFeaturesHub extends StatelessWidget {
  const CareFlowFeaturesHub({
    super.key,
    required this.role,
  });

  final String role;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[
              Color(0xFF2563EB),
              Color(0xFF0F9D8A),
            ],
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${role[0].toUpperCase()}'
                    '${role.substring(1)} workspace',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Appointments, queue, records and care tasks in one place.',
                    style: TextStyle(
                      color: Color(0xE6FFFFFF),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 44,
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const SectionTitle('Core workflow'),
    ];

    if (role == 'patient') {
      cards.addAll(<Widget>[
        FeatureCard(
          icon: Icons.calendar_month_rounded,
          title: 'Book appointment',
          subtitle: 'Find a doctor and reserve a live appointment slot.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AppointmentBookingScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        FeatureCard(
          icon: Icons.qr_code_rounded,
          title: 'My check-in QR',
          subtitle: 'Show your appointment QR at the clinic desk.',
          color: CareFlowUIColors.softTeal,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const QrCheckinScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (role == 'doctor') {
      cards.addAll(<Widget>[
        FeatureCard(
          icon: Icons.medical_services_rounded,
          title: 'Consultation',
          subtitle: 'Record symptoms, diagnosis, notes and prescription.',
          color: CareFlowUIColors.softTeal,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ConsultationScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        FeatureCard(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Scan patient QR',
          subtitle: 'Check in an appointment and issue a live token.',
          color: CareFlowUIColors.softPurple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const QrScannerScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (role == 'clinic') {
      cards.addAll(<Widget>[
        FeatureCard(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Reception check-in',
          subtitle: 'Scan patient QR and move the waiting queue live.',
          color: CareFlowUIColors.softPurple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const QrScannerScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        FeatureCard(
          icon: Icons.receipt_long_rounded,
          title: 'Billing',
          subtitle: 'Create invoice totals and mark a visit paid.',
          color: CareFlowUIColors.softOrange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BillingScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
      ]);
    }

    cards.add(
      FeatureCard(
        icon: Icons.groups_rounded,
        title: 'Live queue',
        subtitle: 'Current token, waiting positions and estimated time.',
        color: CareFlowUIColors.softBlue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const QueueScreen(),
            ),
          );
        },
      ),
    );

    cards.add(const SizedBox(height: 10));

    if (role == 'patient') {
      cards.add(
        FeatureCard(
          icon: Icons.folder_copy_rounded,
          title: 'Medical records',
          subtitle: 'Consultations, prescriptions and lab reports.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RecordsScreen(),
              ),
            );
          },
        ),
      );
      cards.add(const SizedBox(height: 10));
    }

    cards.add(
      FeatureCard(
        icon: Icons.medication_rounded,
        title: 'Medicine information',
        subtitle: 'Reference information for common medicines.',
        color: CareFlowUIColors.softTeal,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MedicineInfoScreen(),
            ),
          );
        },
      ),
    );

    cards.add(const SizedBox(height: 10));

    if (role == 'patient' || role == 'doctor') {
      cards.add(
        FeatureCard(
          icon: Icons.event_repeat_rounded,
          title: 'Follow-ups',
          subtitle: 'Schedule and review post-consultation follow-up visits.',
          color: CareFlowUIColors.softPurple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FollowUpScreen(),
              ),
            );
          },
        ),
      );
      cards.add(const SizedBox(height: 10));
    }

    if (role == 'patient') {
      cards.add(
        FeatureCard(
          icon: Icons.receipt_long_rounded,
          title: 'My bills',
          subtitle: 'View billing records and receipt numbers.',
          color: CareFlowUIColors.softOrange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BillingScreen(
                  patientMode: true,
                ),
              ),
            );
          },
        ),
      );
      cards.add(const SizedBox(height: 10));
    }

    cards.add(
      FeatureCard(
        icon: Icons.notifications_none_rounded,
        title: 'Notifications',
        subtitle: 'Appointment, queue and care updates.',
        color: CareFlowUIColors.softBlue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationsScreen(),
            ),
          );
        },
      ),
    );

    return FeatureScaffold(
      title: 'CareFlow',
      subtitle: 'Connected care tools',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          28,
        ),
        children: cards,
      ),
    );
  }
}
