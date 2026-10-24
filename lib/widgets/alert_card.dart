import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

class AlertCard extends StatelessWidget {
  /// Values passed to [onMenuSelected].
  static const String actionView = 'view';
  static const String actionAcknowledge = 'acknowledge';

  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color color;

  /// Acknowledged/resolved alerts hide the "Acknowledge" action.
  final bool isAcknowledged;

  /// Text shown in the status chip so state is never conveyed by color
  /// alone. Defaults to "Acknowledged" / "Unacknowledged".
  final String? statusLabel;

  final VoidCallback? onTap;
  final ValueChanged<String>? onMenuSelected;

  const AlertCard({
    super.key,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.color,
    this.isAcknowledged = false,
    this.statusLabel,
    this.onTap,
    this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final label =
        statusLabel ?? (isAcknowledged ? 'Acknowledged' : 'Unacknowledged');
    final chipColor = isAcknowledged ? AppColors.success : color;
    final chipIcon =
        isAcknowledged ? Icons.check_circle_outline : Icons.error_outline;

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

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: AppStyles.cardSubtitle.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: chipColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(chipIcon, size: 14, color: chipColor),
                              const SizedBox(width: 4),
                              Text(
                                label,
                                style: AppStyles.bodySmall.copyWith(
                                  color: chipColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          time,
                          style: AppStyles.bodySmall.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                tooltip: 'More options',
                onSelected: onMenuSelected,
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: actionView,
                    child: Text('View Details'),
                  ),
                  if (!isAcknowledged)
                    const PopupMenuItem<String>(
                      value: actionAcknowledge,
                      child: Text('Acknowledge'),
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