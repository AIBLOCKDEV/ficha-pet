import 'package:flutter/material.dart';
import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/utils/pet_labels.dart';
import 'package:ficha_pet/widgets/base64_image.dart';

class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const PetCard({
    super.key,
    required this.pet,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final age = petAgeLabel(pet.birthday);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 84,
                  height: 84,
                  color: scheme.primaryContainer.withValues(alpha: 0.65),
                  child: Base64Image(
                    source: pet.files.petImage,
                    placeholder: _buildPetIcon(scheme),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pet.name.isNotEmpty ? pet.name : 'Sin nombre',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pet.breed.isNotEmpty ? pet.breed : 'Sin raza especificada',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildPill(
                          scheme,
                          icon: petTypeIcon(pet.type),
                          text: petTypeLabel(pet.type),
                        ),
                        if (age.isNotEmpty)
                          _buildPill(
                            scheme,
                            icon: Icons.cake_rounded,
                            text: age,
                          ),
                        if (pet.weight.isNotEmpty)
                          _buildPill(
                            scheme,
                            icon: Icons.monitor_weight_rounded,
                            text: '${pet.weight} kg',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onEdit,
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill(
    ColorScheme scheme, {
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetIcon(ColorScheme scheme) {
    return Center(
      child: Icon(
        petTypeIcon(pet.type),
        size: 42,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}
