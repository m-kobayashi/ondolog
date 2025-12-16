import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';
import 'auth_provider.dart';

// APIサービスプロバイダー
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// 店舗リストのプロバイダー
final locationsProvider = StateNotifierProvider<LocationsNotifier, AsyncValue<List<Location>>>((ref) {
  return LocationsNotifier(ref);
});

class LocationsNotifier extends StateNotifier<AsyncValue<List<Location>>> {
  final Ref ref;

  LocationsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadLocations();
  }

  // 店舗一覧を読み込む
  Future<void> loadLocations() async {
    try {
      state = const AsyncValue.loading();

      // まずローカルストレージから読み込む
      final localStorage = ref.read(localStorageProvider);
      final localLocations = localStorage.getLocations();

      if (localLocations.isNotEmpty) {
        state = AsyncValue.data(localLocations);
      }

      // APIから最新データを取得
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/api/locations');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']['locations'];
        final locations = data.map((json) => Location.fromJson(json)).toList();

        // ローカルストレージに保存
        await localStorage.saveLocations(locations);
        state = AsyncValue.data(locations);
      }
    } catch (e, stack) {
      // エラーが発生してもローカルデータがあればそれを表示
      final localStorage = ref.read(localStorageProvider);
      final localLocations = localStorage.getLocations();

      if (localLocations.isNotEmpty) {
        state = AsyncValue.data(localLocations);
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  // 店舗登録
  Future<bool> createLocation({
    required String name,
    String? address,
  }) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post('/api/locations', data: {
        'name': name,
        'address': address,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        await loadLocations();
        return true;
      }
      return false;
    } catch (e) {
      print('Create location error: $e');
      return false;
    }
  }

  // 店舗更新
  Future<bool> updateLocation({
    required String id,
    required String name,
    String? address,
  }) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.put('/api/locations/$id', data: {
        'name': name,
        'address': address,
      });

      if (response.statusCode == 200) {
        await loadLocations();
        return true;
      }
      return false;
    } catch (e) {
      print('Update location error: $e');
      return false;
    }
  }

  // 店舗削除
  Future<bool> deleteLocation(String id) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.delete('/api/locations/$id');

      if (response.statusCode == 200) {
        await loadLocations();
        return true;
      }
      return false;
    } catch (e) {
      print('Delete location error: $e');
      return false;
    }
  }
}
