import 'package:flutter/material.dart';
import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/utils/date_utils.dart';
import 'package:ficha_pet/utils/app_theme.dart';

import 'package:provider/provider.dart';
import 'package:ficha_pet/providers/pet_provider.dart';

class MedicalHistoryWidget extends StatefulWidget {
  final Pet pet;

  const MedicalHistoryWidget({super.key, required this.pet});

  @override
  State<MedicalHistoryWidget> createState() => _MedicalHistoryWidgetState();
}

class _MedicalHistoryWidgetState extends State<MedicalHistoryWidget> {
  final TextEditingController _entryController = TextEditingController();

  Future<void> _addEntry() async {
    final text = _entryController.text.trim();
    if (text.isEmpty) return;

    try {
      final provider = Provider.of<PetProvider>(context, listen: false);
      final petIndex = provider.pets.indexWhere((p) => p.id == widget.pet.id);

      if (petIndex != -1) {
        final updatedPet = widget.pet.copyWith(
          medicalHistory: [
            ...widget.pet.medicalHistory,
            MedicalHistoryEntry(
              date: DateTime.now().toIso8601String(),
              text: text,
            ),
          ],
        );
        await provider.updatePet(petIndex, updatedPet);
        _entryController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entrada agregada correctamente')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar entrada: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PetProvider>(
      builder: (context, provider, child) {
        final petIndex = provider.pets.indexWhere((p) => p.id == widget.pet.id);
        final currentPet =
            petIndex != -1 ? provider.pets[petIndex] : widget.pet;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo para agregar nueva entrada
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _entryController,
                        decoration: const InputDecoration(
                          hintText: 'Agregar entrada al historial...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addEntry,
                      icon: const Icon(Icons.add),
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Lista de entradas
                if (currentPet.medicalHistory.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No hay entradas en el historial médico',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                else
                  ...currentPet.medicalHistory.reversed.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatDateTime(entry.date),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.text,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}
