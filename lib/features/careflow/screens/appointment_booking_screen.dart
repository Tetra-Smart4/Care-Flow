import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({
    super.key,
    this.initialDoctorId,
    this.initialClinicId,
    this.initialDoctorName,
    this.initialClinicName,
  });

  final String? initialDoctorId;
  final String? initialClinicId;
  final String? initialDoctorName;
  final String? initialClinicName;

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
  TimeOfDay? _selectedTime;

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
      final clinics = _toRows(clinicResponse);

      if (!mounted) return;

      Map<String, dynamic>? initialClinic;
      if (widget.initialClinicId != null) {
        for (final clinic in clinics) {
          if (clinic['id']?.toString() == widget.initialClinicId) {
            initialClinic = clinic;
            break;
          }
        }
      }

      List<Map<String, dynamic>> doctors = [];
      Map<String, dynamic>? initialDoctor;

      if (initialClinic != null) {
        doctors = await _loadDoctorsForClinic(
          initialClinic['id'].toString(),
        );

        if (widget.initialDoctorId != null) {
          for (final doctor in doctors) {
            if (doctor['id']?.toString() == widget.initialDoctorId) {
              initialDoctor = doctor;
              break;
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _clinics = clinics;
        _doctors = doctors;
        _selectedClinic = initialClinic;
        _selectedDoctor = initialDoctor;
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

  Future<List<Map<String, dynamic>>> _loadDoctorsForClinic(
    String clinicId,
  ) async {
    final response = await _db.rpc(
      'careflow_list_doctors_for_clinic',
      params: {
        'p_clinic_id': clinicId,
      },
    );

    return _toRows(response);
  }

  List<Map<String, dynamic>> _toRows(dynamic response) {
    if (response == null) return [];

    if (response is List) {
      return response
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }

    if (response is Map) {
      return [Map<String, dynamic>.from(response)];
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
        .replaceFirst('Exception: ', '')
        .trim();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final initial = _selectedDate.isBefore(
      DateTime(today.year, today.month, today.day),
    )
        ? today
        : _selectedDate;

    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      initialDate: initial,
      helpText: 'Select appointment date',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = picked;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: 'Select appointment time',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedTime = picked;
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
      _showMessage('Please select an appointment time.');
      return;
    }

    setState(() {
      _booking = true;
      _error = null;
    });

    try {
      final appointmentId = await _db.rpc(
        'careflow_book_appointment',
        params: {
          'p_doctor_id': _selectedDoctor!['id'].toString(),
          'p_clinic_id': _selectedClinic!['id'].toString(),
          'p_appointment_date': _dateForDatabase(_selectedDate),
          'p_appointment_time': _timeForDatabase(_selectedTime!),
          'p_reason': _reasonController.text.trim().isEmpty
              ? 'General consultation'
              : _reasonController.text.trim(),
        },
      );

      if (!mounted) return;

      setState(() {
        _booking = false;
      });

      await _showBookingSuccess(
        appointmentId: appointmentId.toString(),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _booking = false;
        _error = _cleanError(e);
      });
    }
  }

  Future<void> _showBookingSuccess({
    required String appointmentId,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF35B96F),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Appointment booked'),
              ),
            ],
          ),
          content: Text(
            'Your appointment has been booked successfully.\n\n'
            'Doctor: ${_doctorName(_selectedDoctor!)}\n'
            'Clinic: ${_clinicName(_selectedClinic!)}\n'
            'Date: ${_displayDate(_selectedDate)}\n'
            'Time: ${_displayTime(_selectedTime)}\n\n'
            'Appointment ID: $appointmentId',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  String _dateForDatabase(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _timeForDatabase(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
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

  String _displayTime(TimeOfDay? time) {
    if (time == null) return 'Select time';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  String _doctorName(Map<String, dynamic> doctor) {
    final name = doctor['full_name']?.toString().trim();
    return name == null || name.isEmpty ? 'Doctor' : name;
  }

  String _doctorSpecialization(Map<String, dynamic> doctor) {
    final value = doctor['specialization']?.toString().trim();
    return value == null || value.isEmpty ? 'Medical specialist' : value;
  }

  String _clinicName(Map<String, dynamic> clinic) {
    final name = clinic['full_name']?.toString().trim();
    return name == null || name.isEmpty ? 'Clinic' : name;
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

  List<Map<String, dynamic>> get _filteredDoctors => _doctors;

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
              'Choose clinic, doctor, date and time',
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _clinics.isEmpty && _doctors.isEmpty) {
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
                style: const TextStyle(color: Color(0xFF64748B)),
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
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      children: [
        _sectionTitle(
          'Appointment details',
          'Choose your clinic, doctor, date and time to book.',
        ),
        const SizedBox(height: 18),
        _buildClinicSelector(),
        const SizedBox(height: 16),
        _buildDoctorSelector(),
        const SizedBox(height: 16),
        _buildDateCard(),
        const SizedBox(height: 16),
        _buildTimeCard(),
        const SizedBox(height: 22),
        _buildReasonField(),
        const SizedBox(height: 22),
        _buildSummary(),
        const SizedBox(height: 24),
        if (_error != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEEE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3B2B2)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFF9B1C1C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(
              _booking ? 'Booking appointment...' : 'Book appointment',
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
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
      onTap: _clinics.isEmpty ? null : _showClinicPicker,
    );
  }

  Widget _buildDoctorSelector() {
    final doctors = _filteredDoctors;

    final clinicSelected = _selectedClinic != null;

    return _selectionCard(
      icon: Icons.medical_services_rounded,
      label: 'Doctor',
      value: _selectedDoctor == null
          ? (clinicSelected
              ? (doctors.isEmpty
                  ? 'No doctor assigned to this clinic'
                  : 'Select doctor')
              : 'Select clinic first')
          : '${_doctorName(_selectedDoctor!)} • '
              '${_doctorSpecialization(_selectedDoctor!)}',
      enabled: clinicSelected && doctors.isNotEmpty,
      onTap: clinicSelected && doctors.isNotEmpty ? _showDoctorPicker : null,
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
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                child: Icon(icon, color: const Color(0xFF1677E8)),
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
    return _actionCard(
      icon: Icons.calendar_month_rounded,
      iconColor: const Color(0xFF35B96F),
      label: 'Date',
      value: _displayDate(_selectedDate),
      onTap: _pickDate,
    );
  }

  Widget _buildTimeCard() {
    return _actionCard(
      icon: Icons.schedule_rounded,
      iconColor: const Color(0xFF1677E8),
      label: 'Time',
      value: _displayTime(_selectedTime),
      onTap: _pickTime,
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: iconColor),
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
                      style: const TextStyle(
                        color: Color(0xFF10245C),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
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
              padding: EdgeInsets.only(left: 14, right: 8, bottom: 62),
              child: Icon(Icons.notes_rounded),
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
        border: Border.all(color: const Color(0xFFD8E5F5)),
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
            _displayTime(_selectedTime),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) {
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
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
            children: [
              const Text(
                'Select clinic',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              ..._clinics.map((clinic) {
                final selected = _selectedClinic?['id'] == clinic['id'];

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEAF2FF),
                      child: Icon(
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
                    onTap: () async {
                      Navigator.pop(context);

                      try {
                        final clinicId = clinic['id']?.toString();
                        if (clinicId == null || clinicId.isEmpty) {
                          throw Exception('Clinic ID is missing.');
                        }

                        if (!mounted) return;

                        setState(() {
                          _selectedClinic = clinic;
                          _selectedDoctor = null;
                          _error = null;
                        });

                        final doctors = await _loadDoctorsForClinic(clinicId);

                        if (!mounted) return;

                        setState(() {
                          _doctors = doctors;

                          if (widget.initialDoctorId != null) {
                            for (final doctor in doctors) {
                              if (doctor['id']?.toString() ==
                                  widget.initialDoctorId) {
                                _selectedDoctor = doctor;
                                break;
                              }
                            }
                          }
                        });
                      } catch (e) {
                        if (!mounted) return;

                        setState(() {
                          _doctors = [];
                          _selectedDoctor = null;
                          _error = _cleanError(e);
                        });
                      }
                    },
                  ),
                );
              }),
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
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
            children: [
              const Text(
                'Select doctor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              ...doctors.map((doctor) {
                final selected = _selectedDoctor?['id'] == doctor['id'];

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEAF8F1),
                      child: Icon(
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
                      });
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
