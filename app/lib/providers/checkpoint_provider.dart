import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/checkpoint.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';
import 'location_provider.dart';

// チェックポイントリストのプロバイダー
final checkpointsProvider = StateNotifierProvider<CheckpointsNotifier, AsyncValue<List<Checkpoint>>>((ref) {
  return CheckpointsNotifier(ref);
});

// 特定店舗のチェックポイント取得
final checkpointsByLocationProvider = FutureProvider.family<List<Checkpoint>, String>((ref, locationId) async {
  final checkpoints = await ref.watch(checkpointsProvider.future);
  return checkpoints.where((c) => c.locationId == locationId).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

class CheckpointsNotifier extends StateNotifier<AsyncValue<List<Checkpoint>>> {
  final Ref ref;

  CheckpointsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadCheckpoints();
  }

  // チェックポイント一覧を読み込む
  Future<void> loadCheckpoints() async {
    try {
      state = const AsyncValue.loading();

      // まずローカルストレージから読み込む
      final localStorage = ref.read(localStorageProvider);
      final localCheckpoints = localStorage.getCheckpoints();

      if (localCheckpoints.isNotEmpty) {
        state = AsyncValue.data(localCheckpoints);
      }

      // APIから最新データを取得
      final locations = await ref.read(locationsProvider.future);
      if (locations.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      final apiService = ref.read(apiServiceProvider);
      final List<Checkpoint> allCheckpoints = [];

      for (final location in locations) {
        try {
          final response = await apiService.get('/api/locations/${location.id}/checkpoints');
          if (response.statusCode == 200) {
            final List<dynamic> data = response.data['data']['checkpoints'];
            final checkpoints = data.map((json) => Checkpoint.fromJson(json)).toList();
            allCheckpoints.addAll(checkpoints);
          }
        } catch (e) {
          print('Error loading checkpoints for location ${location.id}: $e');
        }
      }

      // ローカルストレージに保存
      await localStorage.saveCheckpoints(allCheckpoints);
      state = AsyncValue.data(allCheckpoints);
    } catch (e, stack) {
      // エラーが発生してもローカルデータがあればそれを表示
      final localStorage = ref.read(localStorageProvider);
      final localCheckpoints = localStorage.getCheckpoints();

      if (localCheckpoints.isNotEmpty) {
        state = AsyncValue.data(localCheckpoints);
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  // チェックポイント登録
  Future<bool> createCheckpoint({
    required String locationId,
    required String name,
    required String checkpointType,
    double? minTemp,
    double? maxTemp,
    int? sortOrder,
  }) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post('/api/checkpoints', data: {
        'location_id': locationId,
        'name': name,
        'checkpoint_type': checkpointType,
        'min_temp': minTemp,
        'max_temp': maxTemp,
        'sort_order': sortOrder ?? 0,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        await loadCheckpoints();
        return true;
      }
      return false;
    } catch (e) {
      print('Create checkpoint error: $e');
      return false;
    }
  }

  // チェックポイント更新
  Future<bool> updateCheckpoint({
    required String id,
    required String name,
    required String checkpointType,
    double? minTemp,
    double? maxTemp,
    int? sortOrder,
  }) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.put('/api/checkpoints/$id', data: {
        'name': name,
        'checkpoint_type': checkpointType,
        'min_temp': minTemp,
        'max_temp': maxTemp,
        'sort_order': sortOrder,
      });

      if (response.statusCode == 200) {
        await loadCheckpoints();
        return true;
      }
      return false;
    } catch (e) {
      print('Update checkpoint error: $e');
      return false;
    }
  }

  // チェックポイント削除
  Future<bool> deleteCheckpoint(String id) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.delete('/api/checkpoints/$id');

      if (response.statusCode == 200) {
        await loadCheckpoints();
        return true;
      }
      return false;
    } catch (e) {
      print('Delete checkpoint error: $e');
      return false;
    }
  }
}
