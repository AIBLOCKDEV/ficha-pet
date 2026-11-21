import 'package:flutter/material.dart';
import 'package:ficha_pet/providers/pet_provider.dart';
import 'package:intl/intl.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onTap;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onTap,
  });

  String get _statusText {
    final days = reminder.daysLeft;
    if (days < 0) {
      final abs = -days;
      return abs == 1 ? 'Vencida hace 1 día' : 'Vencida hace $abs días';
    }
    if (days == 0) return 'Es hoy';
    if (days == 1) return 'Mañana';
    return 'En $days días';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final daysDiff = reminder.daysLeft;

    final Color containerColor;
    final Color onContainerColor;
    final IconData icon;

    if (daysDiff < 0) {
      containerColor = scheme.errorContainer;
      onContainerColor = scheme.onErrorContainer;
      icon = Icons.notification_important_rounded;
    } else if (daysDiff <= 7) {
      containerColor = scheme.tertiaryContainer;
      onContainerColor = scheme.onTertiaryContainer;
      icon = Icons.warning_amber_rounded;
    } else {
      containerColor = scheme.secondaryContainer;
      onContainerColor = scheme.onSecondaryContainer;
      icon = Icons.event_available_rounded;
    }

    final petName =
        reminder.pet.name.isNotEmpty ? reminder.pet.name : 'tu mascota';

    return Card(
      color: containerColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: onContainerColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: onContainerColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${reminder.type} · $petName',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: onContainerColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(reminder.date)} · $_statusText',
                      style: TextStyle(
                        color: onContainerColor.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: onContainerColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            reminder.isOverdue
                                ? Icons.repeat_rounded
                                : Icons.notifications_active_rounded,
                            size: 13,
                            color: onContainerColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reminder.pushCadenceBadge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: onContainerColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: onContainerColor),
            ],
          ),
        ),
      ),
    );
  }
}
