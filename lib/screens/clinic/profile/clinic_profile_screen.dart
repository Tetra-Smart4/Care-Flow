import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/clinic_service.dart';
import '../../../widgets/clinic/clinic_widgets.dart';
import '../../auth/login_screen.dart';

class ClinicProfileScreen extends StatefulWidget {
  const ClinicProfileScreen({super.key});

  @override
  State<ClinicProfileScreen> createState() => _ClinicProfileScreenState();
}

class _ClinicProfileScreenState extends State<ClinicProfileScreen> {
  final service = ClinicService();
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();

  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final profile = await service.getClinicProfile();
      if (!mounted) return;
      name.text = '${profile['clinic_name'] ?? ''}';
      phone.text = '${profile['phone'] ?? ''}';
      address.text = '${profile['address'] ?? ''}';
      setState(() => loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) return;
    setState(() => saving = true);
    try {
      await service.updateClinicProfile(
          name: name.text, phone: phone.text, address: address.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
            'You will need to sign in again to access the clinic dashboard.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout')),
        ],
      ),
    );
    if (confirmed != true) return;

    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const ClinicLoadingState();
    if (error != null) {
      return ClinicEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Unable to load profile',
          message: error!,
          onRetry: _load);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        const ClinicHeader(
            title: 'Clinic profile',
            subtitle: 'Keep your clinic information up to date'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF4F8DF7)]),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.local_hospital_rounded,
                      color: Colors.white, size: 28)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(name.text.isEmpty ? 'Clinic' : name.text,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Clinic account',
                        style: TextStyle(color: Colors.white70))
                  ])),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _field(name, 'Clinic name', Icons.local_hospital_outlined),
        _field(phone, 'Phone', Icons.phone_outlined,
            keyboard: TextInputType.phone),
        _field(address, 'Address', Icons.location_on_outlined, maxLines: 3),
        const SizedBox(height: 6),
        SizedBox(
            height: 53,
            child: FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded),
                label: Text(saving ? 'Saving...' : 'Save changes'))),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout')),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboard, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration:
              InputDecoration(labelText: label, prefixIcon: Icon(icon))),
    );
  }
}
