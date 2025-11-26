import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/utils/app_theme.dart';

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
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Imagen de la mascota
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: pet.files.petImage.isNotEmpty
                      ? Image.memory(
                          base64Decode(pet.files.petImage.split(',').last),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPetIcon();
                          },
                        )
                      : _buildPetIcon(),
                ),
              ),
              const SizedBox(width: 16),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name.isNotEmpty ? pet.name : 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pet.breed.isNotEmpty ? pet.breed : 'Sin raza',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          pet.type == 'dog' ? Icons.pets : Icons.pets,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pet.type == 'dog' ? 'Perro' : 'Gato',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Botón de editar
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetIcon() {
    return Icon(
      pet.type == 'dog' ? Icons.pets : Icons.pets,
      size: 50,
      color: Colors.grey[400],
    );
  }
}
