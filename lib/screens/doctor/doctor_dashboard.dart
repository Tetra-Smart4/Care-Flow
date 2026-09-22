import 'package:flutter/material.dart';
import '../profile/careflow_role_profile_screen.dart';
import '../../features/careflow/screens/consultation_screen.dart';
import '../../features/careflow/screens/features_hub.dart';
import '../../features/careflow/screens/queue_screen.dart';
import '../../features/careflow/widgets/feature_widgets.dart';
import '../../ui/theme/careflow_ui_theme.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});
  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int index = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: IndexedStack(index: index, children: [
        _home(),
        const ConsultationScreen(),
        const QueueScreen(),
        _patients(),
        const CareFlowRoleProfileScreen(
            title: 'My profile',
            roleLabel: 'Doctor',
            icon: Icons.medical_services_rounded)
      ])),
      bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (v) => setState(() => index = v),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.medical_services_rounded), label: 'Consult'),
            NavigationDestination(
                icon: Icon(Icons.groups_rounded), label: 'Queue'),
            NavigationDestination(
                icon: Icon(Icons.people_alt_rounded), label: 'Patients'),
            NavigationDestination(
                icon: Icon(Icons.person_rounded), label: 'Profile')
          ]));
  Widget _home() =>
      ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 30), children: [
        const Text('CareFlow',
            style: TextStyle(
                color: CareFlowUIColors.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Doctor workspace',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('Consult, prescribe and keep patient care connected.',
            style: TextStyle(color: CareFlowUIColors.muted, fontSize: 12)),
        const SizedBox(height: 18),
        Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF0F9D8A)]),
                borderRadius: BorderRadius.circular(26)),
            child: const Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today\'s care flow',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900)),
                      SizedBox(height: 7),
                      Text(
                          'Review appointments, check the queue and finish digital consultation records.',
                          style: TextStyle(
                              color: Color(0xE6FFFFFF),
                              fontSize: 12,
                              height: 1.35))
                    ]),
              ),
              Icon(Icons.medical_services_rounded,
                  color: Colors.white, size: 44)
            ])),
        const SizedBox(height: 22),
        const SectionTitle('Doctor actions'),
        FeatureCard(
            icon: Icons.medical_services_rounded,
            title: 'Start consultation',
            subtitle: 'Symptoms, diagnosis, notes and prescription.',
            color: CareFlowUIColors.softTeal,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ConsultationScreen()))),
        const SizedBox(height: 10),
        FeatureCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan patient QR',
            subtitle: 'Check in and issue a live queue token.',
            color: CareFlowUIColors.softPurple,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const CareFlowFeaturesHub(role: 'doctor')))),
        const SizedBox(height: 10),
        FeatureCard(
            icon: Icons.groups_rounded,
            title: 'Live queue',
            subtitle: 'See current tokens and estimated waits.',
            onTap: () => setState(() => index = 2)),
        const SizedBox(height: 10),
        FeatureCard(
            icon: Icons.more_horiz_rounded,
            title: 'All care tools',
            subtitle: 'Medicines, follow-ups, notifications and more.',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CareFlowFeaturesHub(role: 'doctor'))))
      ]);
  Widget _patients() => const Center(
      child: EmptyState(
          icon: Icons.people_alt_rounded,
          title: 'Patient workspace',
          message:
              'Patients connected to today\'s appointments appear here. Open Consultation from the bottom bar to start care.'));
}
