import 'package:flutter/material.dart';

import '../profile/careflow_role_profile_screen.dart';
import '../../features/careflow/screens/appointment_booking_screen.dart';
import '../../features/careflow/screens/features_hub.dart';
import '../../features/careflow/screens/qr_checkin_screen.dart';
import '../../features/careflow/screens/queue_screen.dart';
import '../../features/careflow/screens/records_screen.dart';
import '../../features/careflow/screens/symptom_doctor_screen.dart';
import '../../features/careflow/widgets/feature_widgets.dart';
import '../../ui/theme/careflow_ui_theme.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({
    super.key,
  });

  @override
  State<PatientDashboard> createState() =>
      _PatientDashboardState();
}

class _PatientDashboardState
    extends State<PatientDashboard> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: [
            _home(),
            const AppointmentBookingScreen(),
            const QueueScreen(),
            const RecordsScreen(),
            const CareFlowRoleProfileScreen(
              title: 'My profile',
              roleLabel: 'Patient',
              icon: Icons.person_rounded,
            ),
          ],
        ),
      ),

      // =====================================================
      // BOTTOM NAVIGATION
      // =====================================================

      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.calendar_month_rounded,
            ),
            label: 'Book',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_rounded),
            label: 'Queue',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.folder_copy_rounded,
            ),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PATIENT HOME
  // =========================================================

  Widget _home() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          30,
        ),
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          // =================================================
          // HEADER
          // =================================================

          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CareFlow',
                      style: TextStyle(
                        color:
                            CareFlowUIColors.muted,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your care, connected.',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.w900,
                        color:
                            CareFlowUIColors.text,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Appointments, queue and medical '
                      'records in one place.',
                      style: TextStyle(
                        color:
                            CareFlowUIColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () {
                  setState(() {
                    index = 4;
                  });
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                icon: const Icon(
                  Icons.person_outline_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // =================================================
          // HEALTH JOURNEY CARD
          // =================================================

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF0F9D8A),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(26),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CareFlow health journey',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Find a doctor → book → check in → '
                        'follow the live queue → receive your records.',
                        style: TextStyle(
                          color:
                              Color(0xE6FFFFFF),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          const SectionTitle(
            'Quick actions',
          ),

          const SizedBox(height: 10),

          // =================================================
          // FIND DOCTOR BY SYMPTOMS
          // =================================================

          FeatureCard(
            icon: Icons.manage_search_rounded,
            title: 'Find doctor by symptoms',
            subtitle:
                'Describe your symptoms and find a relevant specialization.',
            color: CareFlowUIColors.softBlue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SymptomDoctorScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // =================================================
          // BOOK APPOINTMENT
          // =================================================

          FeatureCard(
            icon: Icons.calendar_month_rounded,
            title: 'Book appointment',
            subtitle:
                'Reserve a doctor and clinic slot.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AppointmentBookingScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // =================================================
          // MY CHECK-IN QR
          // =================================================

          FeatureCard(
            icon: Icons.qr_code_rounded,
            title: 'My check-in QR',
            subtitle:
                'Show your appointment QR at reception.',
            color: CareFlowUIColors.softTeal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const QrCheckinScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // =================================================
          // MEDICAL RECORDS
          // =================================================

          FeatureCard(
            icon: Icons.folder_copy_rounded,
            title: 'Medical records',
            subtitle:
                'View consultations, prescriptions and reports.',
            color:
                CareFlowUIColors.softPurple,
            onTap: () {
              setState(() {
                index = 3;
              });
            },
          ),

          const SizedBox(height: 10),

          // =================================================
          // ALL CARE TOOLS
          // =================================================

          FeatureCard(
            icon: Icons.more_horiz_rounded,
            title: 'All care tools',
            subtitle:
                'Queue, medicines, bills, follow-ups and notifications.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const CareFlowFeaturesHub(
                    role: 'patient',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 