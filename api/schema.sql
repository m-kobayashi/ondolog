-- オンドログ データベーススキーマ
-- Cloudflare D1 (SQLite)

-- ユーザーテーブル
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  display_name TEXT,
  business_name TEXT,
  business_type TEXT, -- 'restaurant', 'factory', 'cafeteria', 'other'
  plan TEXT DEFAULT 'free',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_email ON users(email);

-- 店舗テーブル
CREATE TABLE locations (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  address TEXT,
  is_active INTEGER DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_locations_user_id ON locations(user_id);
CREATE INDEX idx_locations_is_active ON locations(is_active);

-- 記録ポイントテーブル
CREATE TABLE checkpoints (
  id TEXT PRIMARY KEY,
  location_id TEXT NOT NULL,
  name TEXT NOT NULL, -- '冷蔵庫A', '冷凍庫', '調理場' など
  checkpoint_type TEXT NOT NULL, -- 'refrigerator', 'freezer', 'cooking_area', 'storage', 'other'
  min_temp REAL, -- 基準下限温度
  max_temp REAL, -- 基準上限温度
  sort_order INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE
);

CREATE INDEX idx_checkpoints_location_id ON checkpoints(location_id);
CREATE INDEX idx_checkpoints_is_active ON checkpoints(is_active);
CREATE INDEX idx_checkpoints_sort_order ON checkpoints(sort_order);

-- 温度記録テーブル
CREATE TABLE records (
  id TEXT PRIMARY KEY,
  checkpoint_id TEXT NOT NULL,
  temperature REAL NOT NULL,
  recorded_at DATETIME NOT NULL,
  recorded_by TEXT, -- 記録者名（将来用）
  is_abnormal INTEGER DEFAULT 0, -- 基準外フラグ
  abnormal_action TEXT, -- 異常時対応メモ
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (checkpoint_id) REFERENCES checkpoints(id) ON DELETE CASCADE
);

CREATE INDEX idx_records_checkpoint_id ON records(checkpoint_id);
CREATE INDEX idx_records_recorded_at ON records(recorded_at);
CREATE INDEX idx_records_is_abnormal ON records(is_abnormal);
CREATE INDEX idx_records_created_at ON records(created_at);
