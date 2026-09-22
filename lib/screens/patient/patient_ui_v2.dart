import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ui/widgets/careflow_ui_widgets.dart';
import '../../ui/theme/careflow_ui_theme.dart';
import '../../ui/widgets/careflow_logout_tile.dart';

class PatientUIV2 extends StatefulWidget {
  const PatientUIV2({super.key});

  @override
  State<PatientUIV2> createState() => _PatientUIV2State();
}

class _PatientUIV2State extends State<PatientUIV2> {
  int index = 0;

  String get patientName {
    final metadata =
        Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    return '${metadata['full_name'] ?? 'Patient'}';
  }

  final labels = const [
    'Home',
    'Slots',
    'Reports',
    'History',
    'Profile',
  ];

  final icons = const [
    Icons.home_rounded,
    Icons.calendar_month_rounded,
    Icons.description_rounded,
    Icons.history_rounded,
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
            const _PatientEmptyPage(
              icon: Icons.calendar_month_rounded,
              title: 'Book a slot',
              message: 'Available doctor slots from Supabase will appear here.',
            ),
            const _PatientEmptyPage(
              icon: Icons.description_outlined,
              title: 'Medical reports',
              message: 'Lab reports and prescriptions will appear here.',
            ),
            const _PatientEmptyPage(
              icon: Icons.history_rounded,
              title: 'Visit history',
              message: 'Completed appointments will appear here.',
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
    );
  }

  Widget _home() {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          CareFlowHeader(
            greeting: 'Good day',
            name: patientName,
            subtitle: 'Your care, appointments and reports in one place',
            onNotification: () {},
          ),
          const SizedBox(height: 18),
          CareFlowGlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: CareFlowUIColors.softTeal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: CareFlowUIColors.teal,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your health dashboard',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Keep appointments and medical documents organized.',
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
          const CareFlowSectionTitle(title: 'Quick actions'),
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
                label: 'Find a doctor',
                icon: Icons.medical_services_rounded,
                onTap: () => setState(() => index = 1),
              ),
              CareFlowQuickAction(
                label: 'My reports',
                icon: Icons.folder_open_rounded,
                tint: CareFlowUIColors.softTeal,
                onTap: () => setState(() => index = 2),
              ),
              CareFlowQuickAction(
                label: 'Visit history',
                icon: Icons.history_rounded,
                tint: CareFlowUIColors.softOrange,
                onTap: () => setState(() => index = 3),
              ),
              CareFlowQuickAction(
                label: 'My profile',
                icon: Icons.person_rounded,
                tint: CareFlowUIColors.softPurple,
                onTap: () => setState(() => index = 4),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const CareFlowSectionTitle(title: 'Upcoming care'),
          const SizedBox(height: 10),
          const CareFlowEmptyState(
            icon: Icons.event_available_rounded,
            title: 'No upcoming appointments',
            message: 'Once you book a slot, your next visit will appear here.',
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
          'My profile',
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
                      patientName,
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

class _PatientEmptyPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _PatientEmptyPage({
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
