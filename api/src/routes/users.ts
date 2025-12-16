import { Hono } from 'hono';
import { authMiddleware } from '../middleware/auth';
import { successResponse, validationError, serverError, notFoundError } from '../utils/response';

type Bindings = {
  DB: D1Database;
  FIREBASE_PROJECT_ID: string;
};

const users = new Hono<{ Bindings: Bindings }>();

// 認証ミドルウェアを適用
users.use('*', authMiddleware);

/**
 * GET /api/users/me
 * ログイン中のユーザー情報を取得
 */
users.get('/me', async (c) => {
  try {
    const firebaseUid = c.get('firebaseUid') as string;

    const user = await c.env.DB.prepare(
      `SELECT
        id,
        firebase_uid,
        email,
        display_name,
        business_name,
        business_type,
        plan,
        created_at,
        updated_at
       FROM users
       WHERE firebase_uid = ?`
    ).bind(firebaseUid).first();

    if (!user) {
      return notFoundError(c, 'ユーザーが見つかりません');
    }

    // ユーザーに紐づく店舗情報も取得
    const locations = await c.env.DB.prepare(
      `SELECT id, name, address, is_active, created_at, updated_at
       FROM locations
       WHERE user_id = ? AND is_active = 1
       ORDER BY created_at ASC`
    ).bind(user.id).all();

    // プラン制限情報を追加
    const planLimits = getPlanLimits(user.plan as string);

    return successResponse(c, {
      user,
      locations: locations.results || [],
      plan_limits: planLimits,
    });

  } catch (error) {
    console.error('ユーザー情報取得エラー:', error);
    return serverError(c, 'ユーザー情報の取得に失敗しました', {
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

/**
 * PUT /api/users/me
 * ユーザー情報を更新
 *
 * Request Body:
 * {
 *   "display_name"?: "string",
 *   "business_name"?: "string",
 *   "business_type"?: "restaurant" | "factory" | "cafeteria" | "other"
 * }
 */
users.put('/me', async (c) => {
  try {
    const firebaseUid = c.get('firebaseUid') as string;
    const body = await c.req.json();
    const { display_name, business_name, business_type } = body;

    // バリデーション
    if (business_type && !['restaurant', 'factory', 'cafeteria', 'other'].includes(business_type)) {
      return validationError(c, 'business_typeが不正です');
    }

    // 現在のユーザー情報を取得
    const currentUser = await c.env.DB.prepare(
      'SELECT id FROM users WHERE firebase_uid = ?'
    ).bind(firebaseUid).first();

    if (!currentUser) {
      return notFoundError(c, 'ユーザーが見つかりません');
    }

    // 更新フィールドを動的に構築
    const updates: string[] = [];
    const params: any[] = [];

    if (display_name !== undefined) {
      updates.push('display_name = ?');
      params.push(display_name);
    }

    if (business_name !== undefined) {
      updates.push('business_name = ?');
      params.push(business_name);
    }

    if (business_type !== undefined) {
      updates.push('business_type = ?');
      params.push(business_type);
    }

    if (updates.length === 0) {
      return validationError(c, '更新する項目が指定されていません');
    }

    // updated_at を追加
    updates.push('updated_at = ?');
    params.push(new Date().toISOString());

    // WHERE句のパラメータを追加
    params.push(firebaseUid);

    // 更新実行
    await c.env.DB.prepare(
      `UPDATE users SET ${updates.join(', ')} WHERE firebase_uid = ?`
    ).bind(...params).run();

    // 更新後のユーザー情報を取得
    const updatedUser = await c.env.DB.prepare(
      `SELECT
        id,
        firebase_uid,
        email,
        display_name,
        business_name,
        business_type,
        plan,
        created_at,
        updated_at
       FROM users
       WHERE firebase_uid = ?`
    ).bind(firebaseUid).first();

    return successResponse(c, {
      user: updatedUser,
    });

  } catch (error) {
    console.error('ユーザー情報更新エラー:', error);
    return serverError(c, 'ユーザー情報の更新に失敗しました', {
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

/**
 * プラン別の制限情報を取得
 */
function getPlanLimits(plan: string) {
  const limits: Record<string, any> = {
    free: {
      max_locations: 1,
      max_checkpoints_per_location: 3,
      max_records_per_day: 2,
      data_retention_days: 365,
      export_enabled: false,
      alert_enabled: false,
    },
    premium: {
      max_locations: 10,
      max_checkpoints_per_location: 20,
      max_records_per_day: -1, // 無制限
      data_retention_days: -1, // 無制限
      export_enabled: true,
      alert_enabled: true,
    },
  };

  return limits[plan] || limits.free;
}

export default users;
