// Security-rules tests for StepSecure. Run with `npm test` (needs Java 11+).
// Each test states the attack or mistake it guards against.
import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection,
  getDocs, serverTimestamp, Timestamp,
} from 'firebase/firestore';
import { ref, get, set } from 'firebase/database';

const ALICE = 'alice';
const BOB = 'bob';
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-stepsecure',
    firestore: { rules: readFileSync('firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
    database: {
      rules: readFileSync('database.rules.json', 'utf8'),
      host: '127.0.0.1', port: 9000,
    },
  });
});
after(async () => env?.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearDatabase();
  // Seed as the trusted backend would (rules disabled = Admin SDK).
  await env.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    await setDoc(doc(fs, `users/${ALICE}`), {
      displayName: 'Alice', role: 'caregiver', createdAt: Timestamp.now(),
    });
    await setDoc(doc(fs, `users/${ALICE}/alerts/a1`), {
      status: 'pending', eventType: 'fall_detected', deviceId: 'dev1',
      timestamp: Timestamp.now(),
    });
    await setDoc(doc(fs, `users/${ALICE}/alerts/a2`), {
      status: 'acknowledged', timestamp: Timestamp.now(),
      acknowledgedAt: Timestamp.now(),
    });
    await setDoc(doc(fs, `users/${ALICE}/contacts/c1`), {
      name: 'Mum', phone: '+919876543210', relation: 'Mother',
      priority: 0, createdAt: Timestamp.now(),
    });
    const db = ctx.database();
    await set(ref(db, `userDevices/${ALICE}/dev1`), { name: 'Wearable' });
    await set(ref(db, 'sensors/dev1/live'), { accelX: 1, timestamp: Date.now() });
    await set(ref(db, 'sensors/dev1/status'), { state: 'online', lastHeartbeat: Date.now() });
    await set(ref(db, 'sensors/dev2/live'), { accelX: 9, timestamp: Date.now() });
  });
});

const alice = () => env.authenticatedContext(ALICE).firestore();
const bob = () => env.authenticatedContext(BOB).firestore();
const anon = () => env.unauthenticatedContext().firestore();

// ---------- Firestore: isolation ----------

test('anonymous users can read nothing', async () => {
  await assertFails(getDoc(doc(anon(), `users/${ALICE}`)));
  await assertFails(getDocs(collection(anon(), `users/${ALICE}/alerts`)));
  await assertFails(getDocs(collection(anon(), `users/${ALICE}/contacts`)));
});

test('another user cannot read Alice profile, alerts or contacts', async () => {
  await assertFails(getDoc(doc(bob(), `users/${ALICE}`)));
  await assertFails(getDocs(collection(bob(), `users/${ALICE}/alerts`)));
  await assertFails(getDocs(collection(bob(), `users/${ALICE}/contacts`)));
});

test('owner can read own data', async () => {
  await assertSucceeds(getDoc(doc(alice(), `users/${ALICE}`)));
  await assertSucceeds(getDocs(collection(alice(), `users/${ALICE}/alerts`)));
  await assertSucceeds(getDocs(collection(alice(), `users/${ALICE}/contacts`)));
});

test('unlisted paths are denied even for the owner', async () => {
  await assertFails(setDoc(doc(alice(), 'misc/x'), { a: 1 }));
  await assertFails(setDoc(doc(alice(), `users/${ALICE}/other/x`), { a: 1 }));
});

// ---------- Firestore: profile ----------

test('new user can create a valid caregiver profile', async () => {
  await assertSucceeds(setDoc(doc(bob(), `users/${BOB}`), {
    displayName: 'Bob', phone: '+91 98765 43210', role: 'caregiver',
    createdAt: serverTimestamp(),
  }));
});

test('cannot create a profile for someone else', async () => {
  await assertFails(setDoc(doc(bob(), 'users/carol'), {
    displayName: 'Carol', role: 'caregiver', createdAt: serverTimestamp(),
  }));
});

test('profile cannot grant itself another role or add unknown fields', async () => {
  await assertFails(setDoc(doc(bob(), `users/${BOB}`), {
    displayName: 'Bob', role: 'admin', createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(bob(), `users/${BOB}`), {
    displayName: 'Bob', role: 'caregiver', isAdmin: true, createdAt: serverTimestamp(),
  }));
});

test('profile createdAt cannot be back-dated', async () => {
  await assertFails(setDoc(doc(bob(), `users/${BOB}`), {
    displayName: 'Bob', role: 'caregiver', createdAt: Timestamp.fromMillis(0),
  }));
});

test('owner can rename but not change role or createdAt; cannot delete', async () => {
  await assertSucceeds(updateDoc(doc(alice(), `users/${ALICE}`), { displayName: 'Alice B' }));
  await assertFails(updateDoc(doc(alice(), `users/${ALICE}`), { role: 'admin' }));
  await assertFails(updateDoc(doc(alice(), `users/${ALICE}`), { createdAt: serverTimestamp() }));
  await assertFails(deleteDoc(doc(alice(), `users/${ALICE}`)));
});

// ---------- Firestore: alerts ----------

test('app cannot create alerts (no fabricated emergencies)', async () => {
  await assertFails(setDoc(doc(alice(), `users/${ALICE}/alerts/fake`), {
    status: 'pending', eventType: 'fall_detected', timestamp: serverTimestamp(),
  }));
  await assertFails(addDoc(collection(alice(), `users/${ALICE}/alerts`), { status: 'pending' }));
});

test('owner can acknowledge a pending alert', async () => {
  await assertSucceeds(updateDoc(doc(alice(), `users/${ALICE}/alerts/a1`), {
    status: 'acknowledged', acknowledgedAt: serverTimestamp(),
  }));
});

test('acknowledge must use server time', async () => {
  await assertFails(updateDoc(doc(alice(), `users/${ALICE}/alerts/a1`), {
    status: 'acknowledged', acknowledgedAt: Timestamp.fromMillis(1000),
  }));
});

test('acknowledge cannot rewrite other alert fields', async () => {
  await assertFails(updateDoc(doc(alice(), `users/${ALICE}/alerts/a1`), {
    status: 'acknowledged', acknowledgedAt: serverTimestamp(), eventType: 'other',
  }));
  await assertFails(updateDoc(doc(alice(), `users/${ALICE}/alerts/a1`), {
    status: 'acknowledged', acknowledgedAt: serverTimestamp(), timestamp: Timestamp.fromMillis(1000),
  }));
});

test('cannot un-acknowledge, mark resolved from the app, or re-ack', async () => {
  await assertFails(updateDoc(doc(alice(), `users/${ALICE}/alerts/a2`), { status: 'pending' }));
  await assertFails(updateDoc(doc(alice(), `users/${ALICE}/alerts/a1`), { status: 'resolved' }));
  await assertFails(updateDoc(doc(alice(), `users/${ALICE}/alerts/a2`), {
    status: 'acknowledged', acknowledgedAt: serverTimestamp(),
  }));
});

test('another user cannot acknowledge Alice alerts', async () => {
  await assertFails(updateDoc(doc(bob(), `users/${ALICE}/alerts/a1`), {
    status: 'acknowledged', acknowledgedAt: serverTimestamp(),
  }));
});

test('alerts can never be deleted from the app', async () => {
  await assertFails(deleteDoc(doc(alice(), `users/${ALICE}/alerts/a1`)));
  await assertFails(deleteDoc(doc(alice(), `users/${ALICE}/alerts/a2`)));
});

// ---------- Firestore: contacts ----------

const goodContact = () => ({
  name: 'Dad', phone: '+14155550123', relation: 'Father', priority: 1,
  createdAt: serverTimestamp(),
});

test('owner can add a valid contact; others cannot add to Alice', async () => {
  await assertSucceeds(addDoc(collection(alice(), `users/${ALICE}/contacts`), goodContact()));
  await assertFails(addDoc(collection(bob(), `users/${ALICE}/contacts`), goodContact()));
});

test('contact with optional valid email is accepted', async () => {
  await assertSucceeds(addDoc(collection(alice(), `users/${ALICE}/contacts`),
    { ...goodContact(), email: 'dad@example.com' }));
});

test('invalid contacts are rejected', async () => {
  const col = () => collection(alice(), `users/${ALICE}/contacts`);
  await assertFails(addDoc(col(), { ...goodContact(), phone: '98765' }));
  await assertFails(addDoc(col(), { ...goodContact(), phone: '+91 98765 43210' })); // not E.164
  await assertFails(addDoc(col(), { ...goodContact(), name: '' }));
  await assertFails(addDoc(col(), { ...goodContact(), name: 'x'.repeat(101) }));
  await assertFails(addDoc(col(), { ...goodContact(), email: 'not-an-email' }));
  await assertFails(addDoc(col(), { ...goodContact(), priority: 'first' }));
  await assertFails(addDoc(col(), { ...goodContact(), isAdmin: true }));
  await assertFails(addDoc(col(), { ...goodContact(), createdAt: Timestamp.fromMillis(0) }));
});

test('contact update validates data and keeps createdAt', async () => {
  const c1 = () => doc(alice(), `users/${ALICE}/contacts/c1`);
  await assertSucceeds(updateDoc(c1(), { name: 'Mother', priority: -1 }));
  await assertFails(updateDoc(c1(), { phone: 'call me' }));
  await assertFails(updateDoc(c1(), { createdAt: serverTimestamp() }));
});

test('owner can delete a contact; others cannot', async () => {
  await assertFails(deleteDoc(doc(bob(), `users/${ALICE}/contacts/c1`)));
  await assertSucceeds(deleteDoc(doc(alice(), `users/${ALICE}/contacts/c1`)));
});

// ---------- Realtime Database ----------

const rtdb = (uid, claims) =>
  (uid ? env.authenticatedContext(uid, claims) : env.unauthenticatedContext()).database();

test('RTDB: anonymous cannot read anything', async () => {
  await assertFails(get(ref(rtdb(), 'sensors/dev1/live')));
  await assertFails(get(ref(rtdb(), `userDevices/${ALICE}`)));
});

test('RTDB: owner reads linked device but not an unlinked one', async () => {
  await assertSucceeds(get(ref(rtdb(ALICE), 'sensors/dev1/live')));
  await assertSucceeds(get(ref(rtdb(ALICE), 'sensors/dev1/status')));
  await assertFails(get(ref(rtdb(ALICE), 'sensors/dev2/live')));
});

test('RTDB: another user cannot read Alice device or her device list', async () => {
  await assertFails(get(ref(rtdb(BOB), 'sensors/dev1/live')));
  await assertFails(get(ref(rtdb(BOB), `userDevices/${ALICE}`)));
});

test('RTDB: owner can list her own devices', async () => {
  await assertSucceeds(get(ref(rtdb(ALICE), `userDevices/${ALICE}`)));
});

test('RTDB: users cannot link a device to themselves (no device hijacking)', async () => {
  await assertFails(set(ref(rtdb(BOB), `userDevices/${BOB}/dev1`), { name: 'mine' }));
  await assertFails(set(ref(rtdb(ALICE), `userDevices/${ALICE}/dev2`), { name: 'mine' }));
});

test('RTDB: app users cannot write sensor data (no spoofed readings)', async () => {
  await assertFails(set(ref(rtdb(ALICE), 'sensors/dev1/live'), { accelX: 0, timestamp: Date.now() }));
});

test('RTDB: device with matching claim can write valid data only', async () => {
  const dev = rtdb('device-dev1', { deviceId: 'dev1' });
  await assertSucceeds(set(ref(dev, 'sensors/dev1/live'), {
    accelX: 0.1, accelY: 0.2, accelZ: 1.0, gyroX: 0, gyroY: 0, gyroZ: 0,
    accelUnit: 'g', gyroUnit: 'deg/s', prediction: 'normal', timestamp: Date.now(),
  }));
  await assertSucceeds(set(ref(dev, 'sensors/dev1/status'), {
    state: 'online', lastHeartbeat: Date.now(), monitoring: true, battery: 80,
  }));
  await assertFails(set(ref(dev, 'sensors/dev1/live'), { prediction: 'maybe', timestamp: Date.now() }));
  await assertFails(set(ref(dev, 'sensors/dev1/status'), { state: 'online', battery: 500 }));
  await assertFails(set(ref(dev, 'sensors/dev1/live'), { accelX: 'text', timestamp: Date.now() }));
  await assertFails(set(ref(dev, 'sensors/dev1/live'), { timestamp: Date.now(), extra: 1 }));
});

test('RTDB: a device cannot write another device data', async () => {
  const dev = rtdb('device-dev1', { deviceId: 'dev1' });
  await assertFails(set(ref(dev, 'sensors/dev2/live'), { accelX: 0, timestamp: Date.now() }));
});
