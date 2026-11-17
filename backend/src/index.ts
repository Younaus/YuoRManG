import { setGlobalOptions } from 'firebase-functions/v2';
import { onRequest } from 'firebase-functions/v2/https';
import { createApp } from './app.js';
import { REGION } from './config/env.js';

setGlobalOptions({
  region: REGION,
  maxInstances: 10,
  memory: '256MiB',
});

export const api = onRequest(createApp());
