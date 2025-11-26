import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/utils/date_utils.dart';
import 'dart:convert';

class PDFService {
  Future<void> generatePetPDF(Pet pet) async {
    final pdf = pw.Document();

    // Decodificar imágenes base64
    pw.MemoryImage? petImage;
    pw.MemoryImage? vaccineCardImage;

    if (pet.files.petImage.isNotEmpty) {
      try {
        final base64Data = pet.files.petImage.split(',')[1];
        final imageBytes = base64Decode(base64Data);
        petImage = pw.MemoryImage(imageBytes);
      } catch (e) {
        // Ignorar errores de imagen
      }
    }

    if (pet.files.vaccineCard.isNotEmpty) {
      try {
        final base64Data = pet.files.vaccineCard.split(',')[1];
        final imageBytes = base64Decode(base64Data);
        vaccineCardImage = pw.MemoryImage(imageBytes);
      } catch (e) {
        // Ignorar errores de imagen
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Text(
                'Ficha Pet - ${pet.name.isNotEmpty ? pet.name : "Mascota"}',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Imagen de la mascota
            if (petImage != null)
              pw.Center(
                child: pw.ClipOval(
                  child: pw.Image(petImage, width: 150, height: 150),
                ),
              ),
            pw.SizedBox(height: 20),

            // Información Básica
            pw.Header(level: 1, text: 'Información Básica'),
            _buildInfoRow(
                'Nombre', pet.name.isNotEmpty ? pet.name : 'Sin nombre'),
            _buildInfoRow('Tipo', pet.type == 'dog' ? 'Perro' : 'Gato'),
            _buildInfoRow(
                'Raza', pet.breed.isNotEmpty ? pet.breed : 'Sin raza'),
            _buildInfoRow('Sexo', pet.gender == 'male' ? 'Macho' : 'Hembra'),
            if (pet.birthday.isNotEmpty)
              _buildInfoRow('Nacimiento', formatDate(pet.birthday)),
            if (pet.weight.isNotEmpty)
              _buildInfoRow('Peso', '${pet.weight} kg'),
            _buildInfoRow('Microchip', pet.chip == 'yes' ? 'Sí' : 'No'),
            pw.SizedBox(height: 20),

            // Vacunación
            if (pet.lastVaccineDate.isNotEmpty ||
                pet.nextVaccineDate.isNotEmpty ||
                pet.vaccineType.isNotEmpty) ...[
              pw.Header(level: 1, text: 'Vacunación'),
              if (pet.lastVaccineDate.isNotEmpty)
                _buildInfoRow('Última vacuna', formatDate(pet.lastVaccineDate)),
              if (pet.nextVaccineDate.isNotEmpty)
                _buildInfoRow(
                    'Próxima vacuna', formatDate(pet.nextVaccineDate)),
              if (pet.vaccineType.isNotEmpty)
                _buildInfoRow('Tipo de vacuna', pet.vaccineType),
              if (vaccineCardImage != null) ...[
                pw.SizedBox(height: 10),
                pw.Header(level: 2, text: 'Carnet de vacunación'),
                pw.Image(vaccineCardImage, width: 200),
              ],
              pw.SizedBox(height: 20),
            ],

            // Desparasitación
            if (pet.lastDewormingDate.isNotEmpty ||
                pet.nextDewormingDate.isNotEmpty ||
                pet.dewormingProduct.isNotEmpty) ...[
              pw.Header(level: 1, text: 'Desparasitación'),
              if (pet.lastDewormingDate.isNotEmpty)
                _buildInfoRow('Última desparasitación',
                    formatDate(pet.lastDewormingDate)),
              if (pet.nextDewormingDate.isNotEmpty)
                _buildInfoRow('Próxima desparasitación',
                    formatDate(pet.nextDewormingDate)),
              if (pet.dewormingProduct.isNotEmpty)
                _buildInfoRow('Producto', pet.dewormingProduct),
              pw.SizedBox(height: 20),
            ],

            // Historial Médico
            if (pet.medicalHistory.isNotEmpty) ...[
              pw.Header(level: 1, text: 'Historial Médico'),
              ...pet.medicalHistory.map((entry) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          formatDateTime(entry.date),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(entry.text),
                      ],
                    ),
                  )),
              pw.SizedBox(height: 20),
            ],

            // Contacto de Emergencia
            if (pet.emergencyContact.name.isNotEmpty ||
                pet.emergencyContact.phone.isNotEmpty ||
                pet.emergencyContact.address.isNotEmpty) ...[
              pw.Header(level: 1, text: 'Contacto de Emergencia'),
              if (pet.emergencyContact.name.isNotEmpty)
                _buildInfoRow('Nombre', pet.emergencyContact.name),
              if (pet.emergencyContact.phone.isNotEmpty)
                _buildInfoRow('Teléfono', pet.emergencyContact.phone),
              if (pet.emergencyContact.address.isNotEmpty)
                _buildInfoRow('Dirección', pet.emergencyContact.address),
            ],
          ];
        },
      ),
    );

    // Guardar y abrir PDF
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/ficha_pet_${pet.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Abrir el PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }
}
