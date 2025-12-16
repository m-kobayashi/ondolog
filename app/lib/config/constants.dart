/// アプリ全体で使用する定数定義
class AppConstants {
  // API設定
  static const String apiBaseUrl = 'https://ondolog-api.YOUR-WORKER.workers.dev';

  // プラン制限
  static const int freeMaxLocations = 1;
  static const int freeMaxCheckpoints = 3;
  static const int freeMaxRecordsPerDay = 2;

  // 温度範囲
  static const double minTemperature = -30.0;
  static const double maxTemperature = 50.0;
  static const double temperatureStep = 0.1;

  // チェックポイントタイプのデフォルト温度
  static const Map<String, Map<String, double>> defaultTemperatureRanges = {
    'refrigerator': {'min': 0.0, 'max': 10.0},
    'freezer': {'min': -25.0, 'max': -15.0},
    'cooking_area': {'min': 15.0, 'max': 25.0},
    'storage': {'min': 10.0, 'max': 20.0},
  };

  // チェックポイントタイプ表示名
  static const Map<String, String> checkpointTypeNames = {
    'refrigerator': '冷蔵庫',
    'freezer': '冷凍庫',
    'cooking_area': '調理場',
    'storage': '保管庫',
    'other': 'その他',
  };

  // アイコン
  static const Map<String, String> checkpointTypeIcons = {
    'refrigerator': '🧊',
    'freezer': '🧊',
    'cooking_area': '🍳',
    'storage': '📦',
    'other': '📍',
  };
}
