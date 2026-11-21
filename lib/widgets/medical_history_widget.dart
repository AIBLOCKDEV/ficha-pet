import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/providers/auth_provider.dart';
import 'package:ficha_pet/providers/pet_provider.dart';
import 'package:ficha_pet/utils/date_utils.dart';

class MedicalHistoryWidget extends StatefulWidget {
  final Pet pet;

  const MedicalHistoryWidget({super.key, required this.pet});

  @override
  State<MedicalHistoryWidget> createState() => _MedicalHistoryWidgetState();
}

class _MedicalHistoryWidgetState extends State<MedicalHistoryWidget> {
  final TextEditingController _entryController = TextEditingController();
  bool _saving = false;

  Future<void> _save(List<MedicalHistoryEntry> history, String okMsg) async {
    final provider = Provider.of<PetProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await provider.updatePet(widget.pet.copyWith(medicalHistory: history));
      messenger.showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(okMsg)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addEntry() async {
    final rawText = _entryController.text.trim();
    if (rawText.isEmpty || _saving) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final entryText = (user != null && user.isVet)
        ? '[Vet: ${user.name}${user.clinicName.isNotEmpty ? " · ${user.clinicName}" : ""}] $rawText'
        : rawText;

    await _save([
      ...widget.pet.medicalHistory,
      MedicalHistoryEntry(
          date: DateTime.now().toIso8601String(), text: entryText),
    ], 'Entrada agregada y sincronizada');
    if (mounted) _entryController.clear();
  }

  Future<void> _deleteEntry(MedicalHistoryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar entrada'),
        content: const Text('¿Deseas eliminar esta entrada del historial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _save(
      widget.pet.medicalHistory.where((e) => !identical(e, entry)).toList(),
      'Entrada eliminada',
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = Provider.of<AuthProvider>(context);
    final isVet = auth.currentUser?.isVet ?? false;
    final history = widget.pet.medicalHistory;

    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _entryController,
                      decoration: InputDecoration(
                        hintText: isVet
                            ? 'Agregar nota clínica como veterinario...'
                            : 'Ej.: Consulta por alergia, se receta...',
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Agregar entrada',
                    onPressed: _saving ? null : _addEntry,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'No hay entradas en el historial médico',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                )
              else
                ...history.reversed.map((entry) {
                  final isVetEntry = entry.text.startsWith('[Vet:');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
                      decoration: BoxDecoration(
                        color: isVetEntry
                            ? scheme.primaryContainer.withValues(alpha: 0.35)
                            : scheme.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isVetEntry
                              ? scheme.primary.withValues(alpha: 0.4)
                              : scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isVetEntry) ...[
                                      Icon(
                                        Icons.medical_services_rounded,
                                        size: 14,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      formatDateTime(entry.date),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  entry.text,
                                  style: TextStyle(
                                    color: scheme.onSurface,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: scheme.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed:
                                _saving ? null : () => _deleteEntry(entry),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
