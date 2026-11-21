import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/providers/auth_provider.dart';
import 'package:ficha_pet/providers/pet_provider.dart';
import 'package:ficha_pet/services/notification_service.dart';
import 'package:ficha_pet/utils/date_utils.dart';
import 'package:ficha_pet/utils/pet_labels.dart';

Pet _pet({String name = 'Toby', String weight = '', String nextVaccine = ''}) {
  return Pet.empty().copyWith(
    name: name,
    type: 'dog',
    gender: 'male',
    chip: 'no',
    weight: weight,
    nextVaccineDate: nextVaccine,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Pet se serializa y deserializa sin perder datos ni cambiar id', () {
    final pet = _pet()
      ..id = 42
      ..ownerId = 'usr_1';
    final copy = Pet.fromJson(pet.toJson());
    expect(copy.id, 42);
    expect(copy.ownerId, 'usr_1');
    expect(copy.name, 'Toby');
    expect(copy.toJson()['id'], 42);
  });

  test('Registro, login y aislamiento de mascotas por usuario', () async {
    final auth = AuthProvider();
    final provider = PetProvider();

    final userA = await auth.register(
      name: 'Ana',
      email: 'ana@test.com',
      password: '1234',
    );
    await provider.setActiveUser(userA);
    await provider.addPet(_pet(name: 'Luna', weight: '8'));
    expect(provider.pets.map((p) => p.name), ['Luna']);

    await auth.logout();
    final userB = await auth.register(
      name: 'Carlos',
      email: 'carlos@test.com',
      password: '1234',
    );
    await provider.setActiveUser(userB);
    expect(provider.pets, isEmpty);

    await provider.addPet(_pet(name: 'Thor', weight: '22'));
    expect(provider.pets.map((p) => p.name), ['Thor']);

    // Al volver a iniciar sesión como Ana, sólo ve a Luna
    await auth.login(email: 'ana@test.com', password: '1234');
    await provider.setActiveUser(auth.currentUser);
    expect(provider.pets.map((p) => p.name), ['Luna']);
  });

  test('Veterinario escanea QR y sincroniza actualizaciones bidireccionalmente',
      () async {
    final auth = AuthProvider();
    final provider = PetProvider();

    // 1. Dueño crea a su mascota
    final owner = await auth.register(
      name: 'Dueño Test',
      email: 'dueno@test.com',
      password: '1234',
      role: 'owner',
    );
    await provider.setActiveUser(owner);
    await provider.addPet(_pet(name: 'Yoya', weight: '6.5'));
    final yoya = provider.pets.first;
    final qrCode = yoya.shareCode;

    // 2. Veterinario se registra y escanea el QR clínico de Yoya
    await auth.logout();
    final vet = await auth.register(
      name: 'Dra. Vet',
      email: 'vet@test.com',
      password: '1234',
      role: 'vet',
      clinicName: 'Clínica Central',
    );
    await provider.setActiveUser(vet);
    expect(provider.pets, isEmpty);

    final linked = await provider.linkPetByQR(qrCode);
    expect(linked.name, 'Yoya');
    expect(provider.pets.length, 1);

    // 3. Veterinario actualiza el peso e historial médico de Yoya
    await provider.updatePet(linked.copyWith(
      weight: '6.8',
      medicalHistory: [
        MedicalHistoryEntry(
          date: DateTime.now().toIso8601String(),
          text: '[Vet: Dra. Vet] Vacuna séxtuple aplicada.',
        ),
      ],
    ));

    // 4. El dueño inicia sesión y ve la actualización del veterinario
    await auth.login(email: 'dueno@test.com', password: '1234');
    await provider.setActiveUser(auth.currentUser);
    final updatedForOwner = provider.pets.first;
    expect(updatedForOwner.weight, '6.8');
    expect(updatedForOwner.medicalHistory.length, 1);
    expect(updatedForOwner.medicalHistory.first.text, contains('Dra. Vet'));

    // 5. El dueño actualiza el peso a 7.0 y el veterinario también lo ve
    await provider.updatePet(updatedForOwner.copyWith(weight: '7.0'));
    await auth.login(email: 'vet@test.com', password: '1234');
    await provider.setActiveUser(auth.currentUser);
    expect(provider.pets.first.weight, '7.0');
  });

  test('Recordatorios incluyen vencidos (cada 2 días) y próximos', () async {
    final provider = PetProvider();
    await provider.loadPets();
    final now = DateTime.now();
    await provider.addPet(_pet(
        name: 'Vencido',
        nextVaccine: formatDateForInput(now.subtract(const Duration(days: 3)))));
    await provider.addPet(_pet(
        name: 'Pronto',
        nextVaccine: formatDateForInput(now.add(const Duration(days: 5)))));
    await provider.addPet(_pet(
        name: 'Lejano',
        nextVaccine: formatDateForInput(now.add(const Duration(days: 90)))));

    final reminders = provider.getReminders();
    expect(reminders.map((r) => r.pet.name), ['Vencido', 'Pronto']);
    expect(reminders.first.isOverdue, isTrue);
    expect(reminders.first.pushCadenceBadge, contains('cada 2 días'));

    // Verifica que NotificationService programa repetición cada 2 días
    final service = NotificationService();
    final schedule = service.buildSchedulePreview(
      pets: provider.pets,
      advanceDays: 14,
    );
    expect(schedule.length, 2);
    expect(schedule.first.isOverdue, isTrue);
    expect(schedule.first.cadenceLabel, contains('cada 2 días'));
  });

  test('Etiquetas y edad', () {
    expect(petTypeLabel('cat'), 'Gato');
    expect(petTypeLabel(''), 'Sin especificar');
    final twoYearsAgo =
        DateTime.now().subtract(const Duration(days: 365 * 2 + 5));
    expect(petAgeLabel(formatDateForInput(twoYearsAgo)), '2 años');
  });
}
