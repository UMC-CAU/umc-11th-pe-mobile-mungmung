import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';

enum AuthStatus {
  initializing,
  signedOut,
  authenticating,
  signedIn,
  retryRequired,
}

enum MemberLoadStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._storage, this._authApi, this._memberApi);

  final TokenStorage _storage;
  final AuthApiService _authApi;
  final MemberApiService _memberApi;

  AuthStatus status = AuthStatus.initializing;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  MemberInfo? member;
  String? loginNickname;
  String? message;
  String? memberMessage;
  bool sessionExpired = false;
  bool storageCleanupInProgress = false;
  bool _cleanupFailed = false;
  bool _logoutWasExpiration = false;
  bool _disposed = false;
  int _sessionVersion = 0;
  int get sessionVersion => _sessionVersion;

  bool isCurrent(int version) => !_disposed && version == _sessionVersion;

  bool get mayAuthorize =>
      !storageCleanupInProgress &&
      (status == AuthStatus.signedIn || status == AuthStatus.initializing);

  Future<void> restoreSession() async {
    if (_disposed ||
        storageCleanupInProgress ||
        status == AuthStatus.authenticating ||
        status == AuthStatus.signedIn) {
      return;
    }
    if (_cleanupFailed) {
      await _clearCurrentSession(expired: _logoutWasExpiration);
      return;
    }
    final version = ++_sessionVersion;
    status = AuthStatus.initializing;
    message = null;
    _notify();
    try {
      final token = await _storage.readAccessToken();
      if (!isCurrent(version)) return;
      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut;
      } else {
        final current = await _memberApi.fetchMe();
        if (!isCurrent(version)) return;
        member = current;
        memberStatus = MemberLoadStatus.success;
        status = AuthStatus.signedIn;
      }
    } on DioException catch (error) {
      if (!isCurrent(version)) return;
      if (isExpiredSession(error)) {
        await expireSession(version);
        return;
      }
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    } catch (_) {
      if (!isCurrent(version)) return;
      status = AuthStatus.retryRequired;
      message = '저장된 로그인 정보를 확인하지 못했어요. 다시 시도해 주세요.';
    }
    _notify();
  }

  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        status != AuthStatus.signedOut) {
      return;
    }
    final version = ++_sessionVersion;
    status = AuthStatus.authenticating;
    sessionExpired = false;
    message = null;
    _notify();
    LoginResult result;
    try {
      result = await _authApi.login(
        LoginRequest(email: email, password: password),
      );
    } on DioException catch (error) {
      _failLogin(
        version,
        apiErrorCode(error) == 'AUTH401_1'
            ? '이메일 또는 비밀번호가 올바르지 않아요.'
            : '로그인에 실패했어요. 잠시 후 다시 시도해 주세요.',
      );
      return;
    } catch (_) {
      _failLogin(version, '로그인 응답을 확인하지 못했어요. 다시 시도해 주세요.');
      return;
    }
    if (!isCurrent(version)) return;
    try {
      await _storage.saveAccessToken(result.accessToken);
    } catch (_) {
      _failLogin(version, '로그인 정보를 저장하지 못했어요. 다시 시도해 주세요.');
      return;
    }
    if (!isCurrent(version)) return;
    loginNickname = result.nickname;
    status = AuthStatus.signedIn;
    _notify();
  }

  void _failLogin(int version, String error) {
    if (!isCurrent(version)) return;
    status = AuthStatus.signedOut;
    message = error;
    _notify();
  }

  Future<void> loadMember() async {
    if (_disposed ||
        status != AuthStatus.signedIn ||
        memberStatus == MemberLoadStatus.loading ||
        memberStatus == MemberLoadStatus.success) {
      return;
    }
    final version = _sessionVersion;
    memberStatus = MemberLoadStatus.loading;
    memberMessage = null;
    _notify();
    try {
      final current = await _memberApi.fetchMe();
      if (!isCurrent(version)) return;
      updateMember(current);
      return;
    } on DioException catch (error) {
      if (!isCurrent(version)) return;
      if (isExpiredSession(error)) {
        await expireSession(version);
        return;
      }
    } catch (_) {
      if (!isCurrent(version)) return;
    }
    memberStatus = MemberLoadStatus.error;
    memberMessage = '내 정보를 불러오지 못했어요.';
    _notify();
  }

  void updateMember(MemberInfo updated) {
    if (_disposed || status != AuthStatus.signedIn) return;
    member = updated;
    memberStatus = MemberLoadStatus.success;
    memberMessage = null;
    _notify();
  }

  bool consumeSessionExpired() {
    final expired = sessionExpired;
    sessionExpired = false;
    return expired;
  }

  Future<void> logout() async {
    if (status == AuthStatus.signedIn) {
      await _clearCurrentSession(expired: false);
    }
  }

  Future<void> expireSession(int version) async {
    if (isCurrent(version) && mayAuthorize) {
      await _clearCurrentSession(expired: true);
    }
  }

  Future<void> _clearCurrentSession({required bool expired}) async {
    if (_disposed || storageCleanupInProgress) return;
    ++_sessionVersion;
    storageCleanupInProgress = true;
    _logoutWasExpiration = expired;
    member = null;
    loginNickname = null;
    memberStatus = MemberLoadStatus.idle;
    memberMessage = null;
    message = null;
    status = AuthStatus.initializing;
    _notify();
    try {
      await _storage.clear();
      _cleanupFailed = false;
      status = AuthStatus.signedOut;
      sessionExpired = expired;
    } catch (_) {
      _cleanupFailed = true;
      status = AuthStatus.retryRequired;
      message = '저장된 로그인 정보를 지우지 못했어요. 다시 시도해 주세요.';
    } finally {
      storageCleanupInProgress = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
