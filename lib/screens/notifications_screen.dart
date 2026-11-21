import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ficha_pet/providers/auth_provider.dart';
import 'package:ficha_pet/providers/pet_provider.dart';
import 'package:ficha_pet/screens/view_pet_screen.dart';
import 'package:ficha_pet/services/notification_service.dart';
import 'package:ficha_pet/utils/date_utils.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _openPet(BuildContext context, int? petId) {
    if (petId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ViewPetScreen(petId: petId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = Provider.of<AuthProvider>(context);
    final petProvider = Provider.of<PetProvider>(context);
    final user = auth.currentUser;

    final schedule = petProvider.schedulePreview;
    final inbox = petProvider.pushInbox;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // Tarjeta de estado y reglas de Notificaciones Push
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primaryContainer,
                scheme.secondaryContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: scheme.onPrimary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Motor de Notificaciones Push',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Anticipación: ${user?.advanceDays ?? 14} días antes · Vencidas: repetición cada 2 días',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onPrimaryContainer
                                .withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: user?.pushEnabled ?? true,
                    onChanged: (v) async {
                      await auth.updateProfile(pushEnabled: v);
                      await petProvider.setActiveUser(auth.currentUser);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      final count = await petProvider.triggerPushCheckNow();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            count > 0
                                ? 'Se enviaron $count notificación(es) push ahora'
                                : 'No hay vacunas pendientes o vencidas en este momento',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_to_mobile_rounded, size: 18),
                    label: const Text('Enviar / Probar Push ahora'),
                  ),
                  for (final days in [7, 14, 30])
                    ChoiceChip(
                      label: Text('Anticipar $days d'),
                      selected: (user?.advanceDays ?? 14) == days,
                      onSelected: (_) async {
                        await auth.updateProfile(advanceDays: days);
                        await petProvider.setActiveUser(auth.currentUser);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Programación activa
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alertas Programadas (${schedule.length})',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            Badge(
              backgroundColor: scheme.errorContainer,
              textColor: scheme.onErrorContainer,
              label: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text('Vencidas: cada 48 h'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (schedule.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 48,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Todas las vacunas y desparasitaciones están al día',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recibirás alertas push automáticas ${user?.advanceDays ?? 14} días antes de cada fecha, y cada 2 días si alguna llega a vencerse.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          )
        else
          ...schedule.map(
            (item) => _buildScheduleCard(context, scheme, item),
          ),

        const SizedBox(height: 24),

        // Bandeja de notificaciones enviadas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Historial Push Enviado (${inbox.length})',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            if (inbox.isNotEmpty)
              Row(
                children: [
                  TextButton.icon(
                    onPressed: petProvider.markAllNotificationsRead,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Leídas'),
                  ),
                  IconButton(
                    tooltip: 'Limpiar historial',
                    onPressed: petProvider.clearNotifications,
                    icon: const Icon(Icons.delete_sweep_rounded),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (inbox.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Aún no hay notificaciones registradas en el historial. Pulsa "Enviar / Probar Push ahora" para disparar las alertas activas.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ...inbox.map(
            (item) => Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: item.isOverdue
                      ? scheme.errorContainer
                      : scheme.primaryContainer,
                  foregroundColor: item.isOverdue
                      ? scheme.onErrorContainer
                      : scheme.onPrimaryContainer,
                  child: Icon(
                    item.isOverdue
                        ? Icons.notification_important_rounded
                        : Icons.notifications_rounded,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight:
                              item.isRead ? FontWeight.w600 : FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(item.body),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        Text(
                          item.cadenceLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: item.isOverdue
                                ? scheme.error
                                : scheme.primary,
                          ),
                        ),
                        Text(
                          '· ${formatDateTime(item.createdAt.toIso8601String())}',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () => _openPet(context, item.petId),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScheduleCard(
    BuildContext context,
    ColorScheme scheme,
    PushNotificationItem item,
  ) {
    final isOverdue = item.isOverdue;
    final containerColor =
        isOverdue ? scheme.errorContainer : scheme.secondaryContainer;
    final onContainerColor =
        isOverdue ? scheme.onErrorContainer : scheme.onSecondaryContainer;

    return Card(
      color: containerColor.withValues(alpha: 0.65),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openPet(context, item.petId),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isOverdue
                      ? Icons.replay_circle_filled_rounded
                      : Icons.event_available_rounded,
                  color: onContainerColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: onContainerColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: onContainerColor.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: onContainerColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOverdue
                                ? Icons.repeat_rounded
                                : Icons.schedule_rounded,
                            size: 14,
                            color: onContainerColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.cadenceLabel,
                            style: TextStyle(
                              fontSize: 12,
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
