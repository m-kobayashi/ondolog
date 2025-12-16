import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/location.dart';
import '../models/checkpoint.dart';
import '../models/record.dart';

class LocalStorageService {
  static const String userBoxName = 'users';
  static const String locationBoxName = 'locations';
  static const String checkpointBoxName = 'checkpoints';
  static const String recordBoxName = 'records';

  // Hive初期化
  static Future<void> init() async {
    await Hive.initFlutter();

    // アダプター登録
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(LocationAdapter());
    Hive.registerAdapter(CheckpointAdapter());
    Hive.registerAdapter(TemperatureRecordAdapter());

    // ボックス開く
    await Future.wait([
      Hive.openBox<User>(userBoxName),
      Hive.openBox<Location>(locationBoxName),
      Hive.openBox<Checkpoint>(checkpointBoxName),
      Hive.openBox<TemperatureRecord>(recordBoxName),
    ]);
  }

  // ユーザー保存
  Future<void> saveUser(User user) async {
    final box = Hive.box<User>(userBoxName);
    await box.put('current_user', user);
  }

  // ユーザー取得
  User? getUser() {
    final box = Hive.box<User>(userBoxName);
    return box.get('current_user');
  }

  // ユーザー削除
  Future<void> deleteUser() async {
    final box = Hive.box<User>(userBoxName);
    await box.delete('current_user');
  }

  // 店舗保存
  Future<void> saveLocations(List<Location> locations) async {
    final box = Hive.box<Location>(locationBoxName);
    await box.clear();
    for (final location in locations) {
      await box.put(location.id, location);
    }
  }

  // 店舗取得
  List<Location> getLocations() {
    final box = Hive.box<Location>(locationBoxName);
    return box.values.toList();
  }

  // チェックポイント保存
  Future<void> saveCheckpoints(List<Checkpoint> checkpoints) async {
    final box = Hive.box<Checkpoint>(checkpointBoxName);
    await box.clear();
    for (final checkpoint in checkpoints) {
      await box.put(checkpoint.id, checkpoint);
    }
  }

  // チェックポイント取得
  List<Checkpoint> getCheckpoints() {
    final box = Hive.box<Checkpoint>(checkpointBoxName);
    return box.values.toList();
  }

  // 特定店舗のチェックポイント取得
  List<Checkpoint> getCheckpointsByLocation(String locationId) {
    final box = Hive.box<Checkpoint>(checkpointBoxName);
    return box.values.where((c) => c.locationId == locationId).toList();
  }

  // 記録保存
  Future<void> saveRecord(TemperatureRecord record) async {
    final box = Hive.box<TemperatureRecord>(recordBoxName);
    await box.put(record.id, record);
  }

  // 記録一括保存
  Future<void> saveRecords(List<TemperatureRecord> records) async {
    final box = Hive.box<TemperatureRecord>(recordBoxName);
    for (final record in records) {
      await box.put(record.id, record);
    }
  }

  // 記録取得
  List<TemperatureRecord> getRecords() {
    final box = Hive.box<TemperatureRecord>(recordBoxName);
    return box.values.toList();
  }

  // 日付範囲で記録取得
  List<TemperatureRecord> getRecordsByDateRange(DateTime start, DateTime end) {
    final box = Hive.box<TemperatureRecord>(recordBoxName);
    return box.values
        .where((r) => r.recordedAt.isAfter(start) && r.recordedAt.isBefore(end))
        .toList();
  }

  // 未同期の記録取得
  List<TemperatureRecord> getUnsyncedRecords() {
    final box = Hive.box<TemperatureRecord>(recordBoxName);
    return box.values.where((r) => r.synced != true).toList();
  }

  // 全データクリア
  Future<void> clearAll() async {
    await Future.wait([
      Hive.box<User>(userBoxName).clear(),
      Hive.box<Location>(locationBoxName).clear(),
      Hive.box<Checkpoint>(checkpointBoxName).clear(),
      Hive.box<TemperatureRecord>(recordBoxName).clear(),
    ]);
  }
}
