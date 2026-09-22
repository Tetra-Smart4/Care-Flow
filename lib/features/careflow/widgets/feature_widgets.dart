import 'package:flutter/material.dart';
import '../../../ui/theme/careflow_ui_theme.dart';

class FeatureScaffold extends StatelessWidget {
  const FeatureScaffold(
      {super.key, required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareFlowUIColors.background,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 11, color: CareFlowUIColors.muted)),
        ]),
      ),
      body: SafeArea(child: child),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: CareFlowUIColors.text))),
          if (trailing != null) trailing!,
        ]),
      );
}

class FeatureCard extends StatelessWidget {
  const FeatureCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.color = CareFlowUIColors.softBlue});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: CareFlowUIColors.primary)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: CareFlowUIColors.text)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11,
                            height: 1.3,
                            color: CareFlowUIColors.muted)),
                  ])),
              const Icon(Icons.chevron_right_rounded,
                  color: CareFlowUIColors.muted),
            ]),
          ),
        ),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message,
      this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: CareFlowUIColors.softBlue,
                    borderRadius: BorderRadius.circular(22)),
                child: Icon(icon, size: 34, color: CareFlowUIColors.primary)),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: CareFlowUIColors.muted, height: 1.4)),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ]),
        ),
      );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final color = lower.contains('complete') ||
            lower.contains('paid') ||
            lower.contains('confirmed') ||
            lower.contains('checked')
        ? CareFlowUIColors.success
        : lower.contains('cancel')
            ? CareFlowUIColors.danger
            : CareFlowUIColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(30)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w900, color: color)),
    );
  }
}
