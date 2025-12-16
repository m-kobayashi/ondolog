import { Hono } from 'hono';
import { generateUserId, generateLocationId, generateCheckpointId } from '../utils/id';
import { successResponse, validationError, serverError, authError } from '../utils/response';

type Bindings = {
  DB: D1Database;
  FIREBASE_PROJECT_ID: string;
};

const auth = new Hono<{ Bindings: Bindings }>();

/**
 * POST /api/auth/register
 * ユーザー登録
 *
 * Request Body:
 * {
 *   "firebase_uid": "string",
 *   "email": "string",
 *   "display_name": "string",
 *   "business_name": "string",
 *   "business_type": "restaurant" | "factory" | "cafeteria" | "other"
 * }
 */
auth.post('/register', async (c) => {
  try {
    const body = await c.req.json();
    const { firebase_uid, email, display_name, business_name, business_type } = body;

    // バリデーション
    if (!firebase_uid || typeof firebase_uid !== 'string') {
      return validationError(c, 'firebase_uidは必須です');
    }

    if (!email || typeof email !== 'string' || !email.includes('@')) {
      return validationError(c, '有効なメールアドレスを入力してください');
    }

    if (business_type && !['restaurant', 'factory', 'cafeteria', 'other'].includes(business_type)) {
      return validationError(c, 'business_typeが不正です');
    }

    // 既存ユーザーチェック
    const existingUser = await c.env.DB.prepare(
      'SELECT id FROM users WHERE firebase_uid = ?'
    ).bind(firebase_uid).first();

    if (existingUser) {
      return authError(c, 'すでに登録済みのユーザーです');
    }

    // ユーザー作成
    const userId = generateUserId();
    const now = new Date().toISOString();

    await c.env.DB.prepare(
      `INSERT INTO users (id, firebase_uid, email, display_name, business_name, business_type, plan, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, 'free', ?, ?)`
    ).bind(
      userId,
      firebase_uid,
      email,
      display_name || null,
      business_name || null,
      business_type || null,
      now,
      now
    ).run();

    // デフォルト店舗を作成（無料プランは1店舗のみ）
    const locationId = generateLocationId();
    await c.env.DB.prepare(
      `INSERT INTO locations (id, user_id, name, address, is_active, created_at, updated_at)
       VALUES (?, ?, ?, NULL, 1, ?, ?)`
    ).bind(
      locationId,
      userId,
      business_name || '本店',
      now,
      now
    ).run();

    // デフォルトの記録ポイントを作成（無料プランは3箇所まで）
    const defaultCheckpoints = [
      {
        id: generateCheckpointId(),
        name: '冷蔵庫A',
        type: 'refrigerator',
        min_temp: 0,
        max_temp: 10,
        sort_order: 1,
      },
      {
        id: generateCheckpointId(),
        name: '冷凍庫',
        type: 'freezer',
        min_temp: -25,
        max_temp: -15,
        sort_order: 2,
      },
      {
        id: generateCheckpointId(),
        name: '調理場',
        type: 'cooking_area',
        min_temp: 15,
        max_temp: 25,
        sort_order: 3,
      },
    ];

    for (const checkpoint of defaultCheckpoints) {
      await c.env.DB.prepare(
        `INSERT INTO checkpoints (id, location_id, name, checkpoint_type, min_temp, max_temp, sort_order, is_active, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)`
      ).bind(
        checkpoint.id,
        locationId,
        checkpoint.name,
        checkpoint.type,
        checkpoint.min_temp,
        checkpoint.max_temp,
        checkpoint.sort_order,
        now,
        now
      ).run();
    }

    // 作成されたユーザー情報を取得
    const user = await c.env.DB.prepare(
      'SELECT id, firebase_uid, email, display_name, business_name, business_type, plan, created_at FROM users WHERE id = ?'
    ).bind(userId).first();

    return successResponse(c, {
      user,
      location: {
        id: locationId,
        name: business_name || '本店',
      },
      checkpoints: defaultCheckpoints.map(cp => ({
        id: cp.id,
        name: cp.name,
        type: cp.type,
      })),
    }, 201);

  } catch (error) {
    console.error('ユーザー登録エラー:', error);
    return serverError(c, 'ユーザー登録に失敗しました', {
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

export default auth;
