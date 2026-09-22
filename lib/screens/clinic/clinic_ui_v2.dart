import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ui/theme/careflow_ui_theme.dart';
import '../../ui/widgets/careflow_logout_tile.dart';
import '../../ui/widgets/careflow_ui_widgets.dart';

import 'doctors/add_doctor_screen.dart';
import 'doctors/clinic_doctors_screen.dart';
import 'patients/clinic_patients_screen.dart';
import 'appointments/clinic_appointments_screen.dart';
import 'analytics/clinic_analytics_screen.dart';
import '../profile/careflow_role_profile_screen.dart';

class ClinicUIV2 extends StatefulWidget {
  const ClinicUIV2({super.key});

  @override
  State<ClinicUIV2> createState() => _ClinicUIV2State();
}

class _ClinicUIV2State extends State<ClinicUIV2> {
  int index = 0;

  String get clinicName {
    final metadata =
        Supabase.instance.client.auth.currentUser?.userMetadata ?? {};

    return '${metadata['full_name'] ?? 'Clinic'}';
  }

  final labels = const [
    'Home',
    'Doctors',
    'Patients',
    'Analytics',
    'Profile',
  ];

  final icons = const [
    Icons.home_rounded,
    Icons.medical_services_rounded,
    Icons.groups_rounded,
    Icons.insights_rounded,
    Icons.business_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: [
            _home(),

            // Doctors
            const ClinicDoctorsScreen(),

            // Patients
            const ClinicPatientsScreen(),

            // Analytics
            const ClinicAnalyticsScreen(),

            // Profile
            const CareFlowRoleProfileScreen(
              title: 'Clinic profile',
              roleLabel: 'Clinic',
              icon: Icons.business_rounded,
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        destinations: [
          for (var i = 0; i < labels.length; i++)
            NavigationDestination(
              icon: Icon(icons[i]),
              label: labels[i],
            ),
        ],
      ),

      // Add Doctor only when Doctors tab is selected.
      floatingActionButton: index == 1
          ? FloatingActionButton.extended(
              onPressed: _openAddDoctor,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add doctor'),
            )
          : null,
    );
  }

  void _openAddDoctor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddDoctorScreen(),
      ),
    );
  }

  void _openAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ClinicAppointmentsScreen(),
      ),
    );
  }

  void _openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 42,
                  color: CareFlowUIColors.primary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your clinic notifications will appear here when available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CareFlowUIColors.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _home() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
        children: [
          CareFlowHeader(
            greeting: 'Good day',
            name: clinicName,
            subtitle: 'A clean control center for your clinic',
            onNotification: _openNotifications,
          ),

          const SizedBox(height: 18),

          CareFlowGlassCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: CareFlowUIColors.softBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: CareFlowUIColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clinic overview',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$clinicName · live data from Supabase',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CareFlowUIColors.muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: [
              CareFlowStatCard(
                label: 'Doctors',
                value: '—',
                icon: Icons.medical_services_rounded,
                onTap: () => setState(() => index = 1),
              ),

              CareFlowStatCard(
                label: 'Patients',
                value: '—',
                icon: Icons.groups_rounded,
                tint: CareFlowUIColors.softTeal,
                onTap: () => setState(() => index = 2),
              ),

              CareFlowStatCard(
                label: 'Appointments',
                value: '—',
                icon: Icons.calendar_month_rounded,
                tint: CareFlowUIColors.softOrange,
                onTap: _openAppointments,
              ),

              CareFlowStatCard(
                label: 'Completion rate',
                value: '—',
                icon: Icons.insights_rounded,
                tint: CareFlowUIColors.softPurple,
                onTap: () => setState(() => index = 3),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const CareFlowSectionTitle(
            title: 'Clinic actions',
          ),

          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              CareFlowQuickAction(
                label: 'Manage doctors',
                icon: Icons.medical_services_rounded,
                onTap: () => setState(() => index = 1),
              ),

              CareFlowQuickAction(
                label: 'View patients',
                icon: Icons.groups_rounded,
                tint: CareFlowUIColors.softTeal,
                onTap: () => setState(() => index = 2),
              ),

              CareFlowQuickAction(
                label: 'Appointments',
                icon: Icons.calendar_month_rounded,
                tint: CareFlowUIColors.softOrange,
                onTap: _openAppointments,
              ),

              CareFlowQuickAction(
                label: 'Analytics',
                icon: Icons.insights_rounded,
                tint: CareFlowUIColors.softPurple,
                onTap: () => setState(() => index = 3),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 