#!/usr/bin/env node
/**
 * Tek seferlik migration: mevcut görevlere `searchTokens` alanını ekler / günceller.
 *
 * Token üretimi uygulamayla aynı fonksiyonu kullanır (lib/utils/search.js), bu yüzden önce derlenir:
 *   npm run migrate:search-tokens -- [seçenekler]
 *
 * Seçenekler:
 *   --project <id>   Firebase proje ID'si (yoksa GCLOUD_PROJECT / GOOGLE_CLOUD_PROJECT)
 *   --dry-run        Hiçbir şey yazmaz, yalnızca kaç görevin güncelleneceğini raporlar
 *   --batch <n>      Parti boyutu (varsayılan 400, en fazla 500)
 *   --yes            Emülatör DIŞINDA (canlı projede) yazmak için zorunlu onay
 *
 * Örnekler (PowerShell):
 *   $env:FIRESTORE_EMULATOR_HOST="127.0.0.1:8180"; npm run migrate:search-tokens -- --project demo-yourmang
 *   $env:GOOGLE_APPLICATION_CREDENTIALS="key.json"; npm run migrate:search-tokens -- --project my-proj --dry-run
 *
 * Güvenli tekrar çalıştırma: token'ları zaten güncel olan görevlere dokunulmaz; `updatedAt` değişmez.
 */
import { initializeApp } from 'firebase-admin/app';
import { FieldPath, getFirestore } from 'firebase-admin/firestore';
import { buildSearchTokens } from '../lib/utils/search.js';

function parseArgs(argv) {
  const args = { dryRun: false, yes: false, batch: 400, project: undefined };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--dry-run') args.dryRun = true;
    else if (a === '--yes') args.yes = true;
    else if (a === '--project') args.project = argv[++i];
    else if (a === '--batch') args.batch = Number(argv[++i]);
    else throw new Error(`Bilinmeyen seçenek: ${a}`);
  }
  if (!Number.isInteger(args.batch) || args.batch < 1 || args.batch > 500) {
    throw new Error('--batch 1 ile 500 arasında olmalı');
  }
  return args;
}

const sameTokens = (a, b) =>
  Array.isArray(a) && a.length === b.length && a.every((t, i) => t === b[i]);

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const projectId = args.project ?? process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT;
  if (!projectId) throw new Error('Proje belirtilmedi: --project <id>');

  const emulator = process.env.FIRESTORE_EMULATOR_HOST;
  console.log(`Hedef: ${emulator ? `emülatör (${emulator})` : 'CANLI Firestore'} · proje: ${projectId}`);
  console.log(`Mod: ${args.dryRun ? 'dry-run (yazma yok)' : 'yazma'} · parti: ${args.batch}`);
  if (!emulator && !args.dryRun && !args.yes) {
    throw new Error('Canlı projeye yazmak için --yes gerekli (önce --dry-run ile kontrol edin).');
  }

  const db = getFirestore(initializeApp({ projectId }));
  const tasks = db.collection('tasks');
  let last;
  let scanned = 0;
  let changed = 0;

  for (;;) {
    let query = tasks.orderBy(FieldPath.documentId()).limit(args.batch);
    if (last) query = query.startAfter(last);
    const snap = await query.get();
    if (snap.empty) break;

    const batch = db.batch();
    let pending = 0;
    for (const doc of snap.docs) {
      scanned++;
      const { title = '', searchTokens } = doc.data();
      const next = buildSearchTokens(String(title));
      if (sameTokens(searchTokens, next)) continue;
      changed++;
      if (!args.dryRun) {
        batch.update(doc.ref, { searchTokens: next });
        pending++;
      }
    }
    if (pending > 0) await batch.commit();

    last = snap.docs[snap.docs.length - 1];
    console.log(`  … ${scanned} görev tarandı, ${changed} ${args.dryRun ? 'güncellenecek' : 'güncellendi'}`);
  }

  console.log(
    `Bitti: ${scanned} görev tarandı · ${changed} ${args.dryRun ? 'güncellenecek' : 'güncellendi'} · ` +
      `${scanned - changed} zaten güncel.`,
  );
}

main().catch((err) => {
  console.error(`HATA: ${err.message}`);
  process.exit(1);
});
