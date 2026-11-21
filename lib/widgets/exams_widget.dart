import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/providers/pet_provider.dart';
import 'package:ficha_pet/widgets/base64_image.dart';

class ExamsWidget extends StatefulWidget {
  final Pet pet;

  const ExamsWidget({super.key, required this.pet});

  @override
  State<ExamsWidget> createState() => _ExamsWidgetState();
}

class _ExamsWidgetState extends State<ExamsWidget> {
  bool _saving = false;

  Future<void> _addExam() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (image == null || !mounted) return;

      final nameController = TextEditingController(text: image.name);
      final customName = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Nombre del examen o documento'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Ej.: Hemograma 2026, Radiografía...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, nameController.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
      if (customName == null || !mounted) return;

      setState(() => _saving = true);
      final bytes = await image.readAsBytes();
      final lower = image.name.toLowerCase();
      final mime = image.mimeType ??
          (lower.endsWith('.png')
              ? 'image/png'
              : lower.endsWith('.webp')
                  ? 'image/webp'
                  : 'image/jpeg');
      final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';

      final newExam = ExamFile(
        name: customName.isEmpty ? image.name : customName,
        type: mime,
        data: dataUri,
      );

      if (!mounted) return;
      final provider = Provider.of<PetProvider>(context, listen: false);
      final updatedFiles = PetFiles(
        petImage: widget.pet.files.petImage,
        vaccineCard: widget.pet.files.vaccineCard,
        exams: [...widget.pet.files.exams, newExam],
      );
      await provider.updatePet(widget.pet.copyWith(files: updatedFiles));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Examen adjuntado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al adjuntar examen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteExam(ExamFile exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar examen'),
        content: Text('¿Deseas eliminar "${exam.name}"?'),
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

    setState(() => _saving = true);
    try {
      final provider = Provider.of<PetProvider>(context, listen: false);
      final updatedFiles = PetFiles(
        petImage: widget.pet.files.petImage,
        vaccineCard: widget.pet.files.vaccineCard,
        exams:
            widget.pet.files.exams.where((e) => !identical(e, exam)).toList(),
      );
      await provider.updatePet(widget.pet.copyWith(files: updatedFiles));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _previewExam(ExamFile exam) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      exam.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                maxScale: 5,
                child: Base64Image(
                  source: exam.data,
                  fit: BoxFit.contain,
                  placeholder: const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Vista previa no disponible para este formato'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final exams = widget.pet.files.exams;

    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Archivos adjuntos (${exams.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _addExam,
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('Adjuntar imagen'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (exams.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'No hay exámenes o recetas adjuntas',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                )
              else
                ...exams.map((exam) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.insert_drive_file_rounded,
                          color: scheme.primary),
                      title: Text(
                        exam.name,
                        style: TextStyle(color: scheme.onSurface),
                      ),
                      onTap: () => _previewExam(exam),
                      trailing: IconButton(
                        tooltip: 'Eliminar',
                        icon: Icon(Icons.delete_outline_rounded,
                            color: scheme.onSurfaceVariant, size: 20),
                        onPressed: _saving ? null : () => _deleteExam(exam),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
