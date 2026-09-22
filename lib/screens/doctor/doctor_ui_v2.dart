import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ui/theme/careflow_ui_theme.dart';
import '../../ui/widgets/careflow_logout_tile.dart';
import '../../ui/widgets/careflow_ui_widgets.dart';

class DoctorUIV2 extends StatefulWidget {
  const DoctorUIV2({super.key});

  @override
  State<DoctorUIV2> createState() => _DoctorUIV2State();
}

class _DoctorUIV2State extends State<DoctorUIV2> {
  int index = 0;

  String get doctorName {
    final metadata =
        Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    return '${metadata['full_name'] ?? 'Doctor'}';
  }

  final labels = const [
    'Home',
    'Appointments',
    'Patients',
    'Reports',
    'Profile',
  ];

  final icons = const [
    Icons.home_rounded,
    Icons.event_note_rounded,
    Icons.groups_rounded,
    Icons.science_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: [
            _home(),
            const _DoctorEmptyPage(
              icon: Icons.event_note_rounded,
              title: 'Appointments',
              message: 'Your real appointments will appear here.',
            ),
            const _DoctorEmptyPage(
              icon: Icons.groups_rounded,
              title: 'My patients',
              message: 'Patients linked to your appointments will appear here.',
            ),
            const _DoctorEmptyPage(
              icon: Icons.science_rounded,
              title: 'Lab reports',
              message: 'Reports related to your patients will appear here.',
            ),
            _profile(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: [
          for (var i = 0; i < labels.length; i++)
            NavigationDestination(
              icon: Icon(icons[i]),
              label: labels[i],
            ),
        ],
      ),
      floatingActionButton: index == 0
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => index = 1),
              icon: const Icon(Icons.calendar_today_rounded),
              label: const Text('Appointments'),
            )
          : null,
    );
  }

  Widget _home() {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
        children: [
          CareFlowHeader(
            greeting: 'Good day',
            name: doctorName,
            subtitle: 'A focused workspace for today’s care',
            onNotification: () {},
          ),
          const SizedBox(height: 18),
          const CareFlowGlassCard(
            padding: EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  child: Icon(Icons.medical_services_rounded),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today at a glance',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Live appointments and patient data will load from Supabase.',
                        style: TextStyle(
                          color: CareFlowUIColors.muted,
                          height: 1.35,
                          fontSize: 12,
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
            children: const [
              CareFlowStatCard(
                label: 'Today’s appointments',
                value: '—',
                icon: Icons.today_rounded,
              ),
              CareFlowStatCard(
                label: 'Patients',
                value: '—',
                icon: Icons.groups_rounded,
                tint: CareFlowUIColors.softTeal,
              ),
              CareFlowStatCard(
                label: 'Pending reports',
                value: '—',
                icon: Icons.science_rounded,
                tint: CareFlowUIColors.softOrange,
              ),
              CareFlowStatCard(
                label: 'Availability',
                value: '—',
                icon: Icons.schedule_rounded,
                tint: CareFlowUIColors.softPurple,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const CareFlowSectionTitle(title: 'Today’s queue'),
          const SizedBox(height: 10),
          const CareFlowEmptyState(
            icon: Icons.event_available_rounded,
            title: 'No appointments to show',
            message: 'Connect the appointment query to populate the queue.',
          ),
        ],
      ),
    );
  }

  Widget _profile() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        const Text(
          'Doctor profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: CareFlowUIColors.text,
          ),
        ),
        const SizedBox(height: 16),
        CareFlowGlassCard(
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                child: Icon(Icons.person_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      Supabase.instance.client.auth.currentUser?.email ?? '',
                      style: const TextStyle(
                        color: CareFlowUIColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const CareFlowLogoutTile(),
      ],
    );
  }
}

class _DoctorEmptyPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _DoctorEmptyPage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 60),
        CareFlowEmptyState(
          icon: icon,
          title: title,
          message: message,
        ),
      ],
    );
  }
}
