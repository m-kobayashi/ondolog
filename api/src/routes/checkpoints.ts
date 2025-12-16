import { Hono } from 'hono';
import { verifyAuth } from '../middleware/auth';

type Bindings = {
  DB: D1Database;
  FIREBASE_PROJECT_ID: string;
};

const app = new Hono<{ Bindings: Bindings; Variables: { userId: string } }>();

// 認証ミドルウェア適用
app.use('*', verifyAuth);

// 記録ポイント登録
app.post('/', async (c) => {
  const userId = c.get('userId');
  const body = await c.req.json();

  // バリデーション
  if (!body.location_id || !body.name || !body.checkpoint_type) {
    return c.json({
      success: false,
      error: 'Missing required fields: location_id, name, checkpoint_type',
    }, 400);
  }

  // 店舗の所有権チェック
  const location = await c.env.DB.prepare(
    'SELECT * FROM locations WHERE id = ? AND user_id = ?'
  ).bind(body.location_id, userId).first();

  if (!location) {
    return c.json({ success: false, error: 'Location not found' }, 404);
  }

  // プラン制限チェック（無料プランは3ポイントまで）
  const user = await c.env.DB.prepare(
    'SELECT plan FROM users WHERE id = ?'
  ).bind(userId).first();

  if (user && user.plan === 'free') {
    const existingCheckpoints = await c.env.DB.prepare(
      `SELECT COUNT(*) as count FROM checkpoints c
       INNER JOIN locations l ON c.location_id = l.id
       WHERE l.user_id = ? AND c.is_active = 1`
    ).bind(userId).first();

    if (existingCheckpoints && (existingCheckpoints.count as number) >= 3) {
      return c.json({
        success: false,
        error: 'Free plan is limited to 3 checkpoints',
      }, 403);
    }
  }

  const checkpointId = `cp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  const now = new Date().toISOString();

  await c.env.DB.prepare(
    `INSERT INTO checkpoints (id, location_id, name, checkpoint_type, min_temp, max_temp, sort_order, is_active, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)`
  ).bind(
    checkpointId,
    body.location_id,
    body.name,
    body.checkpoint_type,
    body.min_temp || null,
    body.max_temp || null,
    body.sort_order || 0,
    now,
    now
  ).run();

  const checkpoint = await c.env.DB.prepare(
    'SELECT * FROM checkpoints WHERE id = ?'
  ).bind(checkpointId).first();

  return c.json({
    success: true,
    data: { checkpoint },
  }, 201);
});

// 記録ポイント更新
app.put('/:id', async (c) => {
  const userId = c.get('userId');
  const checkpointId = c.req.param('id');
  const body = await c.req.json();

  // 所有権チェック
  const checkpoint = await c.env.DB.prepare(
    `SELECT c.* FROM checkpoints c
     INNER JOIN locations l ON c.location_id = l.id
     WHERE c.id = ? AND l.user_id = ?`
  ).bind(checkpointId, userId).first();

  if (!checkpoint) {
    return c.json({ success: false, error: 'Checkpoint not found' }, 404);
  }

  const now = new Date().toISOString();

  await c.env.DB.prepare(
    `UPDATE checkpoints
     SET name = ?, checkpoint_type = ?, min_temp = ?, max_temp = ?, sort_order = ?, updated_at = ?
     WHERE id = ?`
  ).bind(
    body.name || checkpoint.name,
    body.checkpoint_type || checkpoint.checkpoint_type,
    body.min_temp !== undefined ? body.min_temp : checkpoint.min_temp,
    body.max_temp !== undefined ? body.max_temp : checkpoint.max_temp,
    body.sort_order !== undefined ? body.sort_order : checkpoint.sort_order,
    now,
    checkpointId
  ).run();

  const updated = await c.env.DB.prepare(
    'SELECT * FROM checkpoints WHERE id = ?'
  ).bind(checkpointId).first();

  return c.json({
    success: true,
    data: { checkpoint: updated },
  });
});

// 記録ポイント削除（論理削除）
app.delete('/:id', async (c) => {
  const userId = c.get('userId');
  const checkpointId = c.req.param('id');

  // 所有権チェック
  const checkpoint = await c.env.DB.prepare(
    `SELECT c.* FROM checkpoints c
     INNER JOIN locations l ON c.location_id = l.id
     WHERE c.id = ? AND l.user_id = ?`
  ).bind(checkpointId, userId).first();

  if (!checkpoint) {
    return c.json({ success: false, error: 'Checkpoint not found' }, 404);
  }

  const now = new Date().toISOString();

  await c.env.DB.prepare(
    'UPDATE checkpoints SET is_active = 0, updated_at = ? WHERE id = ?'
  ).bind(now, checkpointId).run();

  return c.json({
    success: true,
    data: { message: 'Checkpoint deleted successfully' },
  });
});

export default app;
