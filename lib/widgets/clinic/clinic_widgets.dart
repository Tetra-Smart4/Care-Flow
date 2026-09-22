import 'package:flutter/material.dart';

class ClinicColors {
  static const background = Color(0xFFF7F9FC);
  static const surface = Colors.white;
  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFE8F1FF);
  static const text = Color(0xFF142033);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE4E7EC);
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFEAF8EF);
  static const warning = Color(0xFFD97706);
  static const warningSoft = Color(0xFFFFF4E5);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFFEDED);
}

class ClinicHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const ClinicHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ClinicColors.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: ClinicColors.muted,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ClinicSectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ClinicSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: ClinicColors.text,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class ClinicStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;

  const ClinicStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tint = ClinicColors.primarySoft,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClinicColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ClinicColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: ClinicColors.primary),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: ClinicColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: ClinicColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return SizedBox(
      height: 145,
      child: onTap == null
          ? card
          : InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: card,
            ),
    );
  }
}

class ClinicSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const ClinicSearchField({
    super.key,
    required this.controller,
    this.hint = 'Search',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                  icon: const Icon(Icons.clear_rounded),
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: ClinicColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: ClinicColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide:
                const BorderSide(color: ClinicColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class ClinicStatusPill extends StatelessWidget {
  final String text;

  const ClinicStatusPill({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final normalized = text.toLowerCase();
    final Color color;
    final Color background;

    if (normalized == 'completed' ||
        normalized == 'confirmed' ||
        normalized == 'active') {
      color = ClinicColors.success;
      background = ClinicColors.successSoft;
    } else if (normalized == 'cancelled' ||
        normalized == 'rejected' ||
        normalized == 'inactive') {
      color = ClinicColors.danger;
      background = ClinicColors.dangerSoft;
    } else {
      color = ClinicColors.warning;
      background = ClinicColors.warningSoft;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.isEmpty ? 'Unknown' : _capitalize(text),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _capitalize(String value) =>
      value.substring(0, 1).toUpperCase() + value.substring(1);
}

class ClinicEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ClinicEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ClinicColors.primarySoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 34, color: ClinicColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ClinicColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ClinicColors.muted, height: 1.4),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ClinicLoadingState extends StatelessWidget {
  const ClinicLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 3),
    );
  }
}
