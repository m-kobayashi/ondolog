import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';
import 'location_provider.dart';

// 記録リストのプロバイダー
final recordsProvider = StateNotifierProvider<RecordsNotifier, AsyncValue<List<TemperatureRecord>>>((ref) {
  return RecordsNotifier(ref);
});

// 日別記録取得
final dailyRecordsProvider = FutureProvider.family<List<TemperatureRecord>, DateTime>((ref, date) async {
  final dateStr = DateFormat('yyyy-MM-dd').format(date);
  final apiService = ref.read(apiServiceProvider);

  try {
    final response = await apiService.get('/api/records/daily/$dateStr');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['data']['records'];
      return data.map((json) => TemperatureRecord.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    // エラー時はローカルストレージから取得
    final localStorage = ref.read(localStorageProvider);
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return localStorage.getRecordsByDateRange(startOfDay, endOfDay);
  }
});

class RecordsNotifier extends StateNotifier<AsyncValue<List<TemperatureRecord>>> {
  final Ref ref;

  RecordsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadRecords();
  }

  // 記録一覧を読み込む
  Future<void> loadRecords() async {
    try {
      state = const AsyncValue.loading();

      // まずローカルストレージから読み込む
      final localStorage = ref.read(localStorageProvider);
      final localRecords = localStorage.getRecords();

      if (localRecords.isNotEmpty) {
        state = AsyncValue.data(localRecords);
      }

      // APIから最新データを取得（直近100件）
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/api/records');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']['records'];
        final records = data.map((json) => TemperatureRecord.fromJson(json)).toList();

        // ローカルストレージに保存
        await localStorage.saveRecords(records);
        state = AsyncValue.data(records);
      }
    } catch (e, stack) {
      // エラーが発生してもローカルデータがあればそれを表示
      final localStorage = ref.read(localStorageProvider);
      final localRecords = localStorage.getRecords();

      if (localRecords.isNotEmpty) {
        state = AsyncValue.data(localRecords);
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  // 単一記録登録
  Future<Map<String, dynamic>?> createRecord({
    required String checkpointId,
    required double temperature,
    String? recordedBy,
    String? abnormalAction,
    String? notes,
  }) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post('/api/records', data: {
        'checkpoint_id': checkpointId,
        'temperature': temperature,
        'recorded_by': recordedBy,
        'abnormal_action': abnormalAction,
        'notes': notes,
        'recorded_at': DateTime.now().toIso8601String(),
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        await loadRecords();
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Create record error: $e');

      // オフライン時はローカルに保存
      final localStorage = ref.read(localStorageProvider);
      final recordId = 'rec_local_${DateTime.now().millisecondsSinceEpoch}';
      final record = TemperatureRecord(
        id: recordId,
        checkpointId: checkpointId,
        temperature: temperature,
        recordedAt: DateTime.now(),
        recordedBy: recordedBy,
        abnormalAction: abnormalAction,
        notes: notes,
        createdAt: DateTime.now(),
        synced: false,
      );

      await localStorage.saveRecord(record);
      await loadRecords();

      return {'record': record.toJson(), 'is_abnormal': false};
    }
  }

  // 一括記録登録
  Future<Map<String, dynamic>?> createBulkRecords({
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post('/api/records/bulk', data: {
        'records': records,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        await loadRecords();
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Create bulk records error: $e');

      // オフライン時はローカルに保存
      final localStorage = ref.read(localStorageProvider);
      final now = DateTime.now();

      for (final rec in records) {
        final recordId = 'rec_local_${now.millisecondsSinceEpoch}_${rec['checkpoint_id']}';
        final record = TemperatureRecord(
          id: recordId,
          checkpointId: rec['checkpoint_id'],
          temperature: rec['temperature'],
          recordedAt: DateTime.parse(rec['recorded_at'] ?? now.toIso8601String()),
          recordedBy: rec['recorded_by'],
          abnormalAction: rec['abnormal_action'],
          notes: rec['notes'],
          createdAt: now,
          synced: false,
        );

        await localStorage.saveRecord(record);
      }

      await loadRecords();

      return {
        'recorded_count': records.length,
        'abnormal_count': 0,
        'records': records,
      };
    }
  }

  // 未同期データを同期
  Future<void> syncUnsyncedRecords() async {
    try {
      final localStorage = ref.read(localStorageProvider);
      final unsyncedRecords = localStorage.getUnsyncedRecords();

      if (unsyncedRecords.isEmpty) return;

      final apiService = ref.read(apiServiceProvider);

      for (final record in unsyncedRecords) {
        try {
          final response = await apiService.post('/api/records', data: {
            'checkpoint_id': record.checkpointId,
            'temperature': record.temperature,
            'recorded_at': record.recordedAt.toIso8601String(),
            'recorded_by': record.recordedBy,
            'abnormal_action': record.abnormalAction,
            'notes': record.notes,
          });

          if (response.statusCode == 201 || response.statusCode == 200) {
            // 同期成功したらローカルの記録を更新
            final syncedRecord = record.copyWith(synced: true);
            await localStorage.saveRecord(syncedRecord);
          }
        } catch (e) {
          print('Sync record ${record.id} error: $e');
        }
      }

      await loadRecords();
    } catch (e) {
      print('Sync unsynced records error: $e');
    }
  }
}
