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

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daysDiff = reminder.date.difference(today).inDays;

    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (daysDiff <= 7) {
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[800]!;
      icon = Icons.warning;
    } else if (daysDiff <= 14) {
      backgroundColor = Colors.orange[100]!;
      textColor = Colors.orange[800]!;
      icon = Icons.notifications;
    } else {
      backgroundColor = Colors.blue[100]!;
      textColor = Colors.blue[800]!;
      icon = Icons.calendar_today;
    }

    return Card(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${reminder.type} para ${reminder.pet.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(reminder.date)}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
