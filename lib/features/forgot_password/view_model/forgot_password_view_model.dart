import 'package:flutter/widgets.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/constants/input_rules.dart';
import '../../../core/errors/validation_error.dart';
import '../../auth/data/auth_repository.dart';

/// Drives `09 Forgot password`: one email field and a request for a code.
///
/// The server answers the same whether or not the address has an account —
/// telling an anonymous caller which emails exist would be user enumeration —
/// so success here means only "a code was sent if there is an account", and
/// the user always moves on to `10`.
class ForgotPasswordViewModel extends BaseViewModel {
  ForgotPasswordViewModel({required this._auth, String? initialEmail}) {
    emailController.text = initialEmail ?? '';
    emailController.addListener(_onEmailChanged);
    _onEmailChanged();
  }

  final AuthRepository _auth;

  final TextEditingController emailController = TextEditingController();

  bool _canSubmit = false;
  EmailError? _emailError;

  bool get canSubmit => _canSubmit;
  EmailError? get emailError => _emailError;

  /// The address the code went to, or `null` if the request did not go out.
  Future<String?> sendCode() async {
    final String email = emailController.text.trim();
    _emailError = email.isEmpty
        ? const EmailRequired()
        : InputRules.emailPattern.hasMatch(email)
            ? null
            : const EmailInvalid();
    notifyListeners();
    if (_emailError != null) return null;

    final bool? sent = await runGuarded(() async {
      await _auth.forgotPassword(email);
      return true;
    });
    return sent == true ? email : null;
  }

  void _onEmailChanged() {
    final bool canSubmit =
        InputRules.emailPattern.hasMatch(emailController.text.trim());
    final bool hadError = _emailError != null;
    if (hadError) _emailError = null;
    if (canSubmit != _canSubmit || hadError) {
      _canSubmit = canSubmit;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
