export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly errorCode: string,
    message: string,
    public readonly details?: unknown
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export function notImplemented(message: string): never {
  throw new AppError(501, 'NOT_IMPLEMENTED', message);
}
