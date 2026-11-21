import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ficha_pet/providers/auth_provider.dart';
import 'package:ficha_pet/providers/pet_provider.dart';
import 'package:ficha_pet/screens/edit_pet_screen.dart';
import 'package:ficha_pet/screens/notifications_screen.dart';
import 'package:ficha_pet/screens/profile_screen.dart';
import 'package:ficha_pet/screens/view_pet_screen.dart';
import 'package:ficha_pet/utils/app_theme.dart';
import 'package:ficha_pet/widgets/pet_card.dart';
import 'package:ficha_pet/widgets/reminder_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _query = '';
  int _selectedTab = 0;

  void _openPet(int? id) {
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ViewPetScreen(petId: id)),
    );
  }

  void _editPet(int? id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditPetScreen(petId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Consumer<PetProvider>(
      builder: (context, provider, child) {
        final unreadCount = provider.unreadPushCount;
        final activeReminders = provider.getReminders();

        // Mostrar banner in-app cuando se dispara una nueva notificación push
        if (provider.latestTriggered.isNotEmpty) {
          final latest = provider.latestTriggered.first;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            provider.consumeLatestTriggered();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 6),
                backgroundColor: latest.isOverdue
                    ? scheme.errorContainer
                    : scheme.inverseSurface,
                content: Row(
                  children: [
                    Icon(
                      latest.isOverdue
                          ? Icons.notification_important_rounded
                          : Icons.notifications_active_rounded,
                      color: latest.isOverdue
                          ? scheme.onErrorContainer
                          : scheme.onInverseSurface,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latest.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: latest.isOverdue
                                  ? scheme.onErrorContainer
                                  : scheme.onInverseSurface,
                            ),
                          ),
                          Text(
                            latest.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: latest.isOverdue
                                  ? scheme.onErrorContainer
                                  : scheme.onInverseSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                action: SnackBarAction(
                  label: 'Ver',
                  textColor: latest.isOverdue
                      ? scheme.onErrorContainer
                      : scheme.inversePrimary,
                  onPressed: () => _openPet(latest.petId),
                ),
              ),
            );
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo_mark.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.pets_rounded,
                      size: 24,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ficha Pet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (user != null)
                        Text(
                          user.isVet
                              ? 'Veterinario · ${user.name}'
                              : 'Hola, ${user.name}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Cambio rápido Modo Claro / Oscuro
              IconButton(
                tooltip: Theme.of(context).brightness == Brightness.dark
                    ? 'Cambiar a modo claro'
                    : 'Cambiar a modo oscuro',
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                onPressed: () {
                  final nextMode =
                      Theme.of(context).brightness == Brightness.dark
                          ? 'light'
                          : 'dark';
                  auth.updateProfile(themeMode: nextMode);
                },
              ),
              // Selector rápido de color Material You
              IconButton(
                tooltip: 'Cambiar color Material You',
                icon: const Icon(Icons.palette_rounded),
                onPressed: () {
                  final nextIndex = ((user?.themeSeedIndex ?? 0) + 1) %
                      AppTheme.palettes.length;
                  auth.updateProfile(themeSeedIndex: nextIndex);
                },
              ),
              // Campana de notificaciones push con contador
              IconButton(
                tooltip: 'Centro de Notificaciones Push',
                onPressed: () => setState(() => _selectedTab = 1),
                icon: Badge(
                  isLabelVisible:
                      unreadCount > 0 || activeReminders.isNotEmpty,
                  label: Text(
                    '${unreadCount > 0 ? unreadCount : activeReminders.length}',
                  ),
                  child: const Icon(Icons.notifications_rounded),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opciones y respaldo',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) => _handleMenuAction(context, value),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'sample',
                    child: ListTile(
                      leading: Icon(Icons.auto_awesome_rounded),
                      title: Text('Cargar mascota de ejemplo (Rocky)'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      leading: Icon(Icons.download_rounded),
                      title: Text('Exportar respaldo JSON'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'import',
                    child: ListTile(
                      leading: Icon(Icons.upload_rounded),
                      title: Text('Importar respaldo JSON'),
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout_rounded),
                      title: Text('Cerrar sesión'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedTab,
            children: [
              _buildPetsTab(context, provider, scheme),
              const NotificationsScreen(),
              const ProfileScreen(),
            ],
          ),
          floatingActionButton: _selectedTab == 0
              ? (user?.isVet == true
                  ? FloatingActionButton.extended(
                      onPressed: () =>
                          _showVetQRScannerDialog(context, provider),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Escanear QR'),
                    )
                  : FloatingActionButton.extended(
                      onPressed: () => _editPet(null),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Agregar Mascota'),
                    ))
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (idx) =>
                setState(() => _selectedTab = idx),
            destinations: [
              NavigationDestination(
                icon: Icon(user?.isVet == true
                    ? Icons.medical_services_outlined
                    : Icons.pets_outlined),
                selectedIcon: Icon(user?.isVet == true
                    ? Icons.medical_services_rounded
                    : Icons.pets_rounded),
                label: user?.isVet == true
                    ? 'Pacientes (${provider.pets.length})'
                    : 'Mascotas (${provider.pets.length})',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible:
                      unreadCount > 0 || activeReminders.isNotEmpty,
                  label: Text(
                    '${unreadCount > 0 ? unreadCount : activeReminders.length}',
                  ),
                  child: const Icon(Icons.notifications_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible:
                      unreadCount > 0 || activeReminders.isNotEmpty,
                  label: Text(
                    '${unreadCount > 0 ? unreadCount : activeReminders.length}',
                  ),
                  child: const Icon(Icons.notifications_active_rounded),
                ),
                label: 'Alertas Push',
              ),
              const NavigationDestination(
                icon: Icon(Icons.account_circle_outlined),
                selectedIcon: Icon(Icons.account_circle_rounded),
                label: 'Mi Perfil',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPetsTab(
    BuildContext context,
    PetProvider provider,
    ColorScheme scheme,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final reminders = provider.getReminders();
    final query = _query.trim().toLowerCase();
    final pets = query.isEmpty
        ? provider.pets
        : provider.pets
            .where((p) =>
                p.name.toLowerCase().contains(query) ||
                p.breed.toLowerCase().contains(query))
            .toList();

    return RefreshIndicator(
      onRefresh: provider.loadPets,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          if (provider.isActiveUserVet) ...[
            _buildVetBanner(context, provider, scheme),
            const SizedBox(height: 18),
          ],
          if (reminders.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recordatorios Importantes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedTab = 1),
                  icon: const Icon(Icons.notifications_active_rounded, size: 18),
                  label: const Text('Configurar Push'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...reminders.map((reminder) => ReminderCard(
                  reminder: reminder,
                  onTap: () => _openPet(reminder.pet.id),
                )),
            const SizedBox(height: 20),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                provider.isActiveUserVet
                    ? 'Pacientes Vinculados (${provider.pets.length})'
                    : 'Mis Mascotas (${provider.pets.length})',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          if (provider.pets.length > 2) ...[
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o raza',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ],
          const SizedBox(height: 14),
          if (provider.pets.isEmpty)
            _buildEmptyState(provider, scheme)
          else if (pets.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No hay mascotas que coincidan con la búsqueda',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1100
                    ? 3
                    : constraints.maxWidth >= 700
                        ? 2
                        : 1;
                const spacing = 12.0;
                final itemWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: pets
                      .map((pet) => SizedBox(
                            width: itemWidth,
                            child: PetCard(
                              pet: pet,
                              onTap: () => _openPet(pet.id),
                              onEdit: () => _editPet(pet.id),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(BuildContext context, String action) async {
    final provider = Provider.of<PetProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    switch (action) {
      case 'sample':
        await provider.addSamplePet();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Se cargó la mascota de ejemplo "Rocky"'),
            ),
          );
        }
      case 'export':
        final jsonStr = provider.exportBackupJson();
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Exportar respaldo JSON'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 360),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonStr,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jsonStr));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('JSON copiado al portapapeles')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copiar JSON'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      case 'import':
        final controller = TextEditingController();
        final rawJson = await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Importar respaldo JSON'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: TextField(
                controller: controller,
                minLines: 5,
                maxLines: 12,
                decoration: const InputDecoration(
                  hintText:
                      'Pega aquí el contenido de Ficha Pet.json o tu respaldo...',
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, controller.text.trim()),
                child: const Text('Importar'),
              ),
            ],
          ),
        );
        if (rawJson == null || rawJson.isEmpty || !context.mounted) return;
        try {
          final count = await provider.importBackupJson(rawJson);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Se importaron $count mascota(s)')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al importar JSON: $e')),
            );
          }
        }
      case 'logout':
        await auth.logout();
    }
  }

  Widget _buildVetBanner(
    BuildContext context,
    PetProvider provider,
    ColorScheme scheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer,
            scheme.tertiaryContainer,
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
                  Icons.qr_code_scanner_rounded,
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
                      'Panel Veterinario',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Escanea el QR de la mascota para vincular su historia clínica con sincronización bidireccional.',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            scheme.onPrimaryContainer.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _showVetQRScannerDialog(context, provider),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Escanear QR / Ingresar Código'),
          ),
        ],
      ),
    );
  }

  Future<void> _showVetQRScannerDialog(
    BuildContext context,
    PetProvider provider,
  ) async {
    final controller = TextEditingController();
    final scheme = Theme.of(context).colorScheme;
    final quickPets = provider.unlinkedPetsInDevice;

    final scannedInput = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded),
            SizedBox(width: 10),
            Expanded(child: Text('Escanear QR Clínico')),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pega el contenido del QR escaneado o ingresa el código clínico (ej. FP-557584) que aparece en la ficha del dueño:',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Código clínico o texto QR',
                    hintText: 'Ej.: FP-557584',
                    prefixIcon: Icon(Icons.qr_code_2_rounded),
                  ),
                ),
                if (quickPets.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Mascotas detectadas listas para vincular (demo QR):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...quickPets.map(
                    (p) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: scheme.secondaryContainer,
                        foregroundColor: scheme.onSecondaryContainer,
                        child: const Icon(Icons.pets_rounded, size: 18),
                      ),
                      title: Text(p.name.isNotEmpty ? p.name : 'Mascota'),
                      subtitle: Text('${p.breed} · ${p.shareCode}'),
                      trailing: FilledButton.tonal(
                        onPressed: () =>
                            Navigator.pop(dialogContext, p.shareCode),
                        child: const Text('Vincular'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            icon: const Icon(Icons.link_rounded, size: 18),
            label: const Text('Vincular Paciente'),
          ),
        ],
      ),
    );

    if (scannedInput == null || scannedInput.isEmpty || !context.mounted) {
      return;
    }

    try {
      final linkedPet = await provider.linkPetByQR(scannedInput);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Paciente "${linkedPet.name}" vinculado con sincronización bidireccional',
          ),
        ),
      );
      _openPet(linkedPet.id);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Bad state: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(msg),
        ),
      );
    }
  }

  Widget _buildEmptyState(PetProvider provider, ColorScheme scheme) {
    if (provider.isActiveUserVet) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 56,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Aún no tienes pacientes vinculados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Escanea el código QR clínico de una mascota para acceder a su historial y sincronizar cambios automáticamente con su dueño.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => _showVetQRScannerDialog(context, provider),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Escanear QR / Vincular Paciente'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets_rounded,
                size: 56,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No tienes mascotas registradas en tu perfil',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primera mascota o carga a Rocky para probar los recordatorios push con anticipación y cada 2 días en vacunas vencidas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 22),
            FilledButton.tonalIcon(
              onPressed: provider.addSamplePet,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Cargar mascota de ejemplo (Rocky)'),
            ),
          ],
        ),
      ),
    );
  }
}
