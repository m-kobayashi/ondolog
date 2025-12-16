import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/auth_service.dart';
import '../services/local_storage.dart';
import '../models/user.dart';

// AuthServiceのプロバイダー
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// LocalStorageServiceのプロバイダー
final localStorageProvider = Provider<LocalStorageService>((ref) => LocalStorageService());

// Firebase認証状態のプロバイダー
final firebaseAuthStateProvider = StreamProvider<firebase_auth.User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// ユーザー情報のプロバイダー
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  return UserNotifier(ref);
});

class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref ref;

  UserNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadUser();
  }

  // ローカルストレージからユーザー情報を読み込む
  Future<void> _loadUser() async {
    try {
      final localStorage = ref.read(localStorageProvider);
      final user = localStorage.getUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // ユーザー情報を更新
  Future<void> updateUser(User user) async {
    try {
      final localStorage = ref.read(localStorageProvider);
      await localStorage.saveUser(user);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // ユーザー情報をクリア
  Future<void> clearUser() async {
    try {
      final localStorage = ref.read(localStorageProvider);
      await localStorage.deleteUser();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // ログイン
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithEmail(email, password);

      if (user != null) {
        await updateUser(user);
        return true;
      }
      state = const AsyncValue.data(null);
      return false;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  // 新規登録
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    String? businessName,
    String? businessType,
  }) async {
    try {
      state = const AsyncValue.loading();
      final authService = ref.read(authServiceProvider);
      final user = await authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        businessName: businessName,
        businessType: businessType,
      );

      if (user != null) {
        await updateUser(user);
        return true;
      }
      state = const AsyncValue.data(null);
      return false;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  // Googleログイン
  Future<bool> signInWithGoogle() async {
    try {
      state = const AsyncValue.loading();
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();

      if (user != null) {
        await updateUser(user);
        return true;
      }
      state = const AsyncValue.data(null);
      return false;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  // ログアウト
  Future<void> signOut() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      await clearUser();

      // 全ローカルデータをクリア
      final localStorage = ref.read(localStorageProvider);
      await localStorage.clearAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
