import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? child;

  const DashboardCard({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.iconColor,
    this.onTap,
    this.trailing,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        // ignore: deprecated_member_use
                        (iconColor ?? AppColors.primary).withOpacity(0.15),
                    child: Icon(
                      icon,
                      color: iconColor ?? AppColors.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppStyles.cardTitle,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: AppStyles.cardSubtitle,
                          ),
                        ],
                      ],
                    ),
                  ),

                  ...(trailing != null ? [trailing!] : []),
                ],
              ),

              if (child != null) ...[
                const SizedBox(height: 16),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}