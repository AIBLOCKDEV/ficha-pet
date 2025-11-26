import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ficha_pet/providers/pet_provider.dart';
import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/screens/edit_pet_screen.dart';
import 'package:ficha_pet/utils/app_theme.dart';
import 'package:ficha_pet/utils/date_utils.dart';
import 'package:ficha_pet/widgets/weight_chart.dart';
import 'package:ficha_pet/widgets/medical_history_widget.dart';
import 'package:ficha_pet/services/pdf_service.dart';
import 'package:ficha_pet/services/qr_service.dart';

class ViewPetScreen extends StatelessWidget {
  final int petIndex;

  const ViewPetScreen({super.key, required this.petIndex});

  @override
  Widget build(BuildContext context) {
    return Consumer<PetProvider>(
      builder: (context, provider, child) {
        if (petIndex >= provider.pets.length) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Mascota no encontrada')),
          );
        }

        final pet = provider.pets[petIndex];
        return Scaffold(
          appBar: AppBar(
            title: Text(pet.name.isNotEmpty ? pet.name : 'Mascota'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditPetScreen(petIndex: petIndex),
                    ),
                  );
                },
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf),
                        SizedBox(width: 8),
                        Text('Exportar PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'qr',
                    child: Row(
                      children: [
                        Icon(Icons.qr_code),
                        SizedBox(width: 8),
                        Text('Ver QR'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'export') {
                    await _exportToPDF(context, pet);
                  } else if (value == 'qr') {
                    await _showQRCode(context, pet);
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen de la mascota
                Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey[300]!, width: 3),
                    ),
                    child: pet.files.petImage.isNotEmpty
                        ? ClipOval(
                            child: Image.memory(
                              base64Decode(pet.files.petImage.split(',').last),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  pet.type == 'dog' ? Icons.pets : Icons.pets,
                                  size: 80,
                                  color: Colors.grey[400],
                                );
                              },
                            ),
                          )
                        : Icon(
                            pet.type == 'dog' ? Icons.pets : Icons.pets,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Información Básica
                _buildSectionTitle('Información Básica'),
                const SizedBox(height: 16),
                _buildInfoCard([
                  _buildInfoRow(
                      'Nombre', pet.name.isNotEmpty ? pet.name : 'Sin nombre'),
                  _buildInfoRow('Tipo', pet.type == 'dog' ? 'Perro' : 'Gato'),
                  _buildInfoRow(
                      'Raza', pet.breed.isNotEmpty ? pet.breed : 'Sin raza'),
                  _buildInfoRow(
                      'Sexo', pet.gender == 'male' ? 'Macho' : 'Hembra'),
                  if (pet.birthday.isNotEmpty)
                    _buildInfoRow('Nacimiento', formatDate(pet.birthday)),
                  if (pet.weight.isNotEmpty)
                    _buildInfoRow('Peso', '${pet.weight} kg'),
                  _buildInfoRow('Microchip', pet.chip == 'yes' ? 'Sí' : 'No'),
                ]),
                const SizedBox(height: 24),

                // Vacunación
                if (pet.lastVaccineDate.isNotEmpty ||
                    pet.nextVaccineDate.isNotEmpty ||
                    pet.vaccineType.isNotEmpty) ...[
                  _buildSectionTitle('Vacunación'),
                  const SizedBox(height: 16),
                  _buildInfoCard([
                    if (pet.lastVaccineDate.isNotEmpty)
                      _buildInfoRow(
                          'Última vacuna', formatDate(pet.lastVaccineDate)),
                    if (pet.nextVaccineDate.isNotEmpty)
                      _buildInfoRow(
                          'Próxima vacuna', formatDate(pet.nextVaccineDate)),
                    if (pet.vaccineType.isNotEmpty)
                      _buildInfoRow('Tipo de vacuna', pet.vaccineType),
                  ]),
                  if (pet.files.vaccineCard.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Carnet de vacunación',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(pet.files.vaccineCard.split(',').last),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(child: Icon(Icons.image)),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],

                // Desparasitación
                if (pet.lastDewormingDate.isNotEmpty ||
                    pet.nextDewormingDate.isNotEmpty ||
                    pet.dewormingProduct.isNotEmpty) ...[
                  _buildSectionTitle('Desparasitación'),
                  const SizedBox(height: 16),
                  _buildInfoCard([
                    if (pet.lastDewormingDate.isNotEmpty)
                      _buildInfoRow('Última desparasitación',
                          formatDate(pet.lastDewormingDate)),
                    if (pet.nextDewormingDate.isNotEmpty)
                      _buildInfoRow('Próxima desparasitación',
                          formatDate(pet.nextDewormingDate)),
                    if (pet.dewormingProduct.isNotEmpty)
                      _buildInfoRow('Producto', pet.dewormingProduct),
                  ]),
                  const SizedBox(height: 24),
                ],

                // Historial de peso
                if (pet.weightHistory.isNotEmpty) ...[
                  _buildSectionTitle('Historial de Peso'),
                  const SizedBox(height: 16),
                  WeightChart(weightHistory: pet.weightHistory),
                  const SizedBox(height: 24),
                ],

                // Historial médico
                _buildSectionTitle('Historial Médico'),
                const SizedBox(height: 16),
                MedicalHistoryWidget(pet: pet),
                const SizedBox(height: 24),

                // Contacto de emergencia
                if (pet.emergencyContact.name.isNotEmpty ||
                    pet.emergencyContact.phone.isNotEmpty ||
                    pet.emergencyContact.address.isNotEmpty) ...[
                  _buildSectionTitle('Contacto de Emergencia'),
                  const SizedBox(height: 16),
                  _buildInfoCard([
                    if (pet.emergencyContact.name.isNotEmpty)
                      _buildInfoRow('Nombre', pet.emergencyContact.name),
                    if (pet.emergencyContact.phone.isNotEmpty)
                      _buildInfoRow(
                        'Teléfono',
                        pet.emergencyContact.phone,
                        trailing: IconButton(
                          icon: const Icon(Icons.phone),
                          onPressed: () async {
                            final uri =
                                Uri.parse('tel:${pet.emergencyContact.phone}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                      ),
                    if (pet.emergencyContact.address.isNotEmpty)
                      _buildInfoRow('Dirección', pet.emergencyContact.address),
                  ]),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        );
      },
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

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Future<void> _exportToPDF(BuildContext context, Pet pet) async {
    try {
      final pdfService = PDFService();
      await pdfService.generatePetPDF(pet);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exportado correctamente')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar PDF: $e')),
        );
      }
    }
  }

  Future<void> _showQRCode(BuildContext context, Pet pet) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código QR'),
        content: QRService.generateQRCode(pet),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
