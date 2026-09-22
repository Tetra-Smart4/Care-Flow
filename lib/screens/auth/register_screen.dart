import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../widgets/careflow_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final age = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();

  String role = 'patient';
  String gender = 'Male';

  bool loading = false;
  bool obscure = true;

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final profile = <String, dynamic>{
        'full_name': name.text.trim(),
        'role': role,
        'phone': phone.text.trim(),
        'address': address.text.trim(),
      };

      if (role == 'patient') {
        profile['age'] = int.tryParse(age.text.trim());
        profile['gender'] = gender;
      }

      if (role == 'clinic') {
        profile['clinic_name'] = name.text.trim();
      }

      final response = await AuthService.signUp(
        email: email.text.trim(),
        password: password.text,
        profile: profile,
      );

      if (!mounted) return;

      if (response.session == null) {
        _message(
          'Account created. Check your email to verify your account, then login.',
        );
      } else {
        _message('Account created successfully. You can login now.');
      }

      Navigator.pop(context);
    } on AuthException catch (e) {
      _message(e.message);
    } catch (e) {
      _message('Registration error: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    age.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = role == 'patient';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              const Center(
                child: CareFlowLogo(),
              ),

              const SizedBox(height: 14),

              Text(
                'CareFlow Registration',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 24),

              // ROLE
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(
                  labelText: 'Register as',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'patient',
                    child: Text('Patient'),
                  ),
                  DropdownMenuItem(
                    value: 'clinic',
                    child: Text('Clinic'),
                  ),
                ],
                onChanged: loading
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => role = value);
                      },
              ),

              const SizedBox(height: 16),

              // NAME
              TextFormField(
                controller: name,
                decoration: InputDecoration(
                  labelText: isPatient ? 'Full Name' : 'Clinic Name',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // EMAIL
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || !v.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // PASSWORD
              TextFormField(
                controller: password,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => obscure = !obscure);
                    },
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return 'Minimum 6 characters';
                  }
                  return null;
                },
              ),

              // PATIENT ONLY
              if (isPatient) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: age,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: gender,
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
                  onChanged: loading
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() => gender = v);
                        },
                ),
              ],

              const SizedBox(height: 16),

              // PHONE
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),

              const SizedBox(height: 16),

              // ADDRESS
              TextFormField(
                controller: address,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: loading ? null : register,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
