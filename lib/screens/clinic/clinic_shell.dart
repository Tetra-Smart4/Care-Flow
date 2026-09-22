import 'package:flutter/material.dart';
import '../../widgets/clinic/clinic_widgets.dart';
import 'analytics/clinic_analytics_screen.dart';
import 'doctors/clinic_doctors_screen.dart';
import 'home/clinic_home_screen.dart';
import 'patients/clinic_patients_screen.dart';
import 'profile/clinic_profile_screen.dart';

class ClinicShell extends StatefulWidget {
  const ClinicShell({super.key});

  @override
  State<ClinicShell> createState() => _ClinicShellState();
}

class _ClinicShellState extends State<ClinicShell> {
  int index = 0;

  void _goTo(int value) => setState(() => index = value);

  @override
  Widget build(BuildContext context) {
    final pages = [
      ClinicHomeScreen(onNavigate: _goTo),
      const ClinicDoctorsScreen(),
      const ClinicPatientsScreen(),
      const ClinicAnalyticsScreen(),
      const ClinicProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: ClinicColors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: ClinicColors.border),
            boxShadow: const [
              BoxShadow(
                blurRadius: 30,
                offset: Offset(0, 8),
                color: Color(0x18000000),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: _goTo,
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 76,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.medical_services_outlined),
                selectedIcon: Icon(Icons.medical_services_rounded),
                label: 'Doctors',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: 'Patients',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics_rounded),
                label: 'Analytics',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
