// Birim testleri (Node yerleşik test koşucusu): npm run test:unit
import assert from 'node:assert/strict';
import { describe, test } from 'node:test';
import {
  MAX_TOKEN_LENGTH,
  buildSearchTokens,
  normalizeForSearch,
  planSearch,
  searchWords,
  titleMatches,
} from '../lib/utils/search.js';

describe('normalizeForSearch', () => {
  test('Türkçe büyük/küçük harf ve karakter sadeleştirme', () => {
    assert.equal(normalizeForSearch('ÇİÇEK Şişe IĞDIR Ömür Ülkü'), 'cicek sise igdir omur ulku');
    assert.equal(normalizeForSearch('ılık İnce'), 'ilik ince');
  });

  test('diğer aksanlar atılır', () => {
    assert.equal(normalizeForSearch('Café Crème naïve'), 'cafe creme naive');
  });
});

describe('searchWords', () => {
  test('noktalama ve tire ayırıcıdır', () => {
    assert.deepEqual(searchWords('API-dokümantasyonu (v2), #acil!'), ['api', 'dokumantasyonu', 'v2', 'acil']);
  });
  test('boş / yalnızca noktalama', () => {
    assert.deepEqual(searchWords('  ...  '), []);
  });
});

describe('buildSearchTokens', () => {
  const tokens = buildSearchTokens('Sprint planlaması');

  test('her kelimenin tüm önekleri', () => {
    for (const t of ['s', 'sp', 'sprint', 'p', 'plan', 'planlamasi']) assert.ok(tokens.includes(t), t);
  });

  test('kelime ortası token değildir', () => {
    assert.ok(!tokens.includes('lamasi'));
    assert.ok(!tokens.includes('rint'));
  });

  test('tekrarsız', () => {
    const t = buildSearchTokens('plan plan planla');
    assert.equal(new Set(t).size, t.length);
  });

  test(`uzun kelimeler ${MAX_TOKEN_LENGTH} karakterde kesilir`, () => {
    const t = buildSearchTokens('Muvaffakiyetsizleştiricileştiriveremeyebileceklerimizdenmişsinizcesine');
    assert.equal(Math.max(...t.map((x) => x.length)), MAX_TOKEN_LENGTH);
  });

  test('boş başlık → boş dizi', () => {
    assert.deepEqual(buildSearchTokens(''), []);
  });
});

describe('planSearch / titleMatches', () => {
  test('boş sorgu plansızdır', () => {
    assert.equal(planSearch('   '), null);
    assert.equal(planSearch('!!'), null);
  });

  test('en uzun kelime Firestore token\'ı olur, tüm kelimeler eleme için tutulur', () => {
    assert.deepEqual(planSearch('Sprint PLAN'), { token: 'sprint', words: ['sprint', 'plan'] });
  });

  test('uzun sorgu kelimesi token için kesilir ama eleme tam kelimeyle yapılır', () => {
    const plan = planSearch('dokumantasyonunu');
    assert.equal(plan.token, 'dokumantasyonun'.slice(0, MAX_TOKEN_LENGTH));
    assert.equal(titleMatches('API dokümantasyonunu güncelle', plan.words), true);
    assert.equal(titleMatches('API dokümantasyonu yaz', plan.words), false, 'ilk 15 karakter aynı ama kelime farklı');
  });

  test('her sorgu kelimesi bir başlık kelimesinin öneki olmalı', () => {
    assert.equal(titleMatches('Sprint planlaması', ['spr', 'plan']), true);
    assert.equal(titleMatches('Sprint planlaması', ['sprint', 'xyz']), false);
    assert.equal(titleMatches('Sprint planlaması', ['lama']), false);
  });

  test('sorgu ve başlık aynı normalizasyondan geçer', () => {
    const plan = planSearch('ÇİÇEK');
    assert.ok(buildSearchTokens('çiçek siparişi').includes(plan.token));
    assert.equal(titleMatches('Çiçek siparişi', plan.words), true);
  });
});
