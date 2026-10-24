import 'package:flutter/material.dart';
import '../constants/styles.dart';

/// One sensor value. Pass `value: null` when the device hasn't published a
/// reading; the tile then shows "—" and "No data" instead of a made-up 0.
class SensorTile extends StatelessWidget {
  final String title;

  /// Already formatted (e.g. "0.98"). Null/empty = unavailable.
  final String? value;

  /// Unit exactly as published by the firmware (e.g. "g"). Optional.
  final String? unit;

  final IconData icon;
  final Color color;

  const SensorTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.unit,
  });

  bool get _hasValue => value != null && value!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasValue = _hasValue;
    final unitText = (unit ?? '').trim();

    final spoken = hasValue
        ? '$title: $value${unitText.isEmpty ? '' : ' $unitText'}'
        : '$title: no data available';

    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          // A border stays visible in dark mode; a black shadow doesn't.
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: hasValue ? color : cs.onSurface.withValues(alpha: 0.3),
              size: 30,
            ),

            const SizedBox(height: 10),

            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: hasValue ? value!.trim() : '—',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: hasValue
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  if (hasValue && unitText.isNotEmpty)
                    TextSpan(
                      text: ' $unitText',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            Text(
              title,
              textAlign: TextAlign.center,
              style: AppStyles.bodyMedium.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),

            if (!hasValue) ...[
              const SizedBox(height: 2),
              Text(
                'No data',
                textAlign: TextAlign.center,
                style: AppStyles.bodySmall.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}