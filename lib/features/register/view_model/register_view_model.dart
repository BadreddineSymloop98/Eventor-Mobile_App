import 'package:flutter/widgets.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/input_rules.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/validation_error.dart';
import '../../../core/models/account.dart';
import '../../../core/reference/reference_repository.dart';
import '../../../core/routing/app_routes.dart';
import '../../auth/data/auth_repository.dart';

/// Drives `08 Register` (client), `08a Register · Provider` and the `08b`
/// "email already used" state.
///
/// Documents are *not* collected here: the API only accepts them once the
/// email is confirmed and a session exists, so a provider uploads them on
/// `08e`, after `10b`.
///
/// Validation runs twice over. As the user types it answers "is the form
/// complete enough to try?", which drives the button. On submit it runs again
/// to produce the errors — values set programmatically bypass both the
/// formatters and the listeners.
class RegisterViewModel extends BaseViewModel {
  RegisterViewModel({
    required this._auth,
    required this._reference,
    required this._config,
    required this.role,
    required this._languageCode,
  }) {
    for (final TextEditingController controller in <TextEditingController>[
      nameController,
      emailController,
      phoneController,
      passwordController,
      businessNameController,
    ]) {
      controller.addListener(_onFieldChanged);
    }
    loadReference();
  }

  final AuthRepository _auth;
  final ReferenceRepository _reference;
  final AppConfig _config;
  final String Function() _languageCode;

  final UserRole role;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController businessNameController = TextEditingController();

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode businessNameFocusNode = FocusNode();

  NameError? _nameError;
  EmailError? _emailError;
  PhoneError? _phoneError;
  PasswordError? _passwordError;
  NameError? _businessNameError;
  SelectionError? _categoryError;
  SelectionError? _wilayasError;

  /// `08b` — the server said the address already has an account.
  bool _emailTaken = false;

  List<Wilaya> _wilayas = const <Wilaya>[];
  List<ServiceCategory> _categories = const <ServiceCategory>[];
  bool _isLoadingReference = false;
  bool _referenceFailed = false;

  Wilaya? _wilaya;
  ServiceCategory? _category;
  Set<Wilaya> _wilayasServed = <Wilaya>{};

  bool get isProvider => role == UserRole.provider;

  NameError? get nameError => _nameError;
  EmailError? get emailError => _emailError;
  PhoneError? get phoneError => _phoneError;
  PasswordError? get passwordError => _passwordError;
  NameError? get businessNameError => _businessNameError;
  SelectionError? get categoryError => _categoryError;
  SelectionError? get wilayasError => _wilayasError;
  bool get emailTaken => _emailTaken;

  List<Wilaya> get wilayas => _wilayas;
  List<ServiceCategory> get categories => _categories;
  bool get isLoadingReference => _isLoadingReference;
  bool get referenceFailed => _referenceFailed;

  Wilaya? get wilaya => _wilaya;
  ServiceCategory? get category => _category;
  Set<Wilaya> get wilayasServed => _wilayasServed;

  int get minPasswordLength => _config.passwordMinLength;

  /// Whether the form is complete enough to try. The detailed rules are
  /// checked — and explained — on submit.
  bool get canSubmit {
    final bool personal = nameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        phoneController.text.trim().isNotEmpty &&
        passwordController.text.isNotEmpty;
    if (!isProvider) return personal;
    return personal &&
        businessNameController.text.trim().isNotEmpty &&
        _category != null &&
        _wilayasServed.isNotEmpty;
  }

  /// Loads the wilaya and category lists the pickers offer. Safe to call
  /// again after a failure — the pickers do, on tap.
  Future<void> loadReference() async {
    if (_isLoadingReference) return;
    _isLoadingReference = true;
    _referenceFailed = false;
    notifyListeners();
    try {
      final List<Wilaya> wilayas = await _reference.wilayas();
      final List<ServiceCategory> categories =
          isProvider ? await _reference.categories() : const <ServiceCategory>[];
      _wilayas = wilayas;
      _categories = categories;
    } catch (_) {
      _referenceFailed = true;
    }
    _isLoadingReference = false;
    notifyListeners();
  }

  void selectWilaya(Wilaya? wilaya) {
    _wilaya = wilaya;
    notifyListeners();
  }

  void selectCategory(ServiceCategory category) {
    _category = category;
    _categoryError = null;
    notifyListeners();
  }

  void selectWilayasServed(Set<Wilaya> wilayas) {
    _wilayasServed = wilayas;
    if (wilayas.isNotEmpty) _wilayasError = null;
    notifyListeners();
  }

  void moveFocusToEmail() => emailFocusNode.requestFocus();
  void moveFocusToPhone() => phoneFocusNode.requestFocus();
  void moveFocusToPassword() => passwordFocusNode.requestFocus();
  void moveFocusToBusinessName() => businessNameFocusNode.requestFocus();

  /// Validates and creates the account. Returns what `10b` needs, or `null`
  /// when validation or the server stopped it.
  Future<VerifyEmailArgs?> submit() async {
    if (isBusy || !_validate()) return null;

    _emailTaken = false;
    final String email = emailController.text.trim();

    final CodeSent? sent = await runGuarded(
      () => _auth.register(
        RegistrationRequest(
          role: role,
          fullName: nameController.text.trim(),
          email: email,
          phone: InputRules.normalisePhone(phoneController.text)!,
          password: passwordController.text,
          language: _languageCode(),
          // A provider is described by the wilayas they serve; the single
          // `wilayaCode` is the client's own. Sending one of the served set
          // as well would make an arbitrary pick their "home" wilaya.
          wilayaCode: isProvider ? null : _wilaya?.code,
          businessName: isProvider ? businessNameController.text.trim() : null,
          categoryId: isProvider ? _category?.id : null,
          wilayaCodes: isProvider
              ? _wilayasServed.map((Wilaya w) => w.code).toList()
              : const <int>[],
        ),
      ),
    );

    if (sent != null) {
      return VerifyEmailArgs(
        email: sent.email.isEmpty ? email : sent.email,
        resendAfterSeconds: sent.resendAfterSeconds,
      );
    }
    _handleFailure();
    return null;
  }

  void _handleFailure() {
    final Failure? error = failure;
    if (error is! ApiFailure) return;

    switch (error.code) {
      case ApiErrorCode.emailTaken:
        _emailTaken = true;
        _emailError = const EmailTaken();
      case ApiErrorCode.phoneTaken:
        _phoneError = const PhoneTaken();
      case ApiErrorCode.passwordWeak:
        _passwordError = const PasswordWeak();
      case ApiErrorCode.categoryNotFound:
        // Hidden or removed since the list was loaded: pick again.
        _category = null;
        _categoryError = const SelectionRequired();
        loadReference();
      case ApiErrorCode.wilayaNotFound:
        _wilaya = null;
        _wilayasServed = <Wilaya>{};
        loadReference();
        if (!isProvider) {
          // The optional wilaya has no error line of its own; leave the
          // failure in place so the view reports the server's reason instead
          // of the choice silently vanishing.
          notifyListeners();
          return;
        }
        _wilayasError = const SelectionRequired();
      default:
        return; // The view reports it.
    }
    clearFailure();
  }

  bool _validate() {
    final String name = nameController.text.trim();
    _nameError = name.isEmpty
        ? const NameRequired()
        : name.length < InputRules.minNameLength
            ? const NameTooShort(InputRules.minNameLength)
            : null;

    final String email = emailController.text.trim();
    _emailError = email.isEmpty
        ? const EmailRequired()
        : InputRules.emailPattern.hasMatch(email)
            ? null
            : const EmailInvalid();

    _phoneError = phoneController.text.trim().isEmpty
        ? const PhoneRequired()
        : InputRules.isPhoneComplete(phoneController.text)
            ? null
            : const PhoneInvalid();

    _passwordError = InputRules.validateNewPassword(
      passwordController.text,
      minLength: _config.passwordMinLength,
      needsLetterAndDigit: _config.passwordNeedsLetterAndDigit,
    );

    if (isProvider) {
      final String business = businessNameController.text.trim();
      _businessNameError = business.isEmpty
          ? const NameRequired()
          : business.length < InputRules.minBusinessNameLength
              ? const NameTooShort(InputRules.minBusinessNameLength)
              : null;
      _categoryError = _category == null ? const SelectionRequired() : null;
      _wilayasError =
          _wilayasServed.isEmpty ? const SelectionRequired() : null;
    }

    notifyListeners();
    return _nameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passwordError == null &&
        _businessNameError == null &&
        _categoryError == null &&
        _wilayasError == null;
  }

  // The last value each error was given, so an error clears only once the
  // field it belongs to has actually changed.
  final Map<TextEditingController, String> _lastValues =
      <TextEditingController, String>{};

  void _onFieldChanged() {
    bool changed(TextEditingController controller) {
      final String previous = _lastValues[controller] ?? '';
      _lastValues[controller] = controller.text;
      return previous != controller.text;
    }

    if (changed(nameController)) _nameError = null;
    if (changed(emailController)) {
      _emailError = null;
      _emailTaken = false;
    }
    if (changed(phoneController)) _phoneError = null;
    if (changed(passwordController)) _passwordError = null;
    if (changed(businessNameController)) _businessNameError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      nameController,
      emailController,
      phoneController,
      passwordController,
      businessNameController,
    ]) {
      controller.dispose();
    }
    for (final FocusNode node in <FocusNode>[
      nameFocusNode,
      emailFocusNode,
      phoneFocusNode,
      passwordFocusNode,
      businessNameFocusNode,
    ]) {
      node.dispose();
    }
    super.dispose();
  }
}
