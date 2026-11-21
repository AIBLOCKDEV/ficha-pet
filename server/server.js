/**
 * FICHA PET — Servidor Backend REST API + Base de Datos + Motor Push
 * - Registro y Login de usuarios con tokens firmados (HMAC-SHA256)
 * - Perfil y Mascotas aisladas por usuario (ownerId)
 * - Motor programador de Notificaciones Push:
 *     * Con anticipación (30, 14, 7, 3, 2, 1, 0 días antes)
 *     * Vencidas: sigue enviando recordatorios cada 2 días (48 h)
 * - Persistencia automática en `data/ficha_pet_db.json` + soporte SQL (`schema.sql`)
 */

const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = Number(process.env.PORT || 3000);
const HOST = process.env.HOST || '0.0.0.0';
const JWT_SECRET = process.env.JWT_SECRET || 'ficha_pet_production_secret_2026';
const DATA_DIR = path.join(__dirname, 'data');
const DB_FILE = path.join(DATA_DIR, 'ficha_pet_db.json');

function initDatabase() {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }
  if (!fs.existsSync(DB_FILE)) {
    const initialDb = {
      meta: {
        version: '2.0.0',
        createdAt: new Date().toISOString(),
        schemaFile: 'schema.sql',
      },
      users: [],
      passwords: {},
      pets: [],
      pushDevices: [],
      pushDispatchLog: {},
    };
    fs.writeFileSync(DB_FILE, JSON.stringify(initialDb, null, 2), 'utf8');
  }
}

function readDb() {
  initDatabase();
  return JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
}

function writeDb(db) {
  fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2), 'utf8');
}

function signToken(payload) {
  const data = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const sig = crypto
    .createHmac('sha256', JWT_SECRET)
    .update(data)
    .digest('base64url');
  return `${data}.${sig}`;
}

function evaluatePendingNotifications(db, userId) {
  const user = db.users.find((u) => u.id === userId);
  const advanceDays = user?.advanceDays ?? 14;
  const userPets = db.pets.filter((p) => p.ownerId === userId);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayIso = today.toISOString().slice(0, 10);

  const notifications = [];

  function check(pet, dateStr, eventType, detail) {
    if (!dateStr) return;
    const due = new Date(`${dateStr}T00:00:00`);
    if (Number.isNaN(due.getTime())) return;
    const daysLeft = Math.round((due - today) / (1000 * 60 * 60 * 24));
    if (daysLeft > advanceDays) return;

    const isOverdue = daysLeft < 0;
    const key = `${userId}_${pet.id}_${eventType}_${dateStr}`;
    const lastSentStr = db.pushDispatchLog[key];
    let shouldSend = false;

    if (!lastSentStr) {
      shouldSend = true;
    } else {
      const lastSent = new Date(`${lastSentStr}T00:00:00`);
      const daysSinceLast = Math.round(
        (today - lastSent) / (1000 * 60 * 60 * 24)
      );
      if (isOverdue) {
        // Si ya está vencida, seguir mandando cada 2 días
        shouldSend = daysSinceLast >= 2;
      } else {
        const milestones = new Set([30, 21, 14, 7, 3, 2, 1, 0]);
        shouldSend = daysSinceLast >= 1 && milestones.has(daysLeft);
      }
    }

    notifications.push({
      petId: pet.id,
      petName: pet.name,
      eventType,
      detail,
      dueDate: dateStr,
      daysLeft,
      isOverdue,
      cadence: isOverdue
        ? 'Repetición cada 2 días (Vencida)'
        : `Anticipación (${daysLeft} días)`,
      shouldDispatchToday: shouldSend,
    });

    if (shouldSend) {
      db.pushDispatchLog[key] = todayIso;
    }
  }

  for (const pet of userPets) {
    check(pet, pet.nextVaccineDate, 'Vacuna', pet.vaccineType || '');
    check(
      pet,
      pet.nextDewormingDate,
      'Desparasitación',
      pet.dewormingProduct || ''
    );
  }

  writeDb(db);
  return notifications;
}

function sendJson(res, status, payload) {
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  });
  res.end(JSON.stringify(payload));
}

function parseBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (chunk) => {
      raw += chunk;
      if (raw.length > 15 * 1024 * 1024) {
        reject(new Error('Payload too large'));
      }
    });
    req.on('end', () => {
      if (!raw) return resolve({});
      try {
        resolve(JSON.parse(raw));
      } catch (e) {
        reject(e);
      }
    });
    req.on('error', reject);
  });
}

initDatabase();

if (process.argv.includes('--init-only')) {
  console.log('Base de datos inicializada en:', DB_FILE);
  process.exit(0);
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    return sendJson(res, 200, { ok: true });
  }

  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname || '';

  try {
    if (req.method === 'GET' && pathname === '/api/health') {
      const db = readDb();
      return sendJson(res, 200, {
        status: 'ok',
        service: 'ficha-pet-api',
        version: '2.0.0',
        usersCount: db.users.length,
        petsCount: db.pets.length,
      });
    }

    if (req.method === 'POST' && pathname === '/api/auth/register') {
      const body = await parseBody(req);
      const email = (body.email || '').trim().toLowerCase();
      const name = (body.name || '').trim();
      const passwordHash = body.passwordHash || '';

      if (!email || !name || !passwordHash) {
        return sendJson(res, 400, { error: 'Datos incompletos' });
      }

      const db = readDb();
      if (db.users.some((u) => u.email.toLowerCase() === email)) {
        return sendJson(res, 409, {
          error: 'El correo ya está registrado',
        });
      }

      const newUser = {
        id: body.id || `usr_${Date.now()}`,
        name,
        email,
        phone: body.phone || '',
        role: body.role === 'vet' ? 'vet' : 'owner',
        clinicName: body.clinicName || '',
        avatarBase64: '',
        createdAt: new Date().toISOString(),
        themeSeedIndex: 0,
        themeMode: 'light',
        pushEnabled: true,
        advanceDays: 14,
      };

      db.users.push(newUser);
      db.passwords[newUser.id] = passwordHash;
      writeDb(db);

      const token = signToken({ userId: newUser.id, email: newUser.email });
      return sendJson(res, 201, { token, user: newUser });
    }

    if (req.method === 'POST' && pathname === '/api/auth/login') {
      const body = await parseBody(req);
      const email = (body.email || '').trim().toLowerCase();
      const passwordHash = body.passwordHash || '';

      const db = readDb();
      const user = db.users.find((u) => u.email.toLowerCase() === email);
      if (!user || db.passwords[user.id] !== passwordHash) {
        return sendJson(res, 401, { error: 'Credenciales inválidas' });
      }

      const token = signToken({ userId: user.id, email: user.email });
      return sendJson(res, 200, { token, user });
    }

    if (req.method === 'GET' && pathname === '/api/pets') {
      const userId = parsedUrl.query.userId || parsedUrl.query.ownerId || '';
      const db = readDb();
      // Devuelve las mascotas propias Y las vinculadas como paciente veterinario
      const pets = db.pets.filter(
        (p) =>
          p.ownerId === userId ||
          (Array.isArray(p.linkedVetIds) && p.linkedVetIds.includes(userId))
      );
      return sendJson(res, 200, { pets });
    }

    if (req.method === 'POST' && pathname === '/api/vet/link') {
      const body = await parseBody(req);
      const vetId = (body.vetId || '').trim();
      const petId = body.petId != null ? Number(body.petId) : null;
      const shareCode = (body.shareCode || '').trim().toUpperCase();

      if (!vetId) {
        return sendJson(res, 400, { error: 'vetId requerido' });
      }

      const db = readDb();
      const pet = db.pets.find((p) => {
        if (petId != null && Number(p.id) === petId) return true;
        if (shareCode) {
          const raw = String(p.id || 0);
          const suffix =
            raw.length > 6 ? raw.slice(-6) : raw.padStart(6, '0');
          return `FP-${suffix}` === shareCode;
        }
        return false;
      });

      if (!pet) {
        return sendJson(res, 404, {
          error: 'No se encontró ninguna mascota con ese código QR',
        });
      }

      if (!Array.isArray(pet.linkedVetIds)) {
        pet.linkedVetIds = [];
      }
      if (!pet.linkedVetIds.includes(vetId)) {
        pet.linkedVetIds.push(vetId);
        writeDb(db);
      }

      return sendJson(res, 200, { pet });
    }

    if (req.method === 'PUT' && pathname === '/api/pets/item') {
      const body = await parseBody(req);
      const incoming = body.pet;
      if (!incoming || incoming.id == null) {
        return sendJson(res, 400, { error: 'pet.id requerido' });
      }
      const db = readDb();
      const idx = db.pets.findIndex((p) => Number(p.id) === Number(incoming.id));
      if (idx === -1) {
        db.pets.push(incoming);
      } else {
        // Preservar ownerId original y unir linkedVetIds para sincronización bidireccional
        const existing = db.pets[idx];
        const mergedVets = Array.from(
          new Set([
            ...(Array.isArray(existing.linkedVetIds) ? existing.linkedVetIds : []),
            ...(Array.isArray(incoming.linkedVetIds) ? incoming.linkedVetIds : []),
          ])
        );
        db.pets[idx] = {
          ...incoming,
          ownerId: existing.ownerId || incoming.ownerId,
          linkedVetIds: mergedVets,
        };
      }
      writeDb(db);
      return sendJson(res, 200, { pet: db.pets[idx === -1 ? db.pets.length - 1 : idx] });
    }

    if (req.method === 'PUT' && pathname === '/api/pets/sync') {
      const body = await parseBody(req);
      const ownerId = body.ownerId || '';
      const incomingPets = Array.isArray(body.pets) ? body.pets : [];

      if (!ownerId) {
        return sendJson(res, 400, { error: 'ownerId requerido' });
      }

      const db = readDb();
      // Actualiza o inserta cada mascota preservando los vínculos con veterinarios
      for (const incoming of incomingPets) {
        const idx = db.pets.findIndex((p) => Number(p.id) === Number(incoming.id));
        if (idx === -1) {
          incoming.ownerId = incoming.ownerId || ownerId;
          incoming.linkedVetIds = Array.isArray(incoming.linkedVetIds)
            ? incoming.linkedVetIds
            : [];
          db.pets.push(incoming);
        } else {
          const existing = db.pets[idx];
          const mergedVets = Array.from(
            new Set([
              ...(Array.isArray(existing.linkedVetIds) ? existing.linkedVetIds : []),
              ...(Array.isArray(incoming.linkedVetIds) ? incoming.linkedVetIds : []),
            ])
          );
          db.pets[idx] = {
            ...incoming,
            ownerId: existing.ownerId || incoming.ownerId || ownerId,
            linkedVetIds: mergedVets,
          };
        }
      }
      writeDb(db);

      return sendJson(res, 200, {
        synced: incomingPets.length,
        ownerId,
      });
    }

    if (req.method === 'GET' && pathname === '/api/notifications/pending') {
      const ownerId = parsedUrl.query.ownerId || parsedUrl.query.userId || '';
      const db = readDb();
      const notifications = evaluatePendingNotifications(db, ownerId);
      return sendJson(res, 200, { notifications });
    }

    if (req.method === 'POST' && pathname === '/api/devices/register') {
      const body = await parseBody(req);
      const userId = (body.userId || '').trim();
      const deviceToken = (body.deviceToken || '').trim();
      const platform = (body.platform || 'android').trim();
      if (!userId || !deviceToken) {
        return sendJson(res, 400, { error: 'userId y deviceToken requeridos' });
      }
      const db = readDb();
      if (!Array.isArray(db.pushDevices)) db.pushDevices = [];
      const existing = db.pushDevices.find(
        (d) => d.userId === userId && d.deviceToken === deviceToken
      );
      if (!existing) {
        db.pushDevices.push({
          userId,
          deviceToken,
          platform,
          updatedAt: new Date().toISOString(),
        });
      } else {
        existing.platform = platform;
        existing.updatedAt = new Date().toISOString();
      }
      writeDb(db);
      return sendJson(res, 200, { registered: true });
    }

    if (req.method === 'PUT' && pathname === '/api/users/me') {
      const body = await parseBody(req);
      const userId = (body.id || '').trim();
      if (!userId) return sendJson(res, 400, { error: 'id requerido' });
      const db = readDb();
      const idx = db.users.findIndex((u) => u.id === userId);
      if (idx === -1) return sendJson(res, 404, { error: 'Usuario no encontrado' });
      db.users[idx] = { ...db.users[idx], ...body, id: userId };
      writeDb(db);
      return sendJson(res, 200, { user: db.users[idx] });
    }

    return sendJson(res, 404, { error: 'Endpoint no encontrado' });
  } catch (err) {
    return sendJson(res, 500, { error: err.message || 'Error interno' });
  }
});

server.listen(PORT, HOST, () => {
  console.log(
    `[Ficha Pet Server] API y Base de Datos escuchando en http://${HOST}:${PORT}/api`
  );
});
