import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ficha_pet/providers/auth_provider.dart';
import 'package:ficha_pet/providers/pet_provider.dart';
import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/screens/edit_pet_screen.dart';
import 'package:ficha_pet/utils/date_utils.dart';
import 'package:ficha_pet/utils/pet_labels.dart';
import 'package:ficha_pet/widgets/base64_image.dart';
import 'package:ficha_pet/widgets/weight_chart.dart';
import 'package:ficha_pet/widgets/medical_history_widget.dart';
import 'package:ficha_pet/widgets/exams_widget.dart';
import 'package:ficha_pet/widgets/care_assistant_widget.dart';
import 'package:ficha_pet/services/pdf_service.dart';
import 'package:ficha_pet/services/qr_service.dart';

class ViewPetScreen extends StatelessWidget {
  final int petId;

  const ViewPetScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = Provider.of<AuthProvider>(context);
    final isVet = auth.currentUser?.isVet ?? false;

    return Consumer<PetProvider>(
      builder: (context, provider, child) {
        final pet = provider.getPetById(petId);
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mascota')),
            body: const Center(child: Text('Mascota no encontrada')),
          );
        }

        final age = petAgeLabel(pet.birthday);
        final isLinkedPatient = isVet && pet.ownerId != auth.currentUser?.id;

        return Scaffold(
          appBar: AppBar(
            title: Text(pet.name.isNotEmpty ? pet.name : 'Mascota'),
            actions: [
              IconButton(
                tooltip: 'Código QR Clínico',
                icon: const Icon(Icons.qr_code_2_rounded),
                onPressed: () => _showQRCode(context, pet),
              ),
              IconButton(
                tooltip: 'Editar ficha',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditPetScreen(petId: petId),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf_rounded),
                      title: Text('Exportar PDF'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'qr',
                    child: ListTile(
                      leading: Icon(Icons.qr_code_2_rounded),
                      title: Text('Ver QR Clínico'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        isLinkedPatient
                            ? Icons.link_off_rounded
                            : Icons.delete_rounded,
                        color: scheme.error,
                      ),
                      title: Text(
                        isLinkedPatient ? 'Desvincular paciente' : 'Eliminar',
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  ),
                ],
                onSelected: (value) async {
                  switch (value) {
                    case 'export':
                      await _exportToPDF(context, pet);
                    case 'qr':
                      _showQRCode(context, pet);
                    case 'delete':
                      await _confirmDelete(
                        context,
                        provider,
                        pet,
                        isLinkedPatient: isLinkedPatient,
                      );
                  }
                },
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 740),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.primaryContainer
                                  .withValues(alpha: 0.65),
                              border: Border.all(
                                color: scheme.outlineVariant,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: Base64Image(
                                source: pet.files.petImage,
                                placeholder: Icon(
                                  petTypeIcon(pet.type),
                                  size: 72,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              ActionChip(
                                avatar: Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 16,
                                  color: scheme.primary,
                                ),
                                label: Text('Código clínico: ${pet.shareCode}'),
                                onPressed: () => _showQRCode(context, pet),
                              ),
                              if (pet.linkedVetIds.isNotEmpty)
                                Chip(
                                  avatar: Icon(
                                    Icons.sync_rounded,
                                    size: 16,
                                    color: scheme.onTertiaryContainer,
                                  ),
                                  backgroundColor: scheme.tertiaryContainer,
                                  label: Text(
                                    isLinkedPatient
                                        ? 'Paciente vinculado · Sync activo'
                                        : 'Compartida con ${pet.linkedVetIds.length} vet.',
                                    style: TextStyle(
                                      color: scheme.onTertiaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle(context, 'Información Básica'),
                    const SizedBox(height: 12),
                    _buildInfoCard([
                      _buildInfoRow(context, 'Nombre',
                          pet.name.isNotEmpty ? pet.name : 'Sin nombre'),
                      _buildInfoRow(context, 'Tipo', petTypeLabel(pet.type)),
                      _buildInfoRow(context, 'Raza',
                          pet.breed.isNotEmpty ? pet.breed : 'Sin raza'),
                      _buildInfoRow(context, 'Sexo', petGenderLabel(pet.gender)),
                      if (pet.birthday.isNotEmpty)
                        _buildInfoRow(
                          context,
                          'Nacimiento',
                          age.isEmpty
                              ? formatDate(pet.birthday)
                              : '${formatDate(pet.birthday)} ($age)',
                        ),
                      if (pet.weight.isNotEmpty)
                        _buildInfoRow(context, 'Peso', '${pet.weight} kg'),
                      _buildInfoRow(
                          context, 'Microchip', petChipLabel(pet.chip)),
                    ]),
                    const SizedBox(height: 24),

                    if (pet.lastVaccineDate.isNotEmpty ||
                        pet.nextVaccineDate.isNotEmpty ||
                        pet.vaccineType.isNotEmpty ||
                        pet.files.vaccineCard.isNotEmpty) ...[
                      _buildSectionTitle(context, 'Vacunación'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        if (pet.lastVaccineDate.isNotEmpty)
                          _buildInfoRow(context, 'Última vacuna',
                              formatDate(pet.lastVaccineDate)),
                        if (pet.nextVaccineDate.isNotEmpty)
                          _buildInfoRow(context, 'Próxima vacuna',
                              formatDate(pet.nextVaccineDate)),
                        if (pet.vaccineType.isNotEmpty)
                          _buildInfoRow(
                              context, 'Tipo de vacuna', pet.vaccineType),
                        if (pet.files.vaccineCard.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Carnet de vacunación',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () =>
                                _showFullImage(context, pet.files.vaccineCard),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Base64Image(
                                source: pet.files.vaccineCard,
                                fit: BoxFit.contain,
                                placeholder: Container(
                                  height: 200,
                                  color: scheme.surfaceContainerHighest,
                                  child: Center(
                                    child: Icon(
                                      Icons.image_rounded,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 24),
                    ],

                    if (pet.lastDewormingDate.isNotEmpty ||
                        pet.nextDewormingDate.isNotEmpty ||
                        pet.dewormingProduct.isNotEmpty) ...[
                      _buildSectionTitle(context, 'Desparasitación'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        if (pet.lastDewormingDate.isNotEmpty)
                          _buildInfoRow(context, 'Última desparasitación',
                              formatDate(pet.lastDewormingDate)),
                        if (pet.nextDewormingDate.isNotEmpty)
                          _buildInfoRow(context, 'Próxima desparasitación',
                              formatDate(pet.nextDewormingDate)),
                        if (pet.dewormingProduct.isNotEmpty)
                          _buildInfoRow(
                              context, 'Producto', pet.dewormingProduct),
                      ]),
                      const SizedBox(height: 24),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle(context, 'Historial de Peso'),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showAddWeightDialog(context, provider, pet),
                          icon: const Icon(Icons.monitor_weight_rounded,
                              size: 18),
                          label: const Text('Registrar peso'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    WeightChart(weightHistory: pet.weightHistory),
                    const SizedBox(height: 24),

                    _buildSectionTitle(context, 'Historial Médico'),
                    const SizedBox(height: 12),
                    MedicalHistoryWidget(pet: pet),
                    const SizedBox(height: 24),

                    _buildSectionTitle(context, 'Exámenes y Documentos'),
                    const SizedBox(height: 12),
                    ExamsWidget(pet: pet),
                    const SizedBox(height: 24),

                    _buildSectionTitle(context, 'Asistente de Cuidado'),
                    const SizedBox(height: 12),
                    CareAssistantWidget(pet: pet),
                    const SizedBox(height: 24),

                    if (pet.emergencyContact.name.isNotEmpty ||
                        pet.emergencyContact.phone.isNotEmpty ||
                        pet.emergencyContact.address.isNotEmpty) ...[
                      _buildSectionTitle(context, 'Contacto de Emergencia'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        if (pet.emergencyContact.name.isNotEmpty)
                          _buildInfoRow(
                              context, 'Nombre', pet.emergencyContact.name),
                        if (pet.emergencyContact.phone.isNotEmpty)
                          _buildInfoRow(
                            context,
                            'Teléfono',
                            pet.emergencyContact.phone,
                            trailing: IconButton.filledTonal(
                              tooltip: 'Llamar',
                              icon: const Icon(Icons.call_rounded),
                              onPressed: () =>
                                  _call(context, pet.emergencyContact.phone),
                            ),
                          ),
                        if (pet.emergencyContact.address.isNotEmpty)
                          _buildInfoRow(context, 'Dirección',
                              pet.emergencyContact.address),
                      ]),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _call(BuildContext context, String phone) async {
    final uri =
        Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar la llamada')),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PetProvider provider,
    Pet pet, {
    required bool isLinkedPatient,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isLinkedPatient
            ? 'Desvincular paciente'
            : 'Eliminar mascota'),
        content: Text(
          isLinkedPatient
              ? '¿Deseas quitar a ${pet.name} de tu lista de pacientes? El dueño conservará su ficha intacta.'
              : '¿Seguro que deseas eliminar a ${pet.name.isNotEmpty ? pet.name : 'esta mascota'}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isLinkedPatient ? 'Desvincular' : 'Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await provider.deletePet(pet.id!);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(isLinkedPatient
              ? 'Paciente desvinculado de tu lista'
              : 'Mascota eliminada'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showFullImage(BuildContext context, String source) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 5,
              child: Base64Image(
                source: source,
                fit: BoxFit.contain,
                placeholder: const SizedBox(height: 200),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton.filledTonal(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Widget? trailing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Future<void> _showAddWeightDialog(
      BuildContext context, PetProvider provider, Pet pet) async {
    final controller = TextEditingController(text: pet.weight);
    final newWeight = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registrar nuevo peso'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Peso (kg)',
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value =
                  double.tryParse(controller.text.trim().replaceAll(',', '.'));
              if (value != null && value > 0 && value <= 200) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (newWeight == null || !context.mounted) return;
    await provider.updatePet(pet.copyWith(weight: newWeight.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Peso actualizado y sincronizado'),
        ),
      );
    }
  }

  Future<void> _exportToPDF(BuildContext context, Pet pet) async {
    try {
      await PDFService().generatePetPDF(pet);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar PDF: $e')),
        );
      }
    }
  }

  void _showQRCode(BuildContext context, Pet pet) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_2_rounded),
            SizedBox(width: 10),
            Expanded(child: Text('QR Clínico Ficha Pet')),
          ],
        ),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QRService.generateQRCode(pet),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Código: ${pet.shareCode}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 1.1,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tu veterinario puede escanear este QR desde su app Ficha Pet (o ingresar el código ${pet.shareCode}) para ver y actualizar la historia clínica en sincronización bidireccional.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pet.shareCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Código ${pet.shareCode} copiado'),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copiar código'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
