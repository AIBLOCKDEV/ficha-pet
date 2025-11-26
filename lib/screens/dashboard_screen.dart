import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ficha_pet/providers/pet_provider.dart';
import 'package:ficha_pet/screens/edit_pet_screen.dart';
import 'package:ficha_pet/screens/view_pet_screen.dart';
import 'package:ficha_pet/widgets/pet_card.dart';
import 'package:ficha_pet/widgets/reminder_card.dart';
import 'package:ficha_pet/utils/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha Pet'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            color: AppTheme.backgroundColor,
            height: 4,
          ),
        ),
      ),
      body: Consumer<PetProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final reminders = provider.getReminders();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recordatorios
                if (reminders.isNotEmpty) ...[
                  const Text(
                    'Recordatorios Importantes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...reminders.map((reminder) => ReminderCard(
                        reminder: reminder,
                        onTap: () {
                          final petIndex = provider.pets
                              .indexWhere((p) => p.id == reminder.pet.id);
                          if (petIndex != -1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewPetScreen(petIndex: petIndex),
                              ),
                            );
                          }
                        },
                      )),
                  const SizedBox(height: 24),
                ],

                // Título y botón agregar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mis Mascotas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditPetScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Mascota'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Lista de mascotas
                if (provider.pets.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.pets,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes mascotas registradas',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Comienza agregando tu primera mascota',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: provider.pets.length,
                    itemBuilder: (context, index) {
                      return PetCard(
                        pet: provider.pets[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ViewPetScreen(petIndex: index),
                            ),
                          );
                        },
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditPetScreen(petIndex: index),
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EditPetScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

