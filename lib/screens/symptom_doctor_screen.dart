import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/symptom_service.dart';
import '../features/careflow/screens/appointment_booking_screen.dart';

class SymptomDoctorScreen extends StatefulWidget {
  const SymptomDoctorScreen({
    super.key,
  });

  @override
  State<SymptomDoctorScreen> createState() => _SymptomDoctorScreenState();
}

class _SymptomDoctorScreenState extends State<SymptomDoctorScreen> {
  final TextEditingController _symptomController = TextEditingController();

  final SymptomService _symptomService = const SymptomService();

  final SupabaseClient _db = Supabase.instance.client;

  bool loading = false;

  String? specialization;

  String? error;

  List<Map<String, dynamic>> doctors = <Map<String, dynamic>>[];

  // ============================================================
  // FIND DOCTORS
  // ============================================================

  Future<void> _findDoctors() async {
    final text = _symptomController.text.trim();

    if (text.isEmpty) {
      _showMessage(
        'Please enter at least one symptom.',
      );
      return;
    }

    final symptoms = text
        .split(',')
        .map((item) => item.trim())
        .where(
          (item) => item.isNotEmpty,
        )
        .toList();

    final suggested = _symptomService.suggestSpecialization(
      symptoms,
    );

    setState(() {
      loading = true;
      error = null;
      specialization = suggested;
      doctors = [];
    });

    try {
      // ----------------------------------------------------------
      // This RPC returns:
      //
      // doctor_id
      // doctor_name
      // specialization
      // qualification
      // clinic_id
      // clinic_name
      // clinic_address
      //
      // Therefore we have everything needed for booking.
      // ----------------------------------------------------------

      final response = await _db.rpc(
        'careflow_symptom_doctors',
        params: {
          'p_specialization': suggested,
        },
      );

      final rows = _rows(response);

      if (!mounted) {
        return;
      }

      setState(() {
        doctors = rows;
        loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
        error = _cleanError(e);
      });
    }
  }

  // ============================================================
  // CONVERT SUPABASE RESPONSE TO ROWS
  // ============================================================

  List<Map<String, dynamic>> _rows(
    dynamic response,
  ) {
    if (response == null) {
      return <Map<String, dynamic>>[];
    }

    if (response is List) {
      return response
          .whereType<Map>()
          .map(
            (row) => Map<String, dynamic>.from(row),
          )
          .toList();
    }

    if (response is Map) {
      return [
        Map<String, dynamic>.from(response),
      ];
    }

    return <Map<String, dynamic>>[];
  }

  // ============================================================
  // ERROR CLEANUP
  // ============================================================

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.contains('Failed host lookup')) {
      return 'Unable to connect to CareFlow. Check your internet connection.';
    }

    if (text.contains('JWT')) {
      return 'Your session has expired. Please login again.';
    }

    return text
        .replaceFirst(
          'PostgrestException(message: ',
          '',
        )
        .replaceFirst(
          'Exception: ',
          '',
        );
  }

  // ============================================================
  // OPEN BOOKING
  // ============================================================

  void _openBooking(
    Map<String, dynamic> doctor,
  ) {
    final doctorId = doctor['doctor_id']?.toString().trim();

    final clinicId = doctor['clinic_id']?.toString().trim();

    final doctorName = doctor['doctor_name']?.toString().trim();

    final clinicName = doctor['clinic_name']?.toString().trim();

    if (doctorId == null || doctorId.isEmpty) {
      _showMessage(
        'Doctor information is missing.',
      );
      return;
    }

    if (clinicId == null || clinicId.isEmpty) {
      _showMessage(
        'Clinic information is missing for this doctor.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentBookingScreen(
          initialDoctorId: doctorId,
          initialClinicId: clinicId,
          initialDoctorName: doctorName,
          initialClinicName: clinicName,
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F9FC),
        elevation: 0,
        title: const Text(
          'Find a doctor',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF10245C),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          12,
          18,
          30,
        ),
        children: [
          // ======================================================
          // TITLE
          // ======================================================

          const Text(
            'What are your symptoms?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF10245C),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Tell us what you are experiencing and '
            'CareFlow will suggest a relevant doctor '
            'specialization.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          // ======================================================
          // SYMPTOM INPUT
          // ======================================================

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                20,
              ),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: TextField(
              controller: _symptomController,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Example: fever, cough, sore throat',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(18),
                prefixIcon: Padding(
                  padding: EdgeInsets.only(
                    left: 14,
                    right: 8,
                    bottom: 62,
                  ),
                  child: Icon(
                    Icons.medical_information_rounded,
                    color: Color(0xFF1677E8),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'You can enter multiple symptoms separated by commas.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // FIND BUTTON
          // ======================================================

          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: loading ? null : _findDoctors,
              icon: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.search_rounded,
                    ),
              label: Text(
                loading ? 'Finding doctors...' : 'Find doctor',
              ),
            ),
          ),

          // ======================================================
          // SPECIALIZATION
          // ======================================================

          if (specialization != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(
                  20,
                ),
                border: Border.all(
                  color: const Color(0xFFD5E4FA),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.medical_services_rounded,
                      color: Color(0xFF1677E8),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Suggested specialization',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          specialization!,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10245C),
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        const Text(
                          'This suggestion is based on the '
                          'symptoms you entered. It is not a '
                          'medical diagnosis.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ======================================================
          // ERROR
          // ======================================================

          if (error != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
              child: Text(
                error!,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],

          // ======================================================
          // DOCTORS
          // ======================================================

          if (specialization != null && !loading) ...[
            const SizedBox(height: 24),
            const Text(
              'Available doctors',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF10245C),
              ),
            ),
            const SizedBox(height: 12),
            if (doctors.isEmpty)
              _NoDoctorCard(
                specialization: specialization!,
                onBookManually: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppointmentBookingScreen(),
                    ),
                  );
                },
              )
            else
              ...doctors.map(
                (doctor) => _DoctorCard(
                  doctor: doctor,
                  onBook: () => _openBooking(
                    doctor,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }
}

// =================================================================
// DOCTOR CARD
// =================================================================

class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;

  final VoidCallback onBook;

  const _DoctorCard({
    required this.doctor,
    required this.onBook,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final doctorName = doctor['doctor_name']?.toString().trim();

    final specialization = doctor['specialization']?.toString().trim();

    final qualification = doctor['qualification']?.toString().trim();

    final clinicName = doctor['clinic_name']?.toString().trim();

    final clinicAddress = doctor['clinic_address']?.toString().trim();

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          18,
        ),
        side: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------
            // DOCTOR
            // -----------------------------------------------------

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 27,
                  backgroundColor: Color(0xFFEAF2FF),
                  child: Icon(
                    Icons.person_rounded,
                    color: Color(0xFF1677E8),
                  ),
                ),
                const SizedBox(
                  width: 14,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName == null || doctorName.isEmpty
                            ? 'Doctor'
                            : doctorName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10245C),
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        specialization == null || specialization.isEmpty
                            ? 'Medical specialist'
                            : specialization,
                        style: const TextStyle(
                          color: Color(0xFF1677E8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (qualification != null &&
                          qualification.isNotEmpty) ...[
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          qualification,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            // -----------------------------------------------------
            // CLINIC
            // -----------------------------------------------------

            if (clinicName != null && clinicName.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.local_hospital_rounded,
                      size: 20,
                      color: Color(0xFF1677E8),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Clinic',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            clinicName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10245C),
                            ),
                          ),
                          if (clinicAddress != null &&
                              clinicAddress.isNotEmpty) ...[
                            const SizedBox(
                              height: 2,
                            ),
                            Text(
                              clinicAddress,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(
              height: 12,
            ),

            // -----------------------------------------------------
            // BOOK BUTTON
            // -----------------------------------------------------

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onBook,
                icon: const Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Book with this doctor',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// NO DOCTOR
// =================================================================

class _NoDoctorCard extends StatelessWidget {
  final String specialization;

  final VoidCallback onBookManually;

  const _NoDoctorCard({
    required this.specialization,
    required this.onBookManually,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_search_rounded,
            size: 44,
            color: Color(0xFF64748B),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            'No $specialization found',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          const Text(
            'There is currently no matching doctor '
            'available in the CareFlow directory.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          OutlinedButton(
            onPressed: onBookManually,
            child: const Text(
              'Choose doctor manually',
            ),
          ),
        ],
      ),
    );
  }
}
