import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ficha_pet/providers/pet_provider.dart';
import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/utils/date_utils.dart' as date_utils;
import 'package:ficha_pet/utils/pet_labels.dart';
import 'package:ficha_pet/widgets/base64_image.dart';

class EditPetScreen extends StatefulWidget {
  /// `null` para crear una mascota nueva.
  final int? petId;

  const EditPetScreen({super.key, this.petId});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _weightController = TextEditingController();
  final _breedController = TextEditingController();
  final _vaccineTypeController = TextEditingController();
  final _lastVaccineDateController = TextEditingController();
  final _nextVaccineDateController = TextEditingController();
  final _dewormingProductController = TextEditingController();
  final _lastDewormingDateController = TextEditingController();
  final _nextDewormingDateController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyAddressController = TextEditingController();

  String _selectedType = '';
  String _selectedGender = '';
  String _selectedChip = '';
  String _petImageBase64 = '';
  String _vaccineCardBase64 = '';
  bool _isSaving = false;

  Pet? _currentPet;

  bool get _isEditing => widget.petId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadPetData();
  }

  void _loadPetData() {
    final provider = Provider.of<PetProvider>(context, listen: false);
    final pet = provider.getPetById(widget.petId);
    if (pet == null) return;
    _currentPet = pet;
    _nameController.text = pet.name;
    _birthdayController.text = pet.birthday;
    _weightController.text = pet.weight;
    _breedController.text = pet.breed;
    _vaccineTypeController.text = pet.vaccineType;
    _lastVaccineDateController.text = pet.lastVaccineDate;
    _nextVaccineDateController.text = pet.nextVaccineDate;
    _dewormingProductController.text = pet.dewormingProduct;
    _lastDewormingDateController.text = pet.lastDewormingDate;
    _nextDewormingDateController.text = pet.nextDewormingDate;
    _selectedType = pet.type;
    _selectedGender = pet.gender;
    _selectedChip = pet.chip;
    _petImageBase64 = pet.files.petImage;
    _vaccineCardBase64 = pet.files.vaccineCard;
    _emergencyNameController.text = pet.emergencyContact.name;
    _emergencyPhoneController.text = pet.emergencyContact.phone;
    _emergencyAddressController.text = pet.emergencyContact.address;
  }

  /// Propone la próxima fecha sumando [days] a la última.
  void _suggestNextDate(
      TextEditingController last, TextEditingController next, int days) {
    final lastDate = DateTime.tryParse(last.text);
    if (lastDate == null) return;
    next.text =
        date_utils.formatDateForInput(lastDate.add(Duration(days: days)));
  }

  Future<void> _pickDate(
    TextEditingController controller, {
    required DateTime firstDate,
    required DateTime lastDate,
    VoidCallback? onPicked,
  }) async {
    final current = DateTime.tryParse(controller.text);
    var initial = current ?? DateTime.now();
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date != null) {
      setState(() {
        controller.text = date_utils.formatDateForInput(date);
        onPicked?.call();
      });
    }
  }

  Future<void> _pickImage(ImageSource source, {required bool isPetImage}) async {
    try {
      final picker = ImagePicker();
      // Se reduce tamaño/calidad para no saturar el almacenamiento local.
      final image = await picker.pickImage(
        source: source,
        maxWidth: isPetImage ? 800 : 1600,
        maxHeight: isPetImage ? 800 : 1600,
        imageQuality: 80,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final name = image.name.toLowerCase();
      final mime = image.mimeType ??
          (name.endsWith('.png')
              ? 'image/png'
              : name.endsWith('.webp')
                  ? 'image/webp'
                  : 'image/jpeg');
      final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
      setState(() {
        if (isPetImage) {
          _petImageBase64 = dataUri;
        } else {
          _vaccineCardBase64 = dataUri;
        }
      });
    } catch (e) {
      _showSnackBar('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Revisa los campos marcados en rojo');
      return;
    }
    if (_selectedType.isEmpty) {
      _showSnackBar('Por favor selecciona el tipo de mascota');
      return;
    }
    if (_selectedGender.isEmpty) {
      _showSnackBar('Por favor selecciona el sexo');
      return;
    }
    if (_selectedChip.isEmpty) {
      _showSnackBar('Por favor selecciona si tiene microchip');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<PetProvider>(context, listen: false);
      final pet = Pet(
        id: _currentPet?.id,
        ownerId: _currentPet?.ownerId ?? '',
        linkedVetIds: List.of(_currentPet?.linkedVetIds ?? []),
        name: _nameController.text.trim(),
        type: _selectedType,
        birthday: _birthdayController.text,
        weight: _weightController.text.trim().replaceAll(',', '.'),
        gender: _selectedGender,
        breed: _breedController.text.trim(),
        chip: _selectedChip,
        lastVaccineDate: _lastVaccineDateController.text,
        nextVaccineDate: _nextVaccineDateController.text,
        vaccineType: _vaccineTypeController.text.trim(),
        lastDewormingDate: _lastDewormingDateController.text,
        nextDewormingDate: _nextDewormingDateController.text,
        dewormingProduct: _dewormingProductController.text.trim(),
        medicalHistory: List.of(_currentPet?.medicalHistory ?? []),
        weightHistory: List.of(_currentPet?.weightHistory ?? []),
        files: PetFiles(
          petImage: _petImageBase64,
          vaccineCard: _vaccineCardBase64,
          exams: List.of(_currentPet?.files.exams ?? []),
        ),
        emergencyContact: EmergencyContact(
          name: _emergencyNameController.text.trim(),
          phone: _emergencyPhoneController.text.trim(),
          address: _emergencyAddressController.text.trim(),
        ),
      );

      if (_isEditing && _currentPet != null) {
        await provider.updatePet(pet);
      } else {
        await provider.addPet(pet);
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
        content: Text(_isEditing
            ? 'Mascota actualizada correctamente'
            : 'Mascota agregada correctamente'),
      ));
    } catch (e) {
      _showSnackBar('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _birthdayController,
      _weightController,
      _breedController,
      _vaccineTypeController,
      _lastVaccineDateController,
      _nextVaccineDateController,
      _dewormingProductController,
      _lastDewormingDateController,
      _nextDewormingDateController,
      _emergencyNameController,
      _emergencyPhoneController,
      _emergencyAddressController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Mascota' : 'Nueva Mascota'),
      ),
      body: AbsorbPointer(
        absorbing: _isSaving,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Perfil'),
                    const SizedBox(height: 16),
                    Center(child: _buildProfileImage()),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la mascota *',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Información Básica'),
                    const SizedBox(height: 16),
                    _buildSelector(
                      title: 'Tipo *',
                      selected: _selectedType,
                      options: [
                        ('dog', 'Perro', petTypeIcon('dog')),
                        ('cat', 'Gato', petTypeIcon('cat')),
                      ],
                      onChanged: (v) => setState(() => _selectedType = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildDateField(
                            controller: _birthdayController,
                            label: 'Nacimiento',
                            onTap: () => _pickDate(
                              _birthdayController,
                              firstDate: DateTime(1990),
                              lastDate: now,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            decoration: const InputDecoration(
                              labelText: 'Peso (kg)',
                              suffixText: 'kg',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]')),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              final w = double.tryParse(
                                  value.trim().replaceAll(',', '.'));
                              if (w == null || w <= 0 || w > 200) {
                                return 'Peso no válido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSelector(
                      title: 'Sexo *',
                      selected: _selectedGender,
                      options: const [
                        ('male', 'Macho', Icons.male),
                        ('female', 'Hembra', Icons.female),
                      ],
                      onChanged: (v) => setState(() => _selectedGender = v),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _breedController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Raza'),
                    ),
                    const SizedBox(height: 16),
                    _buildSelector(
                      title: 'Microchip *',
                      selected: _selectedChip,
                      options: const [
                        ('yes', 'Sí', Icons.check),
                        ('no', 'No', Icons.close),
                      ],
                      onChanged: (v) => setState(() => _selectedChip = v),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Vacunación'),
                    const SizedBox(height: 16),
                    _buildDateField(
                      controller: _lastVaccineDateController,
                      label: 'Fecha de última vacuna',
                      onTap: () => _pickDate(
                        _lastVaccineDateController,
                        firstDate: DateTime(2000),
                        lastDate: now,
                        onPicked: () => _suggestNextDate(
                            _lastVaccineDateController,
                            _nextVaccineDateController,
                            365),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(
                      controller: _nextVaccineDateController,
                      label: 'Fecha de próxima vacuna',
                      helper: 'Se propone 1 año después; puedes cambiarla',
                      onTap: () => _pickDate(
                        _nextVaccineDateController,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(now.year + 5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vaccineTypeController,
                      decoration:
                          const InputDecoration(labelText: 'Tipo de vacuna'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Carnet de vacunación',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _buildVaccineCard(),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Desparasitación'),
                    const SizedBox(height: 16),
                    _buildDateField(
                      controller: _lastDewormingDateController,
                      label: 'Fecha de última desparasitación',
                      onTap: () => _pickDate(
                        _lastDewormingDateController,
                        firstDate: DateTime(2000),
                        lastDate: now,
                        onPicked: () => _suggestNextDate(
                            _lastDewormingDateController,
                            _nextDewormingDateController,
                            180),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(
                      controller: _nextDewormingDateController,
                      label: 'Fecha de próxima desparasitación',
                      helper: 'Se propone 6 meses después; puedes cambiarla',
                      onTap: () => _pickDate(
                        _nextDewormingDateController,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(now.year + 5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dewormingProductController,
                      decoration: const InputDecoration(
                          labelText: 'Producto de desparasitación'),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Contacto de Emergencia'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emergencyNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emergencyPhoneController,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+\-\s()]')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final digits = value.replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 7) return 'Teléfono no válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emergencyAddressController,
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _savePet,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Guardando...' : 'Guardar'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showImagePickerDialog(isPetImage: true),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surfaceContainerHighest,
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: ClipOval(
              child: Base64Image(
                source: _petImageBase64,
                placeholder: Icon(
                  Icons.camera_alt_rounded,
                  size: 46,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        if (_petImageBase64.isNotEmpty)
          Positioned(
            right: 0,
            top: 0,
            child: _removeButton(() => setState(() => _petImageBase64 = '')),
          ),
      ],
    );
  }

  Widget _buildVaccineCard() {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showImagePickerDialog(isPetImage: false),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Base64Image(
                source: _vaccineCardBase64,
                fit: BoxFit.contain,
                placeholder: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded,
                          size: 44, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 6),
                      Text('Toca para agregar una foto',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_vaccineCardBase64.isNotEmpty)
          Positioned(
            right: 6,
            top: 6,
            child:
                _removeButton(() => setState(() => _vaccineCardBase64 = '')),
          ),
      ],
    );
  }

  Widget _removeButton(VoidCallback onPressed) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        tooltip: 'Quitar imagen',
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.close_rounded, size: 18, color: scheme.onErrorContainer),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    String? helper,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        prefixIcon: const Icon(Icons.event_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Borrar fecha',
                icon: const Icon(Icons.clear_rounded),
                onPressed: () => setState(() => controller.clear()),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
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

  Widget _buildSelector({
    required String title,
    required String selected,
    required List<(String, String, IconData)> options,
    required ValueChanged<String> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _buildSelectionButton(
                  label: options[i].$2,
                  icon: options[i].$3,
                  isSelected: options[i].$1 == selected,
                  onTap: () => onChanged(options[i].$1),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? scheme.primaryContainer
              : scheme.surfaceContainerLow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerDialog({required bool isPetImage}) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera, isPetImage: isPetImage);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery, isPetImage: isPetImage);
              },
            ),
          ],
        ),
      ),
    );
  }
}
