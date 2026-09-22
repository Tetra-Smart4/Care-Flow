import 'package:flutter/material.dart';

const Color careBlue = Color(0xFF2563EB);
const Color careGreen = Color(0xFF16B97A);
const Color careInk = Color(0xFF132B59);
const Color careMuted = Color(0xFF64748B);
const Color careBg = Color(0xFFF7FAFC);

class CareFlowAuthBackground extends StatelessWidget {
  const CareFlowAuthBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FBFF),
            Color(0xFFF3FAF7),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _GlowCircle(
              size: 220,
              color: Color(0x222563EB),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _GlowCircle(
              size: 250,
              color: Color(0x2216B97A),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class CareFlowBrand extends StatelessWidget {
  const CareFlowBrand({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 58.0 : 76.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(compact ? 18 : 22),
            boxShadow: const [
              BoxShadow(
                blurRadius: 28,
                offset: Offset(0, 12),
                color: Color(0x1A1D3E68),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 14 : 17),
            child: Image.asset(
              'assets/images/careflow_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [careBlue, careGreen],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 18),
          const Text(
            'CareFlow',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              color: careInk,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Your care, connected.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: careMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class CareFlowRoleSelector extends StatelessWidget {
  const CareFlowRoleSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const roles = [
    _RoleData('patient', 'Patient', Icons.person_rounded),
    _RoleData('doctor', 'Doctor', Icons.medical_services_rounded),
    _RoleData('clinic', 'Clinic', Icons.local_hospital_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6F1)),
      ),
      child: Row(
        children: [
          for (final role in roles)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(role.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        value == role.value ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: value == role.value
                        ? const [
                            BoxShadow(
                              blurRadius: 14,
                              offset: Offset(0, 5),
                              color: Color(0x121D3E68),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        role.icon,
                        size: 20,
                        color: value == role.value ? careBlue : careMuted,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        role.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: value == role.value ? careInk : careMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoleData {
  const _RoleData(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;
}

InputDecoration careFlowAuthFieldDecoration({
  required String label,
  required IconData icon,
  Widget? suffixIcon,
  String? helperText,
}) {
  return InputDecoration(
    labelText: label,
    helperText: helperText,
    helperStyle: const TextStyle(
      color: careMuted,
      fontSize: 11.5,
    ),
    prefixIcon: Icon(
      icon,
      color: careBlue,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 17,
      vertical: 17,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(
        color: Color(0xFFDCE5EE),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(
        color: Color(0xFFDCE5EE),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(
        color: careBlue,
        width: 1.5,
      ),
    ),
  );
}

class CareFlowPrimaryButton extends StatelessWidget {
  const CareFlowPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: careBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB8C7E0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          elevation: 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  key: const ValueKey('label'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}
