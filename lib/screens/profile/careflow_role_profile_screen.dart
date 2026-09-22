import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ui/theme/careflow_ui_theme.dart';
import '../../ui/widgets/careflow_profile_components.dart';
import '../auth/login_screen.dart';

class CareFlowRoleProfileScreen extends StatefulWidget {
  final String title;
  final String roleLabel;
  final IconData icon;

  const CareFlowRoleProfileScreen({
    super.key,
    required this.title,
    required this.roleLabel,
    required this.icon,
  });

  @override
  State<CareFlowRoleProfileScreen> createState() =>
      _CareFlowRoleProfileScreenState();
}

class _CareFlowRoleProfileScreenState extends State<CareFlowRoleProfileScreen> {
  final SupabaseClient _db = Supabase.instance.client;

  bool loading = true;
  String? error;
  Map<String, dynamic> profile = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _db.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Your session has expired. Please login again.';
      });
      return;
    }

    try {
      final row =
          await _db.from('profiles').select().eq('id', user.id).maybeSingle();

      if (!mounted) return;

      setState(() {
        profile = row ?? {};
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  String _value(String key, [String fallback = 'Not added']) {
    final value = profile[key];

    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  Future<void> _editProfile() async {
    final user = _db.auth.currentUser;

    if (user == null) return;

    final nameController = TextEditingController(text: _value('full_name', ''));
    final phoneController = TextEditingController(text: _value('phone', ''));
    final addressController =
        TextEditingController(text: _value('address', ''));

    final isPatient = widget.roleLabel.toLowerCase() == 'patient';
    final isClinic = widget.roleLabel.toLowerCase() == 'clinic';

    final ageController = TextEditingController(text: _value('age', ''));
    final genderValue = _value('gender', 'Male');

    String selectedGender = genderValue;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isClinic ? 'Edit Clinic Profile' : 'Edit Profile',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: isClinic ? 'Clinic Name' : 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    if (isPatient) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: [
                          'Male',
                          'Female',
                          'Other',
                        ].contains(selectedGender)
                            ? selectedGender
                            : 'Other',
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.wc_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Male',
                            child: Text('Male'),
                          ),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedGender = value;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      enabled: false,
                      controller: TextEditingController(text: user.email ?? ''),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email is managed by your authentication account.',
                        style: TextStyle(
                          fontSize: 11,
                          color: CareFlowUIColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    try {
                      final updates = <String, dynamic>{
                        'full_name': nameController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'address': addressController.text.trim(),
                      };

                      if (isPatient) {
                        updates['age'] =
                            int.tryParse(ageController.text.trim());
                        updates['gender'] = selectedGender;
                      }

                      if (isClinic) {
                        updates['clinic_name'] = nameController.text.trim();
                      }

                      await _db
                          .from('profiles')
                          .update(updates)
                          .eq('id', user.id);

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext, true);
                    } catch (e) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('Unable to update profile: $e'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    ageController.dispose();

    if (result == true && mounted) {
      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
        ),
      );
    }
  }

  void _showEmailInfo() {
    final email = _db.auth.currentUser?.email ?? 'Not available';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Email address'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 48,
                color: CareFlowUIColors.primary,
              ),
              const SizedBox(height: 14),
              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your email is used for authentication and account access.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showDoctorManagedInfo(String title, String value) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 48,
                color: CareFlowUIColors.primary,
              ),
              const SizedBox(height: 14),
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This information is managed by your clinic.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _CareFlowSettingsScreen(),
      ),
    );
  }

  void _openPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _CareFlowPrivacyScreen(),
      ),
    );
  }

  void _openHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _CareFlowHelpScreen(),
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'Are you sure you want to sign out of CareFlow on this device?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _db.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to sign out: $e'),
        ),
      );
    }
  }

  Widget _info({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: CareFlowUIColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: CareFlowUIColors.softBlue,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: CareFlowUIColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: CareFlowUIColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CareFlowUIColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: CareFlowUIColors.muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logoutTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.red.shade100,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: _signOut,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign out',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Securely sign out from this device',
                        style: TextStyle(
                          color: CareFlowUIColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _db.auth.currentUser;
    final email = user?.email ?? 'Not available';
    final name = _value('full_name', widget.roleLabel);

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 44,
                color: CareFlowUIColors.muted,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load profile',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: CareFlowUIColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CareFlowUIColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.tonal(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: CareFlowUIColors.text,
                  ),
                ),
              ),
              IconButton(
                onPressed: _load,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CareFlowProfileHeader(
            name: name,
            email: email,
            role: widget.roleLabel,
            icon: widget.icon,
          ),
          const SizedBox(height: 20),
          const Text(
            'Personal information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: CareFlowUIColors.text,
            ),
          ),
          const SizedBox(height: 10),
          _info(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
            onTap: _showEmailInfo,
          ),
          _info(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: _value('phone'),
            onTap: _editProfile,
          ),
          if (widget.roleLabel == 'Patient') ...[
            _info(
              icon: Icons.cake_outlined,
              label: 'Age',
              value: _value('age'),
              onTap: _editProfile,
            ),
            _info(
              icon: Icons.wc_outlined,
              label: 'Gender',
              value: _value('gender'),
              onTap: _editProfile,
            ),
            _info(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: _value('address'),
              onTap: _editProfile,
            ),
          ],
          if (widget.roleLabel == 'Doctor') ...[
            _info(
              icon: Icons.medical_services_outlined,
              label: 'Specialization',
              value: _value('specialization'),
              onTap: () {
                _showDoctorManagedInfo(
                  'Specialization',
                  _value('specialization'),
                );
              },
            ),
            _info(
              icon: Icons.school_outlined,
              label: 'Qualification',
              value: _value('qualification'),
              onTap: () {
                _showDoctorManagedInfo(
                  'Qualification',
                  _value('qualification'),
                );
              },
            ),
            _info(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: _value('address'),
              onTap: _editProfile,
            ),
          ],
          if (widget.roleLabel == 'Clinic') ...[
            _info(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: _value('address'),
              onTap: _editProfile,
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: CareFlowUIColors.text,
            ),
          ),
          const SizedBox(height: 10),
          CareFlowProfileTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'App preferences and account options',
            onTap: _openSettings,
          ),
          CareFlowProfileTile(
            icon: Icons.security_outlined,
            title: 'Privacy & security',
            subtitle: 'Manage account security',
            onTap: _openPrivacy,
          ),
          CareFlowProfileTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & support',
            subtitle: 'Get assistance with CareFlow',
            onTap: _openHelp,
          ),
          const SizedBox(height: 8),
          _logoutTile(),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'CareFlow · Connected healthcare',
              style: TextStyle(
                color: CareFlowUIColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SETTINGS
// ---------------------------------------------------------------------------

class _CareFlowSettingsScreen extends StatefulWidget {
  const _CareFlowSettingsScreen();

  @override
  State<_CareFlowSettingsScreen> createState() =>
      _CareFlowSettingsScreenState();
}

class _CareFlowSettingsScreenState extends State<_CareFlowSettingsScreen> {
  bool notifications = true;
  bool reminders = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'App preferences',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              value: notifications,
              onChanged: (value) {
                setState(() => notifications = value);
              },
              title: const Text('Notifications'),
              subtitle: const Text(
                'Receive CareFlow notifications',
              ),
              secondary: const Icon(Icons.notifications_outlined),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: reminders,
              onChanged: (value) {
                setState(() => reminders = value);
              },
              title: const Text('Appointment reminders'),
              subtitle: const Text(
                'Show appointment reminder notifications',
              ),
              secondary: const Icon(Icons.alarm_outlined),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('Refresh account data'),
              subtitle: const Text(
                'Reload your profile information',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PRIVACY & SECURITY
// ---------------------------------------------------------------------------

class _CareFlowPrivacyScreen extends StatelessWidget {
  const _CareFlowPrivacyScreen();

  Future<void> _resetPassword(BuildContext context) async {
    final client = Supabase.instance.client;
    final email = client.auth.currentUser?.email;

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email address is available.'),
        ),
      );
      return;
    }

    try {
      await client.auth.resetPasswordForEmail(email);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset instructions have been sent to your email.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to send reset email: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & security'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Security',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_reset_rounded),
              title: const Text('Change password'),
              subtitle: const Text(
                'Send a secure password reset link',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _resetPassword(context),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Authentication'),
              subtitle: const Text(
                'Your account is secured by Supabase Authentication',
              ),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Authentication'),
                      content: const Text(
                        'CareFlow uses Supabase Authentication to manage your account session securely.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HELP & SUPPORT
// ---------------------------------------------------------------------------

class _CareFlowHelpScreen extends StatelessWidget {
  const _CareFlowHelpScreen();

  void _showHelp(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'How can we help?',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: const Text('Using CareFlow'),
              subtitle: const Text(
                'Learn how the main features work',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _showHelp(
                  context,
                  'Using CareFlow',
                  'Use the bottom navigation to access the features available for your account role. Data is loaded from the CareFlow backend.',
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline_rounded),
              title: const Text('Account & login'),
              subtitle: const Text(
                'Problems signing in or accessing your account',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _showHelp(
                  context,
                  'Account & login',
                  'If you cannot sign in, check your email and password. You can also use the password reset option under Privacy & security.',
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.contact_support_outlined),
              title: const Text('Contact support'),
              subtitle: const Text(
                'Get assistance with CareFlow',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _showHelp(
                  context,
                  'Contact support',
                  'Please contact your CareFlow administrator or clinic support team for assistance.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
