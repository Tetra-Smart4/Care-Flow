import 'package:flutter/material.dart';
import '../../../services/clinic_service.dart';
import '../../../widgets/clinic/clinic_widgets.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const DoctorDetailsScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<DoctorDetailsScreen> createState() =>
      _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final ClinicService service = ClinicService();

  late bool available;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    available = widget.doctor['is_available'] == true;
  }

  // ============================================================
  // TOGGLE DOCTOR AVAILABILITY
  // ============================================================

  Future<void> _toggle(bool value) async {
    final oldValue = available;

    // Get the REAL doctor ID from clinic_doctors RPC data.
    final doctorId = widget.doctor['doctor_id']?.toString();

    if (doctorId == null ||
        doctorId.isEmpty ||
        doctorId == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Doctor ID is missing. Cannot update availability.',
          ),
        ),
      );
      return;
    }

    setState(() {
      available = value;
      saving = true;
    });

    try {
      await service.setDoctorAvailability(
        doctorId: doctorId,
        value: value,
      );

      if (!mounted) return;

      // The database update succeeded.
      // Return to Doctors screen and tell it to refresh.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        available = oldValue;
        saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update availability: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.doctor['profiles'] is Map
        ? Map<String, dynamic>.from(
            widget.doctor['profiles'] as Map,
          )
        : <String, dynamic>{};

    final name =
        profile['full_name']?.toString() ?? 'Doctor';

    final specialization =
        widget.doctor['specialization']?.toString() ??
            'Specialist';

    final doctorId =
        widget.doctor['doctor_id']?.toString() ?? '—';

    final qualification =
        widget.doctor['qualification']?.toString() ?? '—';

    final experience =
        widget.doctor['experience']?.toString() ?? '—';

    final phone =
        profile['phone']?.toString() ?? '—';

    return Scaffold(
      backgroundColor: ClinicColors.background,

      appBar: AppBar(
        title: const Text('Doctor details'),
        backgroundColor: Colors.transparent,
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          30,
        ),
        children: [

          // ======================================================
          // DOCTOR HEADER
          // ======================================================

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: ClinicColors.border,
              ),
            ),
            child: Column(
              children: [

                CircleAvatar(
                  radius: 38,
                  backgroundColor:
                      ClinicColors.primarySoft,
                  child: const Icon(
                    Icons.person_rounded,
                    size: 42,
                    color: ClinicColors.primary,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: ClinicColors.text,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  specialization,
                  style: const TextStyle(
                    color: ClinicColors.muted,
                  ),
                ),

                const SizedBox(height: 10),

                ClinicStatusPill(
                  text: available
                      ? 'Active'
                      : 'Inactive',
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ======================================================
          // DOCTOR ID
          // ======================================================

          _info(
            'Doctor ID',
            doctorId,
            Icons.badge_outlined,
          ),

          // ======================================================
          // QUALIFICATION
          // ======================================================

          _info(
            'Qualification',
            qualification,
            Icons.school_outlined,
          ),

          // ======================================================
          // EXPERIENCE
          // ======================================================

          _info(
            'Experience',
            experience,
            Icons.work_history_outlined,
          ),

          // ======================================================
          // PHONE
          // ======================================================

          _info(
            'Phone',
            phone,
            Icons.phone_outlined,
          ),

          // ======================================================
          // AVAILABILITY
          // ======================================================

          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: ClinicColors.border,
              ),
            ),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,

              title: const Text(
                'Accepting appointments',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),

              subtitle: Text(
                saving
                    ? 'Updating...'
                    : 'Controls the doctor availability shown to patients.',
              ),

              value: available,

              onChanged: saving
                  ? null
                  : _toggle,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION CARD
  // ============================================================

  Widget _info(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ClinicColors.border,
        ),
      ),
      child: Row(
        children: [

          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ClinicColors.primarySoft,
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: ClinicColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    color: ClinicColors.muted,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ClinicColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}