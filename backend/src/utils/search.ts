/**
 * Görev başlığında kelime öneki araması (Firestore `array-contains` ile).
 *
 * Firestore tam metin / alt dize araması desteklemez. Bunun yerine her görev yazılırken başlığın
 * normalize edilmiş kelimelerinin önekleri `searchTokens` dizisinde saklanır:
 *   "Sprint planlaması" → [s, sp, spr, …, sprint, p, pl, …, planlamasi]
 * Arama sorgusundaki bir kelime bu dizide aranır; böylece "plan", "PLAN" ve "planlamasi"
 * aynı görevi bulur. Kelimenin ortası ("lamasi") eşleşmez.
 *
 * Bu modül saf fonksiyonlardan oluşur (Firestore bağımlılığı yok) ve migration betiği de
 * aynı fonksiyonları kullanır — token üretimi tek yerde tanımlıdır.
 */

/** Bir kelimeden üretilecek en uzun önek. Daha uzun kelimeler bu uzunlukta kesilip aranır, son eleme tam kelimeyle yapılır. */
export const MAX_TOKEN_LENGTH = 15;

/** Bir görevdeki en fazla token sayısı (200 karakterlik başlık için fazlasıyla yeterli; belge boyutunu sınırlar). */
export const MAX_TOKENS = 300;

const TURKISH_FOLD: Record<string, string> = { ı: 'i', ş: 's', ğ: 'g', ü: 'u', ö: 'o', ç: 'c' };

/**
 * Aramaya uygun biçim: Türkçe kurallarla küçük harf (I→ı, İ→i), Türkçe karakter sadeleştirme
 * (ı ş ğ ü ö ç → i s g u o c) ve diğer aksanların atılması (é → e).
 */
export function normalizeForSearch(text: string): string {
  return text
    .toLocaleLowerCase('tr-TR')
    .replace(/[ışğüöç]/g, (ch) => TURKISH_FOLD[ch])
    .normalize('NFKD')
    .replace(/\p{M}+/gu, '');
}

/** Normalize edilmiş kelimeler (harf/rakam dışındaki her şey ayırıcıdır). */
export function searchWords(text: string): string[] {
  return normalizeForSearch(text)
    .split(/[^\p{L}\p{N}]+/u)
    .filter((w) => w.length > 0);
}

/** Kod noktası bazında kesme (çok baytlı karakterleri bölmemek için). */
function prefix(word: string, length: number): string {
  return Array.from(word).slice(0, length).join('');
}

/** Başlıktan `searchTokens` dizisini üretir (tekrarsız, sıralı değil). */
export function buildSearchTokens(title: string): string[] {
  const tokens = new Set<string>();
  for (const word of searchWords(title)) {
    const chars = Array.from(word);
    const max = Math.min(chars.length, MAX_TOKEN_LENGTH);
    for (let i = 1; i <= max && tokens.size < MAX_TOKENS; i++) {
      tokens.add(chars.slice(0, i).join(''));
    }
  }
  return [...tokens];
}

export interface SearchPlan {
  /** Firestore'da `array-contains` ile aranacak tek token (en uzun kelime — en seçici filtre). */
  token: string;
  /** Sonuçların sunucuda ayrıca kontrol edileceği tüm sorgu kelimeleri. */
  words: string[];
}

/** Sorgu metninden arama planı; aranabilir kelime yoksa `null`. */
export function planSearch(query: string): SearchPlan | null {
  const words = [...new Set(searchWords(query))];
  if (words.length === 0) return null;
  const longest = words.reduce((a, b) => (Array.from(b).length > Array.from(a).length ? b : a));
  return { token: prefix(longest, MAX_TOKEN_LENGTH), words };
}

/** Her sorgu kelimesi, başlıktaki bir kelimenin öneki mi? (çok kelimeli sorgular ve uzun kelimeler için) */
export function titleMatches(title: string, words: readonly string[]): boolean {
  const titleWords = searchWords(title);
  return words.every((w) => titleWords.some((tw) => tw.startsWith(w)));
}
