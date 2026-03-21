import { buildApp } from './app';
import { loadEnv } from './lib/config';

async function start(): Promise<void> {
  const env = loadEnv();
  const app = buildApp(env);

  try {
    await app.listen({
      host: env.HOST,
      port: env.PORT,
    });
  } catch (error) {
    app.log.error(error);
    process.exit(1);
  }
}

void start();
