import { Hono } from 'hono';
import { verifyAuth } from '../middleware/auth';

type Bindings = {
  DB: D1Database;
  FIREBASE_PROJECT_ID: string;
};

const app = new Hono<{ Bindings: Bindings; Variables: { userId: string } }>();

// 認証ミドルウェア適用
app.use('*', verifyAuth);

// 店舗一覧取得
app.get('/', async (c) => {
  const userId = c.get('userId');

  const results = await c.env.DB.prepare(
    'SELECT * FROM locations WHERE user_id = ? AND is_active = 1 ORDER BY created_at DESC'
  ).bind(userId).all();

  return c.json({
    success: true,
    data: { locations: results.results || [] },
  });
});

// 店舗登録
app.post('/', async (c) => {
  const userId = c.get('userId');
  const body = await c.req.json();

  // バリデーション
  if (!body.name || typeof body.name !== 'string') {
    return c.json({ success: false, error: 'Invalid name' }, 400);
  }

  // プラン制限チェック（無料プランは1店舗まで）
  const user = await c.env.DB.prepare(
    'SELECT plan FROM users WHERE id = ?'
  ).bind(userId).first();

  if (user && user.plan === 'free') {
    const existingLocations = await c.env.DB.prepare(
      'SELECT COUNT(*) as count FROM locations WHERE user_id = ? AND is_active = 1'
    ).bind(userId).first();

    if (existingLocations && (existingLocations.count as number) >= 1) {
      return c.json({
        success: false,
        error: 'Free plan is limited to 1 location',
      }, 403);
    }
  }

  const locationId = `loc_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  const now = new Date().toISOString();

  await c.env.DB.prepare(
    `INSERT INTO locations (id, user_id, name, address, is_active, created_at, updated_at)
     VALUES (?, ?, ?, ?, 1, ?, ?)`
  ).bind(
    locationId,
    userId,
    body.name,
    body.address || null,
    now,
    now
  ).run();

  const location = await c.env.DB.prepare(
    'SELECT * FROM locations WHERE id = ?'
  ).bind(locationId).first();

  return c.json({
    success: true,
    data: { location },
  }, 201);
});

// 店舗更新
app.put('/:id', async (c) => {
  const userId = c.get('userId');
  const locationId = c.req.param('id');
  const body = await c.req.json();

  // 所有権チェック
  const location = await c.env.DB.prepare(
    'SELECT * FROM locations WHERE id = ? AND user_id = ?'
  ).bind(locationId, userId).first();

  if (!location) {
    return c.json({ success: false, error: 'Location not found' }, 404);
  }

  const now = new Date().toISOString();

  await c.env.DB.prepare(
    `UPDATE locations
     SET name = ?, address = ?, updated_at = ?
     WHERE id = ? AND user_id = ?`
  ).bind(
    body.name || location.name,
    body.address !== undefined ? body.address : location.address,
    now,
    locationId,
    userId
  ).run();

  const updated = await c.env.DB.prepare(
    'SELECT * FROM locations WHERE id = ?'
  ).bind(locationId).first();

  return c.json({
    success: true,
    data: { location: updated },
  });
});

// 店舗削除（論理削除）
app.delete('/:id', async (c) => {
  const userId = c.get('userId');
  const locationId = c.req.param('id');

  // 所有権チェック
  const location = await c.env.DB.prepare(
    'SELECT * FROM locations WHERE id = ? AND user_id = ?'
  ).bind(locationId, userId).first();

  if (!location) {
    return c.json({ success: false, error: 'Location not found' }, 404);
  }

  const now = new Date().toISOString();

  await c.env.DB.prepare(
    'UPDATE locations SET is_active = 0, updated_at = ? WHERE id = ?'
  ).bind(now, locationId).run();

  return c.json({
    success: true,
    data: { message: 'Location deleted successfully' },
  });
});

// 特定店舗の記録ポイント一覧取得
app.get('/:id/checkpoints', async (c) => {
  const userId = c.get('userId');
  const locationId = c.req.param('id');

  // 所有権チェック
  const location = await c.env.DB.prepare(
    'SELECT * FROM locations WHERE id = ? AND user_id = ?'
  ).bind(locationId, userId).first();

  if (!location) {
    return c.json({ success: false, error: 'Location not found' }, 404);
  }

  const results = await c.env.DB.prepare(
    'SELECT * FROM checkpoints WHERE location_id = ? AND is_active = 1 ORDER BY sort_order, created_at'
  ).bind(locationId).all();

  return c.json({
    success: true,
    data: { checkpoints: results.results || [] },
  });
});

export default app;
