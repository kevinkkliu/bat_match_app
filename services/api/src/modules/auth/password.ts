import { pbkdf2Sync, randomBytes, timingSafeEqual } from 'node:crypto';

const PASSWORD_HASH_ALGORITHM = 'pbkdf2';
const PASSWORD_HASH_DIGEST = 'sha256';
const PASSWORD_HASH_ITERATIONS = 120_000;
const PASSWORD_HASH_KEY_LENGTH = 32;

export function hashPassword(password: string): string {
  const salt = randomBytes(16).toString('hex');
  const hash = pbkdf2Sync(
    password,
    salt,
    PASSWORD_HASH_ITERATIONS,
    PASSWORD_HASH_KEY_LENGTH,
    PASSWORD_HASH_DIGEST
  ).toString('hex');

  return [
    PASSWORD_HASH_ALGORITHM,
    PASSWORD_HASH_ITERATIONS.toString(),
    salt,
    hash,
  ].join('$');
}

export function verifyPassword(password: string, passwordHash: string): boolean {
  const [algorithm, iterationsRaw, salt, encodedHash] = passwordHash.split('$');

  if (
    algorithm !== PASSWORD_HASH_ALGORITHM ||
    !iterationsRaw ||
    !salt ||
    !encodedHash
  ) {
    return false;
  }

  const iterations = Number.parseInt(iterationsRaw, 10);

  if (!Number.isFinite(iterations) || iterations <= 0) {
    return false;
  }

  try {
    const derived = pbkdf2Sync(
      password,
      salt,
      iterations,
      PASSWORD_HASH_KEY_LENGTH,
      PASSWORD_HASH_DIGEST
    );
    const stored = Buffer.from(encodedHash, 'hex');

    return stored.length === derived.length && timingSafeEqual(stored, derived);
  } catch {
    return false;
  }
}
