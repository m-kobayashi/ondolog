import { Hono } from 'hono';
import { cors } from 'hono/cors';
import auth from './routes/auth';
import users from './routes/users';

type Bindings = {
  DB: D1Database;
  // IMAGES: R2Bucket;
  FIREBASE_PROJECT_ID: string;
};

const app = new Hono<{ Bindings: Bindings }>();

// CORS設定
app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}));

// Health check
app.get('/', (c) => c.json({ status: 'ok', service: 'ondolog' }));

// API routes
app.get('/api/health', (c) => c.json({
  status: 'healthy',
  timestamp: new Date().toISOString()
}));

// ルーティング
app.route('/api/auth', auth);
app.route('/api/users', users);

// TODO: 以下のルートを追加予定
// app.route('/api/locations', locations);
// app.route('/api/checkpoints', checkpoints);
// app.route('/api/records', records);

export default app;
