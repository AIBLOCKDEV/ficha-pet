import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ficha_pet/providers/auth_provider.dart';
import 'package:ficha_pet/providers/pet_provider.dart';
import 'package:ficha_pet/services/api_service.dart';
import 'package:ficha_pet/utils/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editProfileDialog(
      BuildContext context, AuthProvider auth) async {
    final user = auth.currentUser;
    if (user == null) return;
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.call_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      await auth.updateProfile(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
      );
    }
  }

  Future<void> _serverConfigDialog(BuildContext context) async {
    final api = ApiService();
    final currentUrl = await api.getBaseUrl();
    if (!context.mounted) return;
    final controller = TextEditingController(text: currentUrl);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Servidor Backend y Base de Datos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'URL de la API REST para sincronizar usuarios, mascotas y notificaciones push:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'URL del Servidor API',
                prefixIcon: Icon(Icons.dns_rounded),
                hintText: 'https://tu-dominio.com/api',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await api.setBaseUrl(controller.text);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('URL del servidor actualizada'),
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = Provider.of<AuthProvider>(context);
    final petProvider = Provider.of<PetProvider>(context);
    final user = auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    final initials = user.name.trim().isNotEmpty
        ? user.name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : 'FP';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // Cabecera de perfil Material You
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(
                        user.isVet
                            ? Icons.medical_services_rounded
                            : Icons.pets_rounded,
                        size: 15,
                        color: scheme.onSecondaryContainer,
                      ),
                      backgroundColor: scheme.secondaryContainer,
                      label: Text(
                        user.isVet
                            ? 'Veterinario${user.clinicName.isNotEmpty ? " · ${user.clinicName}" : ""}'
                            : 'Dueño de Mascota',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (user.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.phone,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Editar perfil',
                onPressed: () => _editProfileDialog(context, auth),
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Resumen estadístico del usuario
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                scheme,
                icon: Icons.pets_rounded,
                value: '${petProvider.pets.length}',
                label: 'Mis Mascotas',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                scheme,
                icon: Icons.notifications_active_rounded,
                value: '${petProvider.getReminders().length}',
                label: 'Recordatorios',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Personalización Material You
        Text(
          'Diseño Material You',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Color Dinámico (Paleta Material 3)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < AppTheme.palettes.length; i++)
                      ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor: AppTheme.palettes[i].seedColor,
                          radius: 10,
                        ),
                        label: Text(AppTheme.palettes[i].name),
                        selected: user.themeSeedIndex == i,
                        onSelected: (_) =>
                            auth.updateProfile(themeSeedIndex: i),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Modo de apariencia',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'light',
                      icon: Icon(Icons.light_mode_rounded),
                      label: Text('Claro'),
                    ),
                    ButtonSegment(
                      value: 'dark',
                      icon: Icon(Icons.dark_mode_rounded),
                      label: Text('Oscuro'),
                    ),
                    ButtonSegment(
                      value: 'system',
                      icon: Icon(Icons.brightness_auto_rounded),
                      label: Text('Sistema'),
                    ),
                  ],
                  selected: {user.themeMode},
                  onSelectionChanged: (set) =>
                      auth.updateProfile(themeMode: set.first),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Datos, Servidor y Sesión
        Text(
          'Cuenta, Respaldo y Servidor',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.dns_rounded),
                title: const Text('Configurar servidor y base de datos'),
                subtitle: Text(auth.isServerConnected
                    ? 'Sincronización con servidor activa'
                    : 'Modo local activo (listo para conectar a servidor)'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _serverConfigDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Exportar respaldo JSON de mis mascotas'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  final jsonStr = petProvider.exportBackupJson();
                  Clipboard.setData(ClipboardData(text: jsonStr));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content:
                          Text('Respaldo JSON copiado al portapapeles'),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.logout_rounded, color: scheme.error),
                title: Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                    'Cambiar de usuario o registrar una nueva cuenta'),
                onTap: auth.logout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ColorScheme scheme, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: scheme.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
