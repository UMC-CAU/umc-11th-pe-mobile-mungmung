import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/view_models/signup_view_model.dart';

class ControlledChecks extends MemberCheckService {
  ControlledChecks() : super(Dio());
  final nickname = Completer<bool>();
  final email = Completer<bool>();
  @override
  Future<bool> checkNickname(String value) => nickname.future;
  @override
  Future<bool> checkEmail(String value) => email.future;
}

void main() {
  test(
    'communication failure differs from duplicate and allows retry',
    () async {
      final service = ControlledChecks();
      final vm = SignUpViewModel(service);
      addTearDown(vm.dispose);
      vm.onNicknameChanged('tester');
      vm.onEmailChanged('test@example.com');
      final nickname = vm.checkNickname('tester');
      final email = vm.checkEmail('test@example.com');
      service.nickname.complete(false);
      service.email.completeError(
        DioException(requestOptions: RequestOptions(path: '/email')),
      );
      await Future.wait([nickname, email]);
      expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
      expect(vm.emailCheckStatus, CheckStatus.error);
      expect(vm.nicknameErrorText, isNot(vm.emailErrorText));
      expect(vm.canCheckNickname, isFalse);
      expect(vm.canCheckEmail, isTrue);
      vm.onNicknameChanged('another');
      expect(vm.nicknameCheckStatus, CheckStatus.idle);
      vm.onNicknameChanged('tester');
      expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
    },
  );

  test('concurrent checks keep results independent', () async {
    final service = ControlledChecks();
    final model = SignUpViewModel(service);
    addTearDown(model.dispose);
    model.onNicknameChanged('tester');
    model.onEmailChanged('test@example.com');
    final nickname = model.checkNickname('tester');
    final email = model.checkEmail('test@example.com');
    service.nickname.complete(false);
    await nickname;
    expect(model.nicknameCheckStatus, CheckStatus.duplicated);
    expect(model.emailCheckStatus, CheckStatus.checking);
    service.email.complete(true);
    await email;
    expect(model.emailCheckStatus, CheckStatus.available);
    expect(model.nicknameCheckStatus, CheckStatus.duplicated);
    expect(model.emailErrorText, isNull);
  });

  test(
    'editing email discards its response without invalidating nickname',
    () async {
      final service = ControlledChecks();
      final model = SignUpViewModel(service);
      addTearDown(model.dispose);
      model.onNicknameChanged('tester');
      model.onEmailChanged('old@example.com');
      final nickname = model.checkNickname('tester');
      final email = model.checkEmail('old@example.com');
      model.onEmailChanged('new@example.com');
      service.email.complete(false);
      service.nickname.complete(true);
      await Future.wait([nickname, email]);
      expect(model.emailCheckStatus, CheckStatus.idle);
      expect(model.emailErrorText, isNull);
      expect(model.nicknameCheckStatus, CheckStatus.available);
    },
  );
}
