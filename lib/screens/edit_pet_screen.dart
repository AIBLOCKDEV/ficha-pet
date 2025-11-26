import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import 'package:ficha_pet/providers/pet_provider.dart';
import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/utils/app_theme.dart';
import 'package:ficha_pet/utils/date_utils.dart' as date_utils;
import 'package:ficha_pet/services/file_service.dart';

class EditPetScreen extends StatefulWidget {
  final int? petIndex;

  const EditPetScreen({super.key, this.petIndex});

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
  String? _petImageBase64;
  String? _vaccineCardBase64;
  final FileService _fileService = FileService();
  bool _isLoading = false;

  Pet? _currentPet;

  @override
  void initState() {
    super.initState();
    if (widget.petIndex != null) {
      _loadPetData();
    }
    _calculateNextVaccineDate();
    _calculateNextDewormingDate();
  }

  void _loadPetData() {
    final provider = Provider.of<PetProvider>(context, listen: false);
    if (widget.petIndex != null && widget.petIndex! < provider.pets.length) {
      _currentPet = provider.pets[widget.petIndex!];
      _nameController.text = _currentPet!.name;
      _birthdayController.text = _currentPet!.birthday;
      _weightController.text = _currentPet!.weight;
      _breedController.text = _currentPet!.breed;
      _vaccineTypeController.text = _currentPet!.vaccineType;
      _lastVaccineDateController.text = _currentPet!.lastVaccineDate;
      _nextVaccineDateController.text = _currentPet!.nextVaccineDate;
      _dewormingProductController.text = _currentPet!.dewormingProduct;
      _lastDewormingDateController.text = _currentPet!.lastDewormingDate;
      _nextDewormingDateController.text = _currentPet!.nextDewormingDate;
      _selectedType = _currentPet!.type;
      _selectedGender = _currentPet!.gender;
      _selectedChip = _currentPet!.chip;
      _petImageBase64 = _currentPet!.files.petImage;
      _vaccineCardBase64 = _currentPet!.files.vaccineCard;
      _emergencyNameController.text = _currentPet!.emergencyContact.name;
      _emergencyPhoneController.text = _currentPet!.emergencyContact.phone;
      _emergencyAddressController.text = _currentPet!.emergencyContact.address;
    }
  }

  void _calculateNextVaccineDate() {
    if (_lastVaccineDateController.text.isNotEmpty) {
      try {
        final lastDate = DateTime.parse(_lastVaccineDateController.text);
        final nextDate = lastDate.add(const Duration(days: 365));
        _nextVaccineDateController.text =
            date_utils.formatDateForInput(nextDate);
      } catch (e) {
        // Ignorar errores de parsing
      }
    }
  }

  void _calculateNextDewormingDate() {
    if (_lastDewormingDateController.text.isNotEmpty) {
      try {
        final lastDate = DateTime.parse(_lastDewormingDateController.text);
        final nextDate = lastDate.add(const Duration(days: 180));
        _nextDewormingDateController.text =
            date_utils.formatDateForInput(nextDate);
      } catch (e) {
        // Ignorar errores de parsing
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source);
      if (image != null) {
        final base64 = await _fileService.imageToBase64(image.path);
        setState(() {
          _petImageBase64 = base64;
        });
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _pickVaccineCard(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source);
      if (image != null) {
        final base64 = await _fileService.imageToBase64(image.path);
        setState(() {
          _vaccineCardBase64 = base64;
        });
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) {
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

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PetProvider>(context, listen: false);
      final pet = Pet(
        id: _currentPet?.id,
        name: _nameController.text,
        type: _selectedType,
        birthday: _birthdayController.text,
        weight: _weightController.text,
        gender: _selectedGender,
        breed: _breedController.text,
        chip: _selectedChip,
        lastVaccineDate: _lastVaccineDateController.text,
        nextVaccineDate: _nextVaccineDateController.text,
        vaccineType: _vaccineTypeController.text,
        lastDewormingDate: _lastDewormingDateController.text,
        nextDewormingDate: _nextDewormingDateController.text,
        dewormingProduct: _dewormingProductController.text,
        medicalHistory: _currentPet?.medicalHistory ?? [],
        weightHistory: _currentPet?.weightHistory ?? [],
        files: PetFiles(
          petImage: _petImageBase64 ?? '',
          vaccineCard: _vaccineCardBase64 ?? '',
          exams: _currentPet?.files.exams ?? [],
        ),
        emergencyContact: EmergencyContact(
          name: _emergencyNameController.text,
          phone: _emergencyPhoneController.text,
          address: _emergencyAddressController.text,
        ),
      );

      if (widget.petIndex != null) {
        await provider.updatePet(widget.petIndex!, pet);
        _showSnackBar('Mascota actualizada correctamente');
      } else {
        await provider.addPet(pet);
        _showSnackBar('Mascota agregada correctamente');
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Error al guardar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthdayController.dispose();
    _weightController.dispose();
    _breedController.dispose();
    _vaccineTypeController.dispose();
    _lastVaccineDateController.dispose();
    _nextVaccineDateController.dispose();
    _dewormingProductController.dispose();
    _lastDewormingDateController.dispose();
    _nextDewormingDateController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.petIndex != null ? 'Editar Mascota' : 'Nueva Mascota'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección Perfil
                    _buildSectionTitle('Perfil'),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => _showImagePickerDialog(true),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _petImageBase64 != null &&
                                  _petImageBase64!.isNotEmpty
                              ? ClipOval(
                                  child: Image.memory(
                                  base64Decode(
                                      _petImageBase64!.split(',').last),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.camera_alt,
                                        size: 50);
                                  },
                                ))
                              : const Icon(Icons.camera_alt, size: 50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la mascota',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Información Básica
                    _buildSectionTitle('Información Básica'),
                    const SizedBox(height: 16),
                    _buildTypeSelector(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _birthdayController,
                            decoration: const InputDecoration(
                              labelText: 'Nacimiento',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                _birthdayController.text =
                                    date_utils.formatDateForInput(date);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildGenderSelector(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _breedController,
                      decoration: const InputDecoration(
                        labelText: 'Raza',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildChipSelector(),
                    const SizedBox(height: 24),

                    // Salud y Prevención
                    _buildSectionTitle('Salud y Prevención'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastVaccineDateController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de última vacuna',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          _lastVaccineDateController.text =
                              date_utils.formatDateForInput(date);
                          _calculateNextVaccineDate();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nextVaccineDateController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de próxima vacuna',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vaccineTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de vacuna',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Carnet de vacunación',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showImagePickerDialog(false),
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _vaccineCardBase64 != null &&
                                _vaccineCardBase64!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(
                                      _vaccineCardBase64!.split(',').last),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.camera_alt,
                                        size: 50);
                                  },
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.camera_alt, size: 50),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _lastDewormingDateController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de última desparasitación',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          _lastDewormingDateController.text =
                              date_utils.formatDateForInput(date);
                          _calculateNextDewormingDate();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nextDewormingDateController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de próxima desparasitación',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dewormingProductController,
                      decoration: const InputDecoration(
                        labelText: 'Producto de desparasitación',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contacto de Emergencia
                    _buildSectionTitle('Contacto de Emergencia'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emergencyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emergencyPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emergencyAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),

                    // Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _savePet,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Guardar'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSelectionButton(
                label: 'Perro',
                icon: Icons.pets,
                value: 'dog',
                selectedValue: _selectedType,
                onTap: () => setState(() => _selectedType = 'dog'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSelectionButton(
                label: 'Gato',
                icon: Icons.pets,
                value: 'cat',
                selectedValue: _selectedType,
                onTap: () => setState(() => _selectedType = 'cat'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sexo', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSelectionButton(
                label: 'Macho',
                icon: Icons.male,
                value: 'male',
                selectedValue: _selectedGender,
                onTap: () => setState(() => _selectedGender = 'male'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSelectionButton(
                label: 'Hembra',
                icon: Icons.female,
                value: 'female',
                selectedValue: _selectedGender,
                onTap: () => setState(() => _selectedGender = 'female'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChipSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Microchip', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSelectionButton(
                label: 'Sí',
                icon: Icons.check,
                value: 'yes',
                selectedValue: _selectedChip,
                onTap: () => setState(() => _selectedChip = 'yes'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSelectionButton(
                label: 'No',
                icon: Icons.close,
                value: 'no',
                selectedValue: _selectedChip,
                onTap: () => setState(() => _selectedChip = 'no'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionButton({
    required String label,
    required IconData icon,
    required String value,
    required String selectedValue,
    required VoidCallback onTap,
  }) {
    final isSelected = value == selectedValue;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerDialog(bool isPetImage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                if (isPetImage) {
                  _pickImage(ImageSource.gallery);
                } else {
                  _pickVaccineCard(ImageSource.gallery);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
