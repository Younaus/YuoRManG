// Uçtan uca duman testi — emülatörler çalışırken: npm run test:smoke
const BASE = process.env.API_BASE ?? 'http://127.0.0.1:5101/demo-yourmang/europe-west1/api';
const AUTH = `http://${process.env.AUTH_EMULATOR ?? '127.0.0.1:9199'}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`;

let passed = 0, failed = 0;
const check = (name, cond, extra) => {
  if (cond) { passed++; console.log(`  ✓ ${name}`); }
  else { failed++; console.log(`  ✗ ${name}`, extra !== undefined ? JSON.stringify(extra) : ''); }
};

async function signUp(email) {
  const r = await fetch(AUTH, { method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, password: 'secret123', returnSecureToken: true }) });
  const j = await r.json();
  if (!j.idToken) throw new Error('signUp failed: ' + JSON.stringify(j));
  return j.idToken;
}

function client(token) {
  return async (method, path, body, rawBody) => {
    const headers = {};
    if (token) headers.authorization = `Bearer ${token}`;
    if (body !== undefined || rawBody !== undefined) headers['content-type'] = 'application/json';
    const r = await fetch(BASE + path, { method, headers, body: rawBody ?? (body !== undefined ? JSON.stringify(body) : undefined), redirect: 'manual' });
    const text = await r.text();
    let json; try { json = text ? JSON.parse(text) : undefined; } catch { json = text; }
    return { status: r.status, body: json, headers: r.headers };
  };
}

const run = Date.now();
const a = client(await signUp(`a${run}@test.dev`));
const b = client(await signUp(`b${run}@test.dev`));
const anon = client(null);
const bad = client('not-a-token');

console.log('\n[Auth]');
check('no token → 401', (await anon('GET', '/v1/me')).status === 401);
const badRes = await bad('GET', '/v1/tasks');
check('invalid token → 401 UNAUTHORIZED', badRes.status === 401 && badRes.body.error.code === 'UNAUTHORIZED', badRes.body);

console.log('\n[Profile]');
let r = await a('GET', '/v1/me');
check('GET /me creates profile', r.status === 200 && r.body.settings.theme === 'system' && r.body.email.startsWith('a'), r.body);
r = await a('PATCH', '/v1/me', { settings: { theme: 'dark' } });
check('PATCH /me merges settings', r.status === 200 && r.body.settings.theme === 'dark' && r.body.settings.locale === 'tr-TR', r.body);
r = await a('GET', '/v1/me');
check('settings persisted', r.body.settings.theme === 'dark' && r.body.settings.locale === 'tr-TR', r.body);
r = await a('PATCH', '/v1/me', {});
check('PATCH /me empty → 400', r.status === 400, r.body);

console.log('\n[Categories]');
const work = (await a('POST', '/v1/categories', { name: 'İş', color: '#4F46E5' })).body;
const projects = (await a('POST', '/v1/categories', { name: 'Projeler', parentId: work.id })).body;
const alpha = (await a('POST', '/v1/categories', { name: 'Alpha', parentId: projects.id })).body;
const personal = (await a('POST', '/v1/categories', { name: 'Kişisel' })).body;
check('create root + nested categories', [work, projects, alpha, personal].every((c) => c.id), [work, projects, alpha, personal]);
check('order auto-increments at root', work.order === 0 && personal.order === 1, [work.order, personal.order]);
r = await a('POST', '/v1/categories', { name: 'iş' });
check('duplicate sibling name (case-insensitive tr) → 409', r.status === 409, r.body);
r = await a('POST', '/v1/categories', { name: 'X', color: 'red' });
check('invalid color → 400 VALIDATION_ERROR', r.status === 400 && r.body.error.code === 'VALIDATION_ERROR', r.body);
r = await a('POST', '/v1/categories', { name: 'X', parentId: 'doesnotexist' });
check('unknown parent → 400', r.status === 400, r.body);
r = await a('POST', '/v1/categories', { name: 'X', extra: 1 });
check('unknown field rejected (strict) → 400', r.status === 400, r.body);

r = await a('GET', '/v1/categories/tree');
const tree = r.body.items;
check('tree has 2 roots', r.status === 200 && tree.length === 2, tree);
check('tree depth 3: İş > Projeler > Alpha',
  tree[0].name === 'İş' && tree[0].children[0].name === 'Projeler' && tree[0].children[0].children[0].name === 'Alpha', tree);
r = await a('GET', `/v1/categories/tree?rootId=${projects.id}`);
check('subtree by rootId', r.body.items.length === 1 && r.body.items[0].id === projects.id && r.body.items[0].children.length === 1, r.body);
r = await a('GET', '/v1/categories');
check('flat list has 4', r.body.items.length === 4, r.body);

r = await a('PATCH', `/v1/categories/${work.id}`, { parentId: alpha.id });
check('move into own descendant → 400 (cycle)', r.status === 400 && /descendant/.test(r.body.error.message), r.body);
r = await a('PATCH', `/v1/categories/${work.id}`, { parentId: work.id });
check('self-parent → 400', r.status === 400, r.body);
r = await a('PATCH', `/v1/categories/${alpha.id}`, { parentId: null });
check('move Alpha to root', r.status === 200 && r.body.parentId === null && r.body.order === 2, r.body);
r = await a('PATCH', `/v1/categories/${alpha.id}`, { parentId: projects.id, name: 'Alpha v2' });
check('move back + rename', r.status === 200 && r.body.parentId === projects.id && r.body.name === 'Alpha v2', r.body);

r = await b('GET', `/v1/categories/${work.id}`);
check('other user cannot read category → 404', r.status === 404, r.body);
r = await b('GET', '/v1/categories');
check('other user sees empty list', r.body.items.length === 0, r.body);

console.log('\n[Tasks]');
const t1 = (await a('POST', '/v1/tasks', { title: 'Alpha görevi', categoryId: alpha.id, dueDate: '2026-12-01T09:00:00+03:00' })).body;
const t2 = (await a('POST', '/v1/tasks', { title: 'İş görevi', categoryId: work.id, status: 'done', dueDate: '2026-11-20T09:00:00Z' })).body;
const t3 = (await a('POST', '/v1/tasks', { title: 'Kategorisiz', description: 'not' })).body;
check('create tasks', t1.id && t2.id && t3.id, [t1, t2, t3]);
check('defaults applied (status todo, description "")', t1.status === 'todo' && t1.description === '' && t3.categoryId === null, t1);
check('dueDate normalized to UTC ISO', t1.dueDate === '2026-12-01T06:00:00.000Z', t1.dueDate);
check('done on create sets completedAt', t2.completedAt !== null && t1.completedAt === null, t2);
r = await a('POST', '/v1/tasks', { title: '' });
check('empty title → 400', r.status === 400, r.body);
r = await a('POST', '/v1/tasks', { title: 'x', status: 'blocked' });
check('invalid status → 400', r.status === 400, r.body);
r = await a('POST', '/v1/tasks', { title: 'x', dueDate: '2026-12-01' });
check('non-datetime dueDate → 400', r.status === 400, r.body);
r = await b('POST', '/v1/tasks', { title: 'x', categoryId: work.id });
check("other user's category on task → 400", r.status === 400, r.body);

r = await a('GET', '/v1/tasks');
check('list all → 3, newest first', r.body.items.length === 3 && r.body.items[0].id === t3.id && r.body.nextCursor === null, r.body);
r = await a('GET', '/v1/tasks?status=done');
check('filter status=done', r.body.items.length === 1 && r.body.items[0].id === t2.id, r.body);
r = await a('GET', `/v1/tasks?categoryId=${work.id}`);
check('filter category (direct only)', r.body.items.length === 1 && r.body.items[0].id === t2.id, r.body);
r = await a('GET', `/v1/tasks?categoryId=${work.id}&includeSubcategories=true`);
check('filter category incl. subcategories', r.body.items.length === 2, r.body);
r = await a('GET', '/v1/tasks?categoryId=none');
check('filter uncategorized', r.body.items.length === 1 && r.body.items[0].id === t3.id, r.body);
r = await a('GET', '/v1/tasks?includeSubcategories=true');
check('includeSubcategories without categoryId → 400', r.status === 400, r.body);
r = await a('GET', '/v1/tasks?sort=dueDate');
check('sort dueDate: null first, then ascending', r.body.items.map((t) => t.id).join() === [t3.id, t2.id, t1.id].join(), r.body.items.map((t) => t.title));
r = await a('GET', '/v1/tasks?dueFrom=2026-11-25T00:00:00Z');
check('dueFrom range', r.body.items.length === 1 && r.body.items[0].id === t1.id, r.body);
r = await a('GET', '/v1/tasks?dueFrom=2026-12-25T00:00:00Z&dueTo=2026-11-01T00:00:00Z');
check('dueFrom > dueTo → 400', r.status === 400, r.body);

const p1 = (await a('GET', '/v1/tasks?limit=2')).body;
check('page 1: 2 items + cursor', p1.items.length === 2 && p1.nextCursor === p1.items[1].id, p1);
const p2 = (await a('GET', `/v1/tasks?limit=2&cursor=${p1.nextCursor}`)).body;
check('page 2: 1 item, no cursor', p2.items.length === 1 && p2.nextCursor === null && !p1.items.some((t) => t.id === p2.items[0].id), p2);
r = await b('GET', `/v1/tasks?cursor=${p1.nextCursor}`);
check("other user's cursor → 400", r.status === 400, r.body);

r = await a('PATCH', `/v1/tasks/${t2.id}`, { status: 'in_progress' });
check('leave done clears completedAt', r.status === 200 && r.body.status === 'in_progress' && r.body.completedAt === null, r.body);
r = await a('PATCH', `/v1/tasks/${t1.id}`, { status: 'done', dueDate: null });
check('to done sets completedAt, dueDate cleared', r.body.completedAt !== null && r.body.dueDate === null, r.body);
r = await a('GET', `/v1/tasks/${t1.id}`);
check('PATCH persisted', r.body.status === 'done' && r.body.dueDate === null, r.body);
r = await b('GET', `/v1/tasks/${t1.id}`);
check('other user cannot read task → 404', r.status === 404, r.body);
r = await b('PATCH', `/v1/tasks/${t1.id}`, { title: 'hack' });
check('other user cannot update task → 404', r.status === 404, r.body);

console.log('\n[Category delete]');
r = await a('DELETE', `/v1/categories/${projects.id}?strategy=lift`);
check('lift: Projeler deleted, Alpha moved up', r.status === 200 && r.body.deletedCategoryIds.join() === projects.id && r.body.movedCategoryIds.join() === alpha.id && r.body.detachedTaskCount === 0, r.body);
r = await a('GET', `/v1/categories/${alpha.id}`);
check('Alpha now under İş', r.body.parentId === work.id, r.body);
r = await a('DELETE', `/v1/categories/${work.id}?strategy=bogus`);
check('invalid strategy → 400', r.status === 400, r.body);
r = await a('DELETE', `/v1/categories/${work.id}`);
check('cascade (default): İş + Alpha deleted, 2 tasks detached',
  r.status === 200 && r.body.deletedCategoryIds.length === 2 && r.body.detachedTaskCount === 2, r.body);
r = await a('GET', '/v1/tasks?categoryId=none');
check('detached tasks are uncategorized, not deleted', r.body.items.length === 3, r.body);
r = await a('GET', '/v1/categories/tree');
check('only Kişisel remains', r.body.items.length === 1 && r.body.items[0].id === personal.id, r.body);

console.log('\n[Task delete & misc]');
r = await a('DELETE', `/v1/tasks/${t3.id}`);
check('DELETE task → 204', r.status === 204);
r = await a('GET', `/v1/tasks/${t3.id}`);
check('deleted task → 404', r.status === 404);
r = await a('GET', '/v1/unknown');
check('unknown route → 404 JSON', r.status === 404 && r.body.error.code === 'NOT_FOUND', r.body);
r = await a('POST', '/v1/tasks', undefined, '{"title":');
// Functions runtime JSON'u Express'ten önce ayrıştırır; bozuk gövdeyi kendisi boş 400 ile reddeder.
check('malformed JSON → 400', r.status === 400, r.body);

console.log('\n[Search]');
// Ayrı kullanıcı: önceki adımların görevleri sonuçları etkilemesin.
const s = client(await signUp(`s${run}@test.dev`));
const searchCat = (await s('POST', '/v1/categories', { name: 'Arama' })).body;
const mk = async (title, extra = {}) => (await s('POST', '/v1/tasks', { title, ...extra })).body;
const st1 = await mk('Sprint planlaması', { categoryId: searchCat.id });
const st2 = await mk('Müşteri sunumu', { status: 'done' });
const st3 = await mk('ÇİÇEK SİPARİŞİ');
await mk('Haftalık plan toplantısı', { status: 'done' });
const titles = async (qs) => (await s('GET', `/v1/tasks?${qs}`)).body.items?.map((t) => t.title).sort();

check('task responses do not expose searchTokens', !('searchTokens' in st1), st1);
check('q=plan → word-prefix matches only', JSON.stringify(await titles('q=plan')) === JSON.stringify(['Haftalık plan toplantısı', 'Sprint planlaması']), await titles('q=plan'));
check('case-insensitive (q=PLANLAMASI)', JSON.stringify(await titles('q=PLANLAMASI')) === JSON.stringify(['Sprint planlaması']));
check('Turkish chars folded (q=planlamasi, q=cicek)',
  JSON.stringify(await titles('q=planlamasi')) === JSON.stringify(['Sprint planlaması']) &&
  JSON.stringify(await titles(`q=${encodeURIComponent('çiçek')}`)) === JSON.stringify(['ÇİÇEK SİPARİŞİ']) &&
  JSON.stringify(await titles('q=CICEK')) === JSON.stringify(['ÇİÇEK SİPARİŞİ']));
check('mid-word does not match (q=lamasi)', (await titles('q=lamasi')).length === 0);
check('multi-word: all words must match', JSON.stringify(await titles(`q=${encodeURIComponent('sprint plan')}`)) === JSON.stringify(['Sprint planlaması']) && (await titles(`q=${encodeURIComponent('sprint xyz')}`)).length === 0);
check('search + status filter', JSON.stringify(await titles('q=plan&status=done')) === JSON.stringify(['Haftalık plan toplantısı']));
check('search + category filter', JSON.stringify(await titles(`q=plan&categoryId=${searchCat.id}`)) === JSON.stringify(['Sprint planlaması']));
// array-contains + `in` (alt kategoriler dahil) birlikte çalışmalı.
const searchSub = (await s('POST', '/v1/categories', { name: 'Alt', parentId: searchCat.id })).body;
const stSub = await mk('Plan detayları', { categoryId: searchSub.id });
r = await s('GET', `/v1/tasks?q=plan&categoryId=${searchCat.id}&includeSubcategories=true`);
check('search + includeSubcategories (array-contains + in)',
  r.status === 200 && JSON.stringify(r.body.items.map((t) => t.title).sort()) === JSON.stringify(['Plan detayları', 'Sprint planlaması']), r.body);
await s('DELETE', `/v1/tasks/${stSub.id}`);
check('search + dueDate sort', JSON.stringify(await titles('q=plan&sort=dueDate')) === JSON.stringify(['Haftalık plan toplantısı', 'Sprint planlaması']));
check('punctuation-only q is ignored (all tasks)', (await titles(`q=${encodeURIComponent('...')}`)).length === 4);
r = await s('GET', `/v1/tasks?q=${'x'.repeat(101)}`);
check('q longer than 100 → 400', r.status === 400, r.body);

r = await s('PATCH', `/v1/tasks/${st2.id}`, { title: 'Müşteri planı' });
check('title update refreshes tokens', JSON.stringify(await titles('q=musteri%20plan')) === JSON.stringify(['Müşteri planı']));
r = await s('PATCH', `/v1/tasks/${st3.id}`, { status: 'in_progress' });
check('non-title update keeps tokens', JSON.stringify(await titles('q=siparis')) === JSON.stringify(['ÇİÇEK SİPARİŞİ']));

// Sayfalama: 5 eşleşen + 5 eşleşmeyen (ilk kelime aynı) görev, limit=2, çok kelimeli arama (bellekte eleme).
for (let i = 0; i < 5; i++) await mk(`Rapor haftalık ${i}`);
for (let i = 0; i < 5; i++) await mk(`Rapor aylık ${i}`);
const seen = [];
let cursor = null;
let pages = 0;
do {
  const page = (await s('GET', `/v1/tasks?q=${encodeURIComponent('rapor haftalik')}&limit=2${cursor ? `&cursor=${cursor}` : ''}`)).body;
  seen.push(...page.items.map((t) => t.title));
  cursor = page.nextCursor;
  pages++;
} while (cursor && pages < 10);
check('multi-word search paginates without duplicates or misses',
  seen.length === 5 && new Set(seen).size === 5 && seen.every((t) => t.startsWith('Rapor haftalık')), { seen, pages });

console.log('\n[Docs]');
r = await anon('GET', '/docs.json');
const paths = Object.keys(r.body.paths ?? {});
const ops = paths.flatMap((p) => Object.keys(r.body.paths[p]).map((m) => `${m.toUpperCase()} ${p}`));
check('docs.json has 6 paths / 13 operations', paths.length === 6 && ops.length === 13, ops);
check('server url includes function prefix', r.body.servers?.[0]?.url === '/demo-yourmang/europe-west1/api', r.body.servers);
check('CategoryTreeNode component present', !!r.body.components?.schemas?.CategoryTreeNode);
r = await anon('GET', '/docs');
check('/docs redirects with prefix', r.status === 301 && r.headers.get('location') === '/demo-yourmang/europe-west1/api/docs/', r.headers.get('location'));
r = await anon('GET', '/docs/');
check('/docs/ serves Swagger UI', r.status === 200 && String(r.body).includes('swagger'));

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
