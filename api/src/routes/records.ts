import { Hono } from 'hono';
import { verifyAuth } from '../middleware/auth';

type Bindings = {
  DB: D1Database;
  FIREBASE_PROJECT_ID: string;
};

const app = new Hono<{ Bindings: Bindings; Variables: { userId: string } }>();

// 認証ミドルウェア適用
app.use('*', verifyAuth);

// 温度記録一覧取得
app.get('/', async (c) => {
  const userId = c.get('userId');
  const locationId = c.req.query('location_id');
  const startDate = c.req.query('start_date');
  const endDate = c.req.query('end_date');

  let query = `
    SELECT r.* FROM records r
    INNER JOIN checkpoints cp ON r.checkpoint_id = cp.id
    INNER JOIN locations l ON cp.location_id = l.id
    WHERE l.user_id = ?
  `;
  const params: any[] = [userId];

  if (locationId) {
    query += ' AND l.id = ?';
    params.push(locationId);
  }

  if (startDate) {
    query += ' AND r.recorded_at >= ?';
    params.push(startDate);
  }

  if (endDate) {
    query += ' AND r.recorded_at <= ?';
    params.push(endDate);
  }

  query += ' ORDER BY r.recorded_at DESC LIMIT 100';

  const stmt = c.env.DB.prepare(query);
  const results = await stmt.bind(...params).all();

  return c.json({
    success: true,
    data: { records: results.results || [] },
  });
});

// 日別記録取得
app.get('/daily/:date', async (c) => {
  const userId = c.get('userId');
  const date = c.req.param('date'); // YYYY-MM-DD形式
  const locationId = c.req.query('location_id');

  // 日付の開始と終了を計算
  const startOfDay = `${date}T00:00:00Z`;
  const endOfDay = `${date}T23:59:59Z`;

  let query = `
    SELECT r.*, cp.name as checkpoint_name, cp.checkpoint_type, cp.min_temp, cp.max_temp
    FROM records r
    INNER JOIN checkpoints cp ON r.checkpoint_id = cp.id
    INNER JOIN locations l ON cp.location_id = l.id
    WHERE l.user_id = ?
    AND r.recorded_at >= ?
    AND r.recorded_at <= ?
  `;
  const params: any[] = [userId, startOfDay, endOfDay];

  if (locationId) {
    query += ' AND l.id = ?';
    params.push(locationId);
  }

  query += ' ORDER BY r.recorded_at ASC';

  const stmt = c.env.DB.prepare(query);
  const results = await stmt.bind(...params).all();

  return c.json({
    success: true,
    data: {
      date,
      records: results.results || [],
    },
  });
});

// 単一記録登録
app.post('/', async (c) => {
  const userId = c.get('userId');
  const body = await c.req.json();

  // バリデーション
  if (!body.checkpoint_id || body.temperature === undefined) {
    return c.json({
      success: false,
      error: 'Missing required fields: checkpoint_id, temperature',
    }, 400);
  }

  // チェックポイントの所有権チェック
  const checkpoint = await c.env.DB.prepare(
    `SELECT cp.*, l.user_id FROM checkpoints cp
     INNER JOIN locations l ON cp.location_id = l.id
     WHERE cp.id = ? AND l.user_id = ?`
  ).bind(body.checkpoint_id, userId).first();

  if (!checkpoint) {
    return c.json({ success: false, error: 'Checkpoint not found' }, 404);
  }

  // 異常値判定
  const temperature = parseFloat(body.temperature);
  let isAbnormal = false;

  if (checkpoint.min_temp !== null && temperature < checkpoint.min_temp) {
    isAbnormal = true;
  }
  if (checkpoint.max_temp !== null && temperature > checkpoint.max_temp) {
    isAbnormal = true;
  }

  // 異常値の場合、対応メモが必須
  if (isAbnormal && !body.abnormal_action) {
    return c.json({
      success: false,
      error: 'Abnormal action is required for abnormal temperature',
    }, 400);
  }

  const recordId = `rec_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  const now = new Date().toISOString();
  const recordedAt = body.recorded_at || now;

  await c.env.DB.prepare(
    `INSERT INTO records (id, checkpoint_id, temperature, recorded_at, recorded_by, is_abnormal, abnormal_action, notes, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
  ).bind(
    recordId,
    body.checkpoint_id,
    temperature,
    recordedAt,
    body.recorded_by || null,
    isAbnormal ? 1 : 0,
    body.abnormal_action || null,
    body.notes || null,
    now
  ).run();

  const record = await c.env.DB.prepare(
    'SELECT * FROM records WHERE id = ?'
  ).bind(recordId).first();

  return c.json({
    success: true,
    data: { record, is_abnormal: isAbnormal },
  }, 201);
});

// 一括記録登録
app.post('/bulk', async (c) => {
  const userId = c.get('userId');
  const body = await c.req.json();

  if (!body.records || !Array.isArray(body.records) || body.records.length === 0) {
    return c.json({
      success: false,
      error: 'Invalid records array',
    }, 400);
  }

  const now = new Date().toISOString();
  const results = [];
  let abnormalCount = 0;

  for (const rec of body.records) {
    // バリデーション
    if (!rec.checkpoint_id || rec.temperature === undefined) {
      return c.json({
        success: false,
        error: 'Each record must have checkpoint_id and temperature',
      }, 400);
    }

    // チェックポイントの所有権チェック
    const checkpoint = await c.env.DB.prepare(
      `SELECT cp.*, l.user_id FROM checkpoints cp
       INNER JOIN locations l ON cp.location_id = l.id
       WHERE cp.id = ? AND l.user_id = ?`
    ).bind(rec.checkpoint_id, userId).first();

    if (!checkpoint) {
      return c.json({
        success: false,
        error: `Checkpoint not found: ${rec.checkpoint_id}`,
      }, 404);
    }

    // 異常値判定
    const temperature = parseFloat(rec.temperature);
    let isAbnormal = false;

    if (checkpoint.min_temp !== null && temperature < checkpoint.min_temp) {
      isAbnormal = true;
    }
    if (checkpoint.max_temp !== null && temperature > checkpoint.max_temp) {
      isAbnormal = true;
    }

    if (isAbnormal) {
      abnormalCount++;
    }

    // 異常値の場合、対応メモが必須
    if (isAbnormal && !rec.abnormal_action) {
      return c.json({
        success: false,
        error: `Abnormal action is required for abnormal temperature at checkpoint ${rec.checkpoint_id}`,
      }, 400);
    }

    const recordId = `rec_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const recordedAt = rec.recorded_at || now;

    await c.env.DB.prepare(
      `INSERT INTO records (id, checkpoint_id, temperature, recorded_at, recorded_by, is_abnormal, abnormal_action, notes, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(
      recordId,
      rec.checkpoint_id,
      temperature,
      recordedAt,
      rec.recorded_by || null,
      isAbnormal ? 1 : 0,
      rec.abnormal_action || null,
      rec.notes || null,
      now
    ).run();

    results.push({
      id: recordId,
      checkpoint_id: rec.checkpoint_id,
      is_abnormal: isAbnormal,
    });
  }

  return c.json({
    success: true,
    data: {
      recorded_count: results.length,
      abnormal_count: abnormalCount,
      records: results,
    },
  }, 201);
});

export default app;
