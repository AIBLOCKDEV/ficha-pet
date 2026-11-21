import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/utils/date_utils.dart';
import 'package:ficha_pet/utils/pet_labels.dart';

class CareAssistantWidget extends StatelessWidget {
  final Pet pet;

  const CareAssistantWidget({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Herramientas rápidas de análisis y consulta preventiva',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildActionChip(
                    scheme,
                    icon: Icons.insights_rounded,
                    label: 'Analizar Historial',
                    onTap: () => _showResultModal(
                      context,
                      title: 'Análisis de Historial — ${pet.name}',
                      content: _buildHistoryAnalysis(),
                    ),
                  ),
                  _buildActionChip(
                    scheme,
                    icon: Icons.menu_book_rounded,
                    label: 'Guía de Cuidado',
                    onTap: () => _showResultModal(
                      context,
                      title: 'Guía de Cuidado — ${pet.name}',
                      content: _buildCareGuide(),
                    ),
                  ),
                  _buildActionChip(
                    scheme,
                    icon: Icons.medical_services_rounded,
                    label: 'Analizar Síntomas',
                    onTap: () => _showInputModal(
                      context,
                      title: 'Analizar Síntomas',
                      hint:
                          'Ej.: Vómito desde ayer, decaimiento, pérdida de apetito...',
                      onSubmit: _evaluateSymptoms,
                    ),
                  ),
                  _buildActionChip(
                    scheme,
                    icon: Icons.restaurant_rounded,
                    label: '¿Puede comer esto?',
                    onTap: () => _showInputModal(
                      context,
                      title: '¿Puede comer esto?',
                      hint:
                          'Ej.: chocolate, uva, cebolla, pollo, manzana, zanahoria...',
                      onSubmit: _evaluateFood,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip(
    ColorScheme scheme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: scheme.onSecondaryContainer),
      label: Text(
        label,
        style: TextStyle(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: scheme.secondaryContainer.withValues(alpha: 0.7),
      side: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
      ),
      onPressed: onTap,
    );
  }

  String _buildHistoryAnalysis() {
    final buffer = StringBuffer();
    final species = petTypeLabel(pet.type);
    final age = petAgeLabel(pet.birthday);

    buffer.writeln('RESUMEN CLÍNICO DE ${pet.name.toUpperCase()}');
    buffer.writeln(
        '• Especie: $species${pet.breed.isNotEmpty ? " (${pet.breed})" : ""}');
    if (age.isNotEmpty) buffer.writeln('• Edad actual: $age');
    if (pet.weight.isNotEmpty) buffer.writeln('• Peso actual: ${pet.weight} kg');
    buffer.writeln(
        '• Microchip: ${petChipLabel(pet.chip)}${pet.chip == "no" ? " (se recomienda colocarlo)" : ""}');
    buffer.writeln();

    // Estado de vacunas y desparasitación
    buffer.writeln('PREVENCIÓN:');
    buffer.writeln(_checkDateStatus('Vacunación', pet.nextVaccineDate,
        detail: pet.vaccineType));
    buffer.writeln(_checkDateStatus('Desparasitación', pet.nextDewormingDate,
        detail: pet.dewormingProduct));
    buffer.writeln();

    // Tendencia de peso
    if (pet.weightHistory.length >= 2) {
      final sorted = List<WeightHistoryEntry>.from(pet.weightHistory)
        ..sort((a, b) => a.date.compareTo(b.date));
      final first = sorted.first.weight;
      final last = sorted.last.weight;
      final diff = last - first;
      final sign = diff >= 0 ? '+' : '';
      buffer.writeln('EVOLUCIÓN DE PESO:');
      buffer.writeln(
          '• ${sorted.length} registros: de ${first.toStringAsFixed(1)} kg a ${last.toStringAsFixed(1)} kg ($sign${diff.toStringAsFixed(1)} kg).');
      buffer.writeln();
    }

    // Historial médico
    buffer.writeln('HISTORIAL MÉDICO (${pet.medicalHistory.length} entradas):');
    if (pet.medicalHistory.isEmpty) {
      buffer.writeln('• Aún no hay consultas registradas en el historial.');
    } else {
      for (final entry in pet.medicalHistory.reversed.take(5)) {
        buffer.writeln('• [${formatDateTime(entry.date)}] ${entry.text}');
      }
    }

    buffer.writeln();
    buffer.writeln(
        'Nota: Este resumen es orientativo y no reemplaza el diagnóstico de un médico veterinario.');
    return buffer.toString();
  }

  String _checkDateStatus(String label, String dateStr, {String detail = ''}) {
    if (dateStr.isEmpty) {
      return '• $label: Sin fecha próxima registrada.';
    }
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '• $label: $dateStr';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final days = target.difference(today).inDays;
    final extra = detail.isNotEmpty ? ' ($detail)' : '';
    if (days < 0) {
      return '• $label$extra: VENCIDA el ${formatDate(dateStr)} (hace ${-days} días).';
    } else if (days <= 30) {
      return '• $label$extra: Próxima el ${formatDate(dateStr)} (en $days días).';
    }
    return '• $label$extra: Al día (próxima el ${formatDate(dateStr)}).';
  }

  String _buildCareGuide() {
    final isCat = pet.type == 'cat';
    final species = isCat ? 'gato' : 'perro';
    final breed = pet.breed.isNotEmpty ? ' (${pet.breed})' : '';
    final age = petAgeLabel(pet.birthday);

    return '''
GUÍA DE CUIDADO PARA ${pet.name.toUpperCase()} ($species$breed${age.isNotEmpty ? ", $age" : ""})

1. Alimentación e Hidratación
• Proporciona alimento balanceado de calidad acorde a su etapa de vida${pet.weight.isNotEmpty ? " y peso actual (${pet.weight} kg)" : ""}.
• Mantén agua fresca y limpia disponible las 24 horas${isCat ? " (los gatos suelen preferir fuentes de agua en movimiento)" : ""}.

2. Actividad y Enriquecimiento
• ${isCat ? "Sesiones diarias de juego vertical, rascadores y caza simulada (20-30 min/día)." : "Paseos diarios y socialización (30-60 min/día según energía y edad)."}
• Controla el peso periódicamente en la sección de Evolución de Peso.

3. Salud Preventiva
• Vacunación anual al día (${pet.nextVaccineDate.isNotEmpty ? "próxima: ${formatDate(pet.nextVaccineDate)}" : "pendiente de registrar"}).
• Desparasitación interna y externa periódica (${pet.nextDewormingDate.isNotEmpty ? "próxima: ${formatDate(pet.nextDewormingDate)}" : "pendiente de registrar"}).
• Higiene dental regular y revisión de oídos, pelaje y uñas.
''';
  }

  String _evaluateSymptoms(String input) {
    final lower = input.toLowerCase();
    final urgentKeywords = [
      'sangre',
      'convulsi',
      'respira',
      'ahog',
      'veneno',
      'tóxic',
      'toxic',
      'desmay',
      'inconsciente',
      'no se mueve',
      'hinchado',
      'trauma',
      'atropell',
    ];
    final isUrgent = urgentKeywords.any(lower.contains);
    final species = petTypeLabel(pet.type).toLowerCase();

    return '''
EVALUACIÓN ORIENTATIVA DE SÍNTOMAS (${pet.name} · $species)

Síntomas reportados:
"$input"

1. Nivel de atención sugerido:
${isUrgent ? "URGENCIA VETERINARIA INMEDIATA — Acude a una clínica de urgencias hoy mismo." : "CONSULTA VETERINARIA RECOMENDADA — Agenda revisión si persiste más de 24 h o empeora."}

2. Qué observar y registrar en el Historial Médico:
• Frecuencia y duración exacta de los síntomas.
• Si toma agua, come con normalidad y su nivel de energía.
• Cambios recientes en dieta, premios, plantas o productos del hogar.

3. Primeros cuidados:
• Mantén agua fresca disponible y un ambiente tranquilo.
• No administres medicamentos de uso humano (paracetamol, ibuprofeno, etc. son altamente tóxicos).

Importante: Esta guía no sustituye una valoración veterinaria presencial.
''';
  }

  String _evaluateFood(String input) {
    final lower = input.trim().toLowerCase();
    final isCat = pet.type == 'cat';
    final species = isCat ? 'gatos' : 'perros';

    const toxicFoods = <String, String>{
      'chocolate':
          'TÓXICO (Alto riesgo): Contiene teobromina y cafeína. Puede causar vómitos, taquicardia y convulsiones.',
      'cacao':
          'TÓXICO (Alto riesgo): Contiene teobromina, peligrosa para el corazón y el sistema nervioso.',
      'uva':
          'TÓXICO (Alto riesgo): Las uvas y pasas pueden provocar insuficiencia renal aguda.',
      'pasa':
          'TÓXICO (Alto riesgo): Las pasas y uvas pueden provocar insuficiencia renal aguda.',
      'cebolla':
          'TÓXICO: Daña los glóbulos rojos y puede causar anemia hemolítica.',
      'ajo':
          'TÓXICO: Pertenece a la familia Allium y puede causar daño oxidativo a los glóbulos rojos.',
      'xilitol':
          'TÓXICO (Emergencia): Edulcorante que provoca hipoglucemia severa y daño hepático.',
      'aguacate':
          'NO RECOMENDADO: Contiene persina y alto contenido graso; el hueso representa riesgo de obstrucción.',
      'palta':
          'NO RECOMENDADO: Contiene persina y alto contenido graso; el hueso representa riesgo de obstrucción.',
      'alcohol': 'TÓXICO (Emergencia): Extremadamente peligroso.',
      'café': 'TÓXICO: La cafeína afecta el sistema nervioso y cardíaco.',
      'cafe': 'TÓXICO: La cafeína afecta el sistema nervioso y cardíaco.',
      'macadamia':
          'TÓXICO: Las nueces de macadamia causan debilidad, vómitos y temblores.',
      'hueso cocido':
          'PELIGROSO: Los huesos cocidos se astillan y pueden perforar el tracto digestivo.',
    };

    const safeFoods = <String, String>{
      'pollo':
          'SEGURO (Cocido, sin sal, sin piel ni huesos): Excelente fuente de proteína magra.',
      'arroz':
          'SEGURO (Cocido y sin condimentos): Útil en pequeñas porciones o dietas blandas.',
      'zanahoria':
          'SEGURO: Baja en calorías y rica en fibra (cruda en trozos adecuados o cocida).',
      'manzana':
          'SEGURO (Sin semillas ni corazón): Aporta fibra y vitaminas como premio ocasional.',
      'calabaza':
          'SEGURO (Cocida y natural): Excelente para la digestión y el tránsito intestinal.',
      'zapallo':
          'SEGURO (Cocido y natural): Excelente para la digestión y el tránsito intestinal.',
      'salmón':
          'SEGURO (Bien cocido y sin espinas): Rico en ácidos grasos omega-3.',
      'salmon':
          'SEGURO (Bien cocido y sin espinas): Rico en ácidos grasos omega-3.',
      'sandía':
          'SEGURO (Sin semillas ni cáscara): Hidratante en pequeñas cantidades.',
      'sandia':
          'SEGURO (Sin semillas ni cáscara): Hidratante en pequeñas cantidades.',
      'plátano':
          'SEGURO CON MODERACIÓN: Solo en trozos pequeños por su contenido de azúcar.',
      'platano':
          'SEGURO CON MODERACIÓN: Solo en trozos pequeños por su contenido de azúcar.',
      'banana':
          'SEGURO CON MODERACIÓN: Solo en trozos pequeños por su contenido de azúcar.',
    };

    for (final entry in toxicFoods.entries) {
      if (lower.contains(entry.key)) {
        return 'CONSULTA SOBRE "$input" PARA ${species.toUpperCase()}:\n\n'
            '❌ ${entry.value}\n\n'
            'Si ${pet.name} ingirió este alimento, contacta a su veterinario de inmediato.';
      }
    }

    for (final entry in safeFoods.entries) {
      if (lower.contains(entry.key)) {
        return 'CONSULTA SOBRE "$input" PARA ${species.toUpperCase()}:\n\n'
            '✅ ${entry.value}\n\n'
            'Recuerda que los premios o alimentos extras no deben superar el 10% de su dieta diaria.';
      }
    }

    return '''
CONSULTA SOBRE "$input" PARA ${species.toUpperCase()}:

⚠️ PRECAUCIÓN / VERIFICAR ANTES DE OFRECER:
• Asegúrate de que no contenga sal, azúcar, xilitol, cebolla, ajo, salsas ni huesos cocidos.
• Si es la primera vez que lo prueba y es un alimento apto para $species, ofrece una porción mínima y observa posibles reacciones digestivas o alérgicas.
• En caso de duda, consulta con tu veterinario antes de incluirlo en la dieta de ${pet.name}.
''';
  }

  void _showResultModal(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: SelectableText(
              content.trim(),
              style: const TextStyle(height: 1.45),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content.trim()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Texto copiado al portapapeles')),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showInputModal(
    BuildContext context, {
    required String title,
    required String hint,
    required String Function(String input) onSubmit,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(hintText: hint),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(dialogContext);
              _showResultModal(
                context,
                title: title,
                content: onSubmit(text),
              );
            },
            child: const Text('Consultar'),
          ),
        ],
      ),
    );
  }
}
