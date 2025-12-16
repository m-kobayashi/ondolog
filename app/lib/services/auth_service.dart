import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ApiService _apiService = ApiService();

  // 現在のFirebaseユーザー
  firebase_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // 認証状態の変更ストリーム
  Stream<firebase_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // メール/パスワードでログイン
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await _getUserFromApi();
      }
      return null;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // メール/パスワードで登録
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    String? businessName,
    String? businessType,
  }) async {
    try {
      // Firebase Authでユーザー登録
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      // 表示名を設定
      await credential.user!.updateDisplayName(displayName);

      // バックエンドにユーザー登録
      final response = await _apiService.post('/api/auth/register', data: {
        'email': email,
        'display_name': displayName,
        'business_name': businessName,
        'business_type': businessType,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        return User.fromJson(response.data['data']['user']);
      }

      return null;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  // Googleログイン
  /// 注: MVP段階では一時的に無効化しています
  Future<User?> signInWithGoogle() async {
    throw Exception('Google Sign In は現在利用できません。メール/パスワードでログインしてください。');

    // TODO: Android/iOS向けに Google Sign In を有効化する場合は以下のコメントを外す
    /*
    try {
      // Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // ユーザーがキャンセル

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase認証
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) return null;

      // バックエンドにユーザー登録（既存の場合は取得）
      try {
        return await _getUserFromApi();
      } catch (e) {
        // ユーザーが存在しない場合は新規登録
        final response = await _apiService.post('/api/auth/register', data: {
          'email': userCredential.user!.email,
          'display_name': userCredential.user!.displayName,
        });

        if (response.statusCode == 201 || response.statusCode == 200) {
          return User.fromJson(response.data['data']['user']);
        }
      }

      return null;
    } catch (e) {
      print('Google sign in error: $e');
      rethrow;
    }
    */
  }

  // バックエンドからユーザー情報取得
  Future<User?> _getUserFromApi() async {
    try {
      final response = await _apiService.get('/api/users/me');
      if (response.statusCode == 200) {
        return User.fromJson(response.data['data']['user']);
      }
      return null;
    } catch (e) {
      print('Get user error: $e');
      rethrow;
    }
  }

  // ログアウト
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    // TODO: Google Sign In 有効化時は以下も追加
    // await _googleSignIn.signOut();
  }

  // パスワードリセット
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
