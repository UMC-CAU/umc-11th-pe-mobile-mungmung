import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';

class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._api, this._auth);

  final MemberApiService _api;
  final AuthViewModel _auth;
  bool saving = false;
  String? nicknameError;
  String? message;
  bool _disposed = false;

  void clearNicknameError() {
    if (nicknameError == null) return;
    nicknameError = null;
    notifyListeners();
  }

  Future<bool> save(String nickname) async {
    if (saving || _auth.status != AuthStatus.signedIn) return false;
    final version = _auth.sessionVersion;
    message = null;
    nicknameError = null;
    saving = true;
    notifyListeners();
    try {
      final updated = await _api.updateNickname(nickname.trim());
      if (_disposed || !_auth.isCurrent(version)) return false;
      _auth.updateMember(updated);
      return true;
    } on DioException catch (error) {
      if (_disposed || !_auth.isCurrent(version)) return false;
      switch (apiErrorCode(error)) {
        case 'MEMBER409_1':
          nicknameError = '이미 사용 중인 닉네임이에요.';
        case 'COMMON400':
          nicknameError = apiErrorMessage(error) ?? '닉네임을 확인해 주세요.';
        default:
          message = apiErrorMessage(error) ?? '프로필을 저장하지 못했어요. 다시 시도해 주세요.';
      }
    } catch (_) {
      message = '프로필을 저장하지 못했어요. 다시 시도해 주세요.';
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
    return false;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
