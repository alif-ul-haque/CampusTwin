// =============================================================================
// Firestore viewer — list collections / docs / field names from the terminal.
//
// Usage:
//   node scripts/list_firestore.js            -> all collections + doc count + field names
//   node scripts/list_firestore.js <collection> -> full documents of one collection
// =============================================================================

const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const path = require('path');

admin.initializeApp({
  credential: admin.cert(path.join(__dirname, '..', 'service-account.json')),
});

const db = getFirestore();
const target = process.argv[2];

function fmt(v) {
  if (v instanceof Date) return v.toISOString().slice(0, 16);
  if (v && typeof v.toDate === 'function') return v.toDate().toISOString().slice(0, 16);
  if (typeof v === 'object' && v !== null) return JSON.stringify(v);
  return String(v);
}

async function listAll() {
  const collections = await db.listCollections();
  const collectionIds = collections.map((c) => c.id).sort();
  if (collectionIds.length === 0) {
    console.log('No collections found.');
    return;
  }
  console.log(`${collectionIds.length} collections found:\n`);
  for (const id of collectionIds) {
    const docs = await db.collection(id).limit(3).get();
    const fields = new Set();
    docs.docs.forEach((d) => Object.keys(d.data()).forEach((k) => fields.add(k)));
    console.log(`📁 ${id}  (${docs.size >= 3 ? '3+' : docs.size} docs)`);
    if (fields.size > 0) {
      console.log(`   fields: ${[...fields].sort().join(', ')}`);
    }
    console.log('');
  }
}

async function listOne(collectionId) {
  const snap = await db.collection(collectionId).get();
  if (snap.empty) {
    console.log(`Collection "${collectionId}" is empty or does not exist.`);
    return;
  }
  console.log(`${snap.docs.length} docs in ${collectionId}:\n`);
  for (const d of snap.docs) {
    console.log(`📄 ${d.id}`);
    const data = d.data();
    for (const [k, v] of Object.entries(data)) {
      console.log(`   ${k}: ${fmt(v)}`);
    }
    console.log('');
  }
}

(async () => {
  try {
    if (target) {
      await listOne(target);
    } else {
      await listAll();
    }
    process.exit(0);
  } catch (e) {
    console.error('Failed:', e.message);
    process.exit(1);
  }
})();
