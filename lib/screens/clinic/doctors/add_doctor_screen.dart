import 'package:flutter/material.dart';
import '../../../services/clinic_service.dart';
import '../../../widgets/clinic/clinic_widgets.dart';

class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final specialization = TextEditingController();
  final qualification = TextEditingController();
  final phone = TextEditingController();
  final service = ClinicService();

  bool loading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    for (final c in [
      name,
      email,
      password,
      specialization,
      qualification,
      phone
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);

    try {
      final result = await service.createDoctor(
        name: name.text,
        email: email.text,
        password: password.text,
        specialization: specialization.text,
        qualification: qualification.text,
        phone: phone.text,
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Doctor registered'),
          content: Text(
            'Doctor ID: ${result['doctor_id'] ?? 'Generated'}\n\n'
            'The doctor can use the registered email and password to sign in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _cleanError(String value) => value.replaceFirst('Exception: ', '');

  String? requiredText(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClinicColors.background,
      appBar: AppBar(
        title: const Text('Add Doctor'),
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: ClinicColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded,
                      color: ClinicColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This account is created for your clinic and linked to the doctor ID automatically.',
                      style: TextStyle(color: ClinicColors.text, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _field(name, 'Doctor name', Icons.person_outline_rounded),
            _field(email, 'Email', Icons.email_outlined,
                keyboard: TextInputType.emailAddress),
            TextFormField(
              controller: password,
              obscureText: hidePassword,
              validator: (v) => (v == null || v.length < 8)
                  ? 'Use at least 8 characters'
                  : null,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => hidePassword = !hidePassword),
                  icon: Icon(hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _field(specialization, 'Specialization',
                Icons.local_hospital_outlined),
            _field(qualification, 'Qualification', Icons.school_outlined),
            _field(phone, 'Phone', Icons.phone_outlined,
                keyboard: TextInputType.phone),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: loading ? null : submit,
                icon: loading
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.person_add_alt_1_rounded),
                label: Text(
                    loading ? 'Creating doctor...' : 'Create Doctor Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: (value) => requiredText(value, label),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}
