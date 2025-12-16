/**
 * ユニークなIDを生成
 */
export function generateId(prefix: string): string {
  const timestamp = Date.now().toString(36);
  const randomPart = Math.random().toString(36).substring(2, 10);
  return `${prefix}_${timestamp}${randomPart}`;
}

/**
 * ユーザーID生成
 */
export function generateUserId(): string {
  return generateId('usr');
}

/**
 * 店舗ID生成
 */
export function generateLocationId(): string {
  return generateId('loc');
}

/**
 * 記録ポイントID生成
 */
export function generateCheckpointId(): string {
  return generateId('cp');
}

/**
 * 温度記録ID生成
 */
export function generateRecordId(): string {
  return generateId('rec');
}
