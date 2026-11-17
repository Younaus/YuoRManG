/** Derleme zamanında iki tipin birebir eşit olduğunu doğrular (Zod şeması ↔ model DTO). */
export type Equals<A, B> =
  (<T>() => T extends A ? 1 : 2) extends <T>() => T extends B ? 1 : 2 ? true : false;
export type Assert<T extends true> = T;
