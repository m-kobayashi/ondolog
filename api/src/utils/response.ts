import { Context } from 'hono';

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: any;
  };
}

/**
 * 成功レスポンスを返す
 */
export function successResponse<T>(c: Context, data: T, status: number = 200) {
  return c.json<ApiResponse<T>>({
    success: true,
    data,
  }, status);
}

/**
 * エラーレスポンスを返す
 */
export function errorResponse(
  c: Context,
  code: string,
  message: string,
  status: number = 400,
  details?: any
) {
  return c.json<ApiResponse>({
    success: false,
    error: {
      code,
      message,
      details,
    },
  }, status);
}

/**
 * バリデーションエラーレスポンス
 */
export function validationError(c: Context, message: string, details?: any) {
  return errorResponse(c, 'VALIDATION_ERROR', message, 400, details);
}

/**
 * 認証エラーレスポンス
 */
export function authError(c: Context, message: string = '認証に失敗しました') {
  return errorResponse(c, 'AUTHENTICATION_ERROR', message, 401);
}

/**
 * 権限エラーレスポンス
 */
export function forbiddenError(c: Context, message: string = 'アクセス権限がありません') {
  return errorResponse(c, 'FORBIDDEN', message, 403);
}

/**
 * リソース未検出エラーレスポンス
 */
export function notFoundError(c: Context, message: string = 'リソースが見つかりません') {
  return errorResponse(c, 'NOT_FOUND', message, 404);
}

/**
 * サーバーエラーレスポンス
 */
export function serverError(c: Context, message: string = 'サーバーエラーが発生しました', details?: any) {
  return errorResponse(c, 'INTERNAL_SERVER_ERROR', message, 500, details);
}
