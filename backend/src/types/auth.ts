/** Doğrulanmış Firebase ID token'dan çıkarılan kullanıcı bilgisi. */
export interface AuthUser {
  uid: string;
  email: string | null;
  name: string | null;
  picture: string | null;
  emailVerified: boolean;
}
