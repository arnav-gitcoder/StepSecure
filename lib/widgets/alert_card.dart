import 'package:flutter/material.dart';
import '../constants/styles.dart';

class AlertCard extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final ValueChanged<String>? onMenuSelected;

  const AlertCard({
    super.key,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.color,
    this.onTap,
    this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.cardTitle.copyWith(
                        color: cs.onSurface,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      description,
                      style: AppStyles.cardSubtitle.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      time,
                      style: AppStyles.bodySmall.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                onSelected: onMenuSelected,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'view',
                    child: Text('View Details'),
                  ),
                  PopupMenuItem(
                    value: 'dismiss',
                    child: Text('Dismiss'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}