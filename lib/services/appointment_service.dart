import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final SupabaseClient _db = Supabase.instance.client;

  final TextEditingController _reasonController = TextEditingController();

  List<Map<String, dynamic>> _clinics = [];
  List<Map<String, dynamic>> _doctors = [];

  Map<String, dynamic>? _selectedClinic;
  Map<String, dynamic>? _selectedDoctor;

  DateTime _selectedDate = DateTime.now();

  String? _selectedTime;

  bool _loading = true;
  bool _booking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadDirectory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final clinicResponse = await _db.rpc('careflow_list_clinics');

      final doctorResponse = await _db.rpc('careflow_list_doctors');

      final clinics = _toRows(clinicResponse);
      final doctors = _toRows(doctorResponse);

      if (!mounted) return;

      setState(() {
        _clinics = clinics;
        _doctors = doctors;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  List<Map<String, dynamic>> _toRows(dynamic response) {
    if (response == null) {
      return [];
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

    return [];
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.contains('Failed host lookup')) {
      return 'Unable to connect to CareFlow. Check your internet connection.';
    }

    if (text.contains('JWT')) {
      return 'Your session has expired. Please login again.';
    }

    return text
        .replaceFirst('PostgrestException(message: ', '')
        .replaceFirst('Exception: ', '');
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(
        const Duration(days: 90),
      ),
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      helpText: 'Select appointment date',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = picked;
      _selectedTime = null;
    });
  }

  Future<void> _confirmAppointment() async {
    if (_selectedClinic == null) {
      _showMessage('Please select a clinic.');
      return;
    }

    if (_selectedDoctor == null) {
      _showMessage('Please select a doctor.');
      return;
    }

    if (_selectedTime == null) {
      _showMessage('Please select an available time.');
      return;
    }

    final reason = _reasonController.text.trim();

    setState(() {
      _booking = true;
    });

    try {
      final result = await _db.rpc(
        'careflow_book_appointment',
        params: {
          'p_doctor_id': _selectedDoctor!['id'],
          'p_clinic_id': _selectedClinic!['id'],
          'p_appointment_date': _dateForDatabase(_selectedDate),
          'p_appointment_time': _selectedTime,
          'p_reason': reason,
        },
      );

      if (!mounted) return;

      setState(() {
        _booking = false;
      });

      _showSuccessDialog(result);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _booking = false;
      });

      _showMessage(_cleanError(e));
    }
  }

  String _dateForDatabase(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _displayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _doctorName(Map<String, dynamic> doctor) {
    final name = doctor['full_name']?.toString().trim();

    if (name == null || name.isEmpty) {
      return 'Doctor';
    }

    return name;
  }

  String _doctorSpecialization(
    Map<String, dynamic> doctor,
  ) {
    final value = doctor['specialization']?.toString().trim();

    if (value == null || value.isEmpty) {
      return 'Medical specialist';
    }

    return value;
  }

  String _clinicName(Map<String, dynamic> clinic) {
    final name = clinic['full_name']?.toString().trim();

    if (name == null || name.isEmpty) {
      return 'Clinic';
    }

    return name;
  }

  List<Map<String, dynamic>> get _filteredDoctors {
    if (_selectedClinic == null) {
      return _doctors;
    }

    /*
     * careflow_list_doctors currently returns the global
     * doctor directory. Clinic-doctor assignment is handled
     * separately in the CareFlow database.
     *
     * Therefore we do not invent a clinic_id field here.
     */
    return _doctors;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _showSuccessDialog(dynamic appointmentId) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF35B96F),
              ),
              SizedBox(width: 10),
              Text('Appointment booked'),
            ],
          ),
          content: Text(
            'Your appointment has been successfully created.\n\n'
            '${_doctorName(_selectedDoctor!)}\n'
            '${_doctorSpecialization(_selectedDoctor!)}\n\n'
            '${_clinicName(_selectedClinic!)}\n'
            '${_displayDate(_selectedDate)} • $_selectedTime',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F9FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book appointment',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: Color(0xFF10245C),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Choose clinic, doctor and time',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 52,
                color: Color(0xFF64748B),
              ),
              const SizedBox(height: 14),
              const Text(
                'Could not load appointment data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadDirectory,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        8,
        18,
        32,
      ),
      children: [
        _sectionTitle(
          'Appointment details',
          'Select where and when you want to see the doctor.',
        ),
        const SizedBox(height: 18),
        _buildClinicSelector(),
        const SizedBox(height: 16),
        _buildDoctorSelector(),
        const SizedBox(height: 16),
        _buildDateCard(),
        const SizedBox(height: 20),
        _buildTimeSection(),
        const SizedBox(height: 22),
        _buildReasonField(),
        const SizedBox(height: 22),
        _buildSummary(),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: _booking ? null : _confirmAppointment,
            icon: _booking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.check_circle_outline_rounded,
                  ),
            label: Text(
              _booking ? 'Booking...' : 'Confirm appointment',
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: Color(0xFF10245C),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildClinicSelector() {
    return _selectionCard(
      icon: Icons.local_hospital_rounded,
      label: 'Clinic',
      value: _selectedClinic == null
          ? 'Select clinic'
          : _clinicName(_selectedClinic!),
      enabled: _clinics.isNotEmpty,
      onTap: _clinics.isEmpty
          ? null
          : () {
              _showClinicPicker();
            },
    );
  }

  Widget _buildDoctorSelector() {
    final doctors = _filteredDoctors;

    return _selectionCard(
      icon: Icons.medical_services_rounded,
      label: 'Doctor',
      value: _selectedDoctor == null
          ? 'Select doctor'
          : '${_doctorName(_selectedDoctor!)} • '
              '${_doctorSpecialization(_selectedDoctor!)}',
      enabled: doctors.isNotEmpty,
      onTap: doctors.isEmpty
          ? null
          : () {
              _showDoctorPicker();
            },
    );
  }

  Widget _selectionCard({
    required IconData icon,
    required String label,
    required String value,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1677E8),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: enabled
                            ? const Color(0xFF10245C)
                            : const Color(0xFF94A3B8),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF35B96F),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Choose appointment date',
                      style: TextStyle(
                        color: Color(0xFF10245C),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _displayDate(_selectedDate),
                style: const TextStyle(
                  color: Color(0xFF1677E8),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available time',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF10245C),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select a time offered by the selected doctor.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 38,
                color: Color(0xFF64748B),
              ),
              const SizedBox(height: 9),
              Text(
                _selectedDoctor == null
                    ? 'Select a doctor first'
                    : 'No slot list is configured for this doctor yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'No fake times are shown. Configure real doctor availability to enable booking.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reason for visit',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF10245C),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tell the doctor briefly why you are booking.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reasonController,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Example: tooth pain, fever, follow-up...',
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                left: 14,
                right: 8,
                bottom: 62,
              ),
              child: Icon(
                Icons.notes_rounded,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    if (_selectedClinic == null || _selectedDoctor == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEAF2FF),
            Color(0xFFEAF8F1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD8E5F5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF10245C),
            ),
          ),
          const SizedBox(height: 14),
          _summaryRow(
            Icons.medical_services_rounded,
            _doctorName(_selectedDoctor!),
          ),
          const SizedBox(height: 8),
          _summaryRow(
            Icons.local_hospital_rounded,
            _clinicName(_selectedClinic!),
          ),
          const SizedBox(height: 8),
          _summaryRow(
            Icons.calendar_month_rounded,
            _displayDate(_selectedDate),
          ),
          const SizedBox(height: 8),
          _summaryRow(
            Icons.schedule_rounded,
            _selectedTime ?? 'No time selected',
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: const Color(0xFF1677E8),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  void _showClinicPicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              18,
              8,
              18,
              30,
            ),
            children: [
              const Text(
                'Select clinic',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              ..._clinics.map(
                (clinic) {
                  final selected = _selectedClinic?['id'] == clinic['id'];

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEAF2FF),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: Color(0xFF1677E8),
                        ),
                      ),
                      title: Text(
                        _clinicName(clinic),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        clinic['phone']?.toString() ?? 'CareFlow clinic',
                      ),
                      trailing: selected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF35B96F),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedClinic = clinic;
                        });

                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDoctorPicker() {
    final doctors = _filteredDoctors;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              18,
              8,
              18,
              30,
            ),
            children: [
              const Text(
                'Select doctor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              ...doctors.map(
                (doctor) {
                  final selected = _selectedDoctor?['id'] == doctor['id'];

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEAF8F1),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Color(0xFF35B96F),
                        ),
                      ),
                      title: Text(
                        _doctorName(doctor),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        _doctorSpecialization(doctor),
                      ),
                      trailing: selected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF35B96F),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedDoctor = doctor;
                          _selectedTime = null;
                        });

                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
