import 'package:flutter/material.dart';

import '../../services/logout_service.dart';
import '../theme/careflow_ui_theme.dart';

class CareFlowProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final IconData icon;

  const CareFlowProfileHeader({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.icon,
  });

  String _initials() {
    final clean = name.trim();

    if (clean.isEmpty) return 'CF';

    final parts = clean.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CareFlowUIColors.primary,
            CareFlowUIColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.85),
            size: 27,
          ),
        ],
      ),
    );
  }
}

class CareFlowProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;

  const CareFlowProfileTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? CareFlowUIColors.danger : CareFlowUIColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: danger
              ? CareFlowUIColors.danger.withValues(alpha: 0.14)
              : CareFlowUIColors.border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: danger ? color : CareFlowUIColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: CareFlowUIColors.muted,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: danger ? color : CareFlowUIColors.muted,
        ),
        onTap: onTap,
      ),
    );
  }
}

class CareFlowLogoutTile extends StatelessWidget {
  const CareFlowLogoutTile({super.key});

  @override
  Widget build(BuildContext context) {
    return CareFlowProfileTile(
      icon: Icons.logout_rounded,
      title: 'Sign out',
      subtitle: 'Securely sign out from this device',
      danger: true,
      onTap: () async {
        final confirmed = await showCareFlowLogoutSheet(context);

        if (!confirmed || !context.mounted) return;

        await signOutCareFlow(context);
      },
    );
  }
}
