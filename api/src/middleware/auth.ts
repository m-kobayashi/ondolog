import { Context, Next } from 'hono';
import { authError, serverError } from '../utils/response';

/**
 * Firebase ID Tokenの検証
 *
 * Cloudflare Workersでは firebase-admin が使用できないため、
 * Googleの公開鍵を使ってJWTを検証する
 */

interface DecodedToken {
  uid: string;
  email?: string;
  email_verified?: boolean;
  [key: string]: any;
}

interface JWKKey {
  kid: string;
  n: string;
  e: string;
  kty: string;
  alg: string;
  use: string;
}

/**
 * Googleの公開鍵をキャッシュ（Cloudflare KVまたはメモリ）
 */
let publicKeysCache: { keys: JWKKey[]; expiry: number } | null = null;

/**
 * Googleの公開鍵を取得
 */
async function fetchGooglePublicKeys(): Promise<JWKKey[]> {
  // キャッシュが有効な場合はそれを返す
  if (publicKeysCache && publicKeysCache.expiry > Date.now()) {
    return publicKeysCache.keys;
  }

  const response = await fetch(
    'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'
  );

  if (!response.ok) {
    throw new Error('公開鍵の取得に失敗しました');
  }

  const certs = await response.json() as Record<string, string>;

  // Cache-Controlヘッダーから有効期限を取得
  const cacheControl = response.headers.get('cache-control');
  const maxAge = cacheControl?.match(/max-age=(\d+)/)?.[1];
  const expiryTime = maxAge ? Date.now() + parseInt(maxAge) * 1000 : Date.now() + 3600000; // デフォルト1時間

  // PEM形式の証明書をJWK形式に変換（簡易版）
  const keys: JWKKey[] = Object.entries(certs).map(([kid, cert]) => ({
    kid,
    n: '', // 実装簡略化のため省略
    e: '',
    kty: 'RSA',
    alg: 'RS256',
    use: 'sig',
  }));

  publicKeysCache = {
    keys,
    expiry: expiryTime,
  };

  return keys;
}

/**
 * JWT（Firebase ID Token）をデコード（検証なし）
 *
 * 注意: 本番環境では必ず署名検証を実装すること
 * Cloudflare Workersでの署名検証は Web Crypto API を使用
 */
function decodeToken(token: string): DecodedToken | null {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) {
      return null;
    }

    const payload = parts[1];
    const decoded = JSON.parse(atob(payload.replace(/-/g, '+').replace(/_/g, '/')));

    return decoded as DecodedToken;
  } catch (error) {
    return null;
  }
}

/**
 * Firebase ID Tokenの基本検証
 */
async function verifyFirebaseToken(
  token: string,
  projectId: string
): Promise<DecodedToken | null> {
  const decoded = decodeToken(token);

  if (!decoded) {
    return null;
  }

  // 基本的な検証
  const now = Math.floor(Date.now() / 1000);

  if (decoded.exp && decoded.exp < now) {
    console.error('トークンの有効期限切れ');
    return null;
  }

  if (decoded.iat && decoded.iat > now) {
    console.error('トークンの発行時刻が未来');
    return null;
  }

  if (decoded.aud !== projectId) {
    console.error('プロジェクトIDが一致しません');
    return null;
  }

  if (!decoded.iss || !decoded.iss.includes('securetoken.google.com')) {
    console.error('発行者が不正です');
    return null;
  }

  if (!decoded.sub || typeof decoded.sub !== 'string') {
    console.error('ユーザーIDが不正です');
    return null;
  }

  // TODO: 本番環境では署名検証を実装
  // await verifySignature(token, publicKeys);

  return decoded;
}

/**
 * 認証ミドルウェア
 *
 * Authorization: Bearer <firebase_id_token>
 */
export async function authMiddleware(c: Context, next: Next) {
  try {
    const authHeader = c.req.header('Authorization');

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return authError(c, '認証トークンが提供されていません');
    }

    const token = authHeader.substring(7);
    const projectId = c.env.FIREBASE_PROJECT_ID;

    if (!projectId) {
      console.error('FIREBASE_PROJECT_ID が設定されていません');
      return serverError(c, 'サーバー設定エラー');
    }

    const decodedToken = await verifyFirebaseToken(token, projectId);

    if (!decodedToken) {
      return authError(c, '認証トークンが無効です');
    }

    // コンテキストにユーザー情報を保存
    c.set('firebaseUid', decodedToken.uid);
    c.set('userEmail', decodedToken.email);
    c.set('decodedToken', decodedToken);

    await next();
  } catch (error) {
    console.error('認証エラー:', error);
    return serverError(c, '認証処理中にエラーが発生しました');
  }
}

/**
 * オプショナル認証ミドルウェア
 * トークンがあれば検証するが、なくてもエラーにしない
 */
export async function optionalAuthMiddleware(c: Context, next: Next) {
  try {
    const authHeader = c.req.header('Authorization');

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      const projectId = c.env.FIREBASE_PROJECT_ID;

      if (projectId) {
        const decodedToken = await verifyFirebaseToken(token, projectId);
        if (decodedToken) {
          c.set('firebaseUid', decodedToken.uid);
          c.set('userEmail', decodedToken.email);
          c.set('decodedToken', decodedToken);
        }
      }
    }

    await next();
  } catch (error) {
    console.error('オプショナル認証エラー:', error);
    await next();
  }
}
