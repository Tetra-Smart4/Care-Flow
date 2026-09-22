import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../profile/careflow_role_profile_screen.dart';
import 'doctors/clinic_doctors_screen.dart';
import 'patients/clinic_patients_screen.dart';

import '../../features/careflow/screens/billing_screen.dart';
import '../../features/careflow/screens/features_hub.dart';
import '../../features/careflow/widgets/feature_widgets.dart';
import '../../services/clinic_service.dart';
import '../../ui/theme/careflow_ui_theme.dart';

class ClinicDashboard extends StatefulWidget {
  const ClinicDashboard({super.key});

  @override
  State<ClinicDashboard> createState() => _ClinicDashboardState();
}

class _ClinicDashboardState extends State<ClinicDashboard> {
  final ClinicService _clinicService = ClinicService();

  int index = 0;

  List<Map<String, dynamic>> _queue = [];
  bool _queueLoading = true;
  String? _queueError;

  RealtimeChannel? _queueChannel;

  @override
  void initState() {
    super.initState();

    _loadQueue();

    _queueChannel = _clinicService.subscribe(
      _loadQueue,
      tag: 'clinic-dashboard-queue',
    );
  }

  @override
  void dispose() {
    _queueChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadQueue() async {
    try {
      final rows = await _clinicService.getQueue();

      if (!mounted) return;

      setState(() {
        _queue = rows;
        _queueLoading = false;
        _queueError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _queueLoading = false;
        _queueError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: [
            _home(),
            const ClinicDoctorsScreen(),
            const ClinicPatientsScreen(),
            _queueScreen(),
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
        onDestinationSelected: (v) {
          setState(() => index = v);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_rounded),
            label: 'Doctors',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_rounded),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_2_rounded),
            label: 'Queue',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _home() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        const Text(
          'CareFlow',
          style: TextStyle(
            color: CareFlowUIColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Clinic operations',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Run reception, queue, doctors and billing from one workspace.',
          style: TextStyle(
            color: CareFlowUIColors.muted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2563EB),
                Color(0xFF0F9D8A),
              ],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinic command center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Check in patients, manage the live queue and keep billing organized.',
                      style: TextStyle(
                        color: Color(0xE6FFFFFF),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.local_hospital_rounded,
                color: Colors.white,
                size: 44,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionTitle('Reception actions'),
        FeatureCard(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Scan patient QR',
          subtitle: 'Check in the patient and issue a token.',
          color: CareFlowUIColors.softPurple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CareFlowFeaturesHub(
                role: 'clinic',
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        FeatureCard(
          icon: Icons.groups_rounded,
          title: 'Live queue',
          subtitle: 'Monitor tokens and waiting times.',
          onTap: () => setState(() => index = 3),
        ),
        const SizedBox(height: 10),
        FeatureCard(
          icon: Icons.receipt_long_rounded,
          title: 'Billing desk',
          subtitle: 'Create digital bills and receipt numbers.',
          color: CareFlowUIColors.softOrange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BillingScreen(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        FeatureCard(
          icon: Icons.more_horiz_rounded,
          title: 'All clinic tools',
          subtitle: 'Queue, billing, analytics and notifications.',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CareFlowFeaturesHub(
                role: 'clinic',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _queueScreen() {
    final activeQueue = _queue.where((item) {
      final status = item['status']?.toString().toLowerCase();

      return status == 'checked_in' ||
          status == 'waiting' ||
          status == 'called';
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
        title: const Text(
          'Live Queue',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadQueue,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadQueue,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const Text(
              'Updates in real time',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 20),

            // QUEUE HEADER
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF0F9D8A),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's queue",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${activeQueue.length} active tokens',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_queueLoading)
              const Padding(
                padding: EdgeInsets.all(50),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_queueError != null)
              _queueErrorWidget()
            else if (activeQueue.isEmpty)
              _emptyQueueWidget()
            else
              ...activeQueue.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _queueCard(item),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _queueCard(Map<String, dynamic> item) {
    final token = item['token_no']?.toString() ?? '-';
    final patient = item['patient_name']?.toString() ?? 'Patient';
    final doctor = item['doctor_name']?.toString() ?? 'Doctor';
    final time = item['appointment_time']?.toString() ?? '-';
    final status = item['status']?.toString() ?? 'unknown';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$token',
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  doctor,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Appointment: $time',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF0F9D8A),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyQueueWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 45,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 64,
            color: Color(0xFF2563EB),
          ),
          SizedBox(height: 18),
          Text(
            'Queue is clear',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'There are no active checked-in patients right now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _queueErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 50,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to load queue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _queueError ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _loadQueue,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
