import type { Request } from 'express';

export const REGION = 'europe-west1';
/** index.ts'teki export adı — URL'de fonksiyon adı olarak görünür. */
export const FUNCTION_NAME = 'api';

export const isEmulator = process.env.FUNCTIONS_EMULATOR === 'true';

/**
 * API'nin dışarıdan görünen taban yolu. Functions altyapısı Express'e gelen URL'den bu öneki siler,
 * bu yüzden Swagger "Try it out" ve yönlendirmeler için ortama göre hesaplanır:
 *  - Emülatör:            /<project>/<region>/api
 *  - *.cloudfunctions.net: /api
 *  - Cloud Run URL / Hosting rewrite: '' (önek yok)
 */
export function publicBasePath(req: Request): string {
  if (isEmulator) return `/${process.env.GCLOUD_PROJECT}/${REGION}/${FUNCTION_NAME}`;
  return req.hostname.endsWith('cloudfunctions.net') ? `/${FUNCTION_NAME}` : '';
}
