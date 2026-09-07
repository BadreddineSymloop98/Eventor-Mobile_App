import 'package:flutter/widgets.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/constants/input_rules.dart';
import '../../../core/errors/validation_error.dart';
import '../../../core/services/document_picker.dart';
import '../../role_selection/model/user_role.dart';
import '../model/account_document.dart';

/// Drives the register form.
///
/// It owns the fields, their focus nodes, the attached documents, the
/// validation results and the sign-up call, so the form can be tested without
/// building a widget.
///
/// **The form is one screen with three shapes.** A planner answers four
/// questions; a provider and an institution answer those plus the papers their
/// role has to prove, and an institution names the body it acts for. Which
/// shape applies is decided entirely by [role] — see [AccountDocument.forRole]
/// — so the view never branches on the role itself, it just renders what this
/// class says is there.
///
/// Validation runs twice over, the same way the login form does. As the user
/// types it answers "is this field valid yet?", which is what enables the
/// button. On submit it runs again to produce the messages — a value set
/// programmatically bypasses both the formatters and the listeners.
class RegisterViewModel extends BaseViewModel {
  RegisterViewModel({this.role, DocumentPicker? picker})
    : _picker = picker ?? pickDocumentFile {
    for (final TextEditingController controller in _controllers) {
      controller.addListener(_onFieldChanged);
    }
  }

  /// Opens the platform's file browser. Injected so a test can choose a file
  /// without one.
  final DocumentPicker _picker;

  /// How long the fake sign-up takes.
  ///
  /// There is no backend yet, so this stands in for the round trip. It is long
  /// enough that the button's busy state is actually visible, which is the
  /// point of simulating it at all.
  static const Duration _fakeRequestDuration = Duration(seconds: 3);

  /// Chosen on the previous screen and carried here, because it is saved with
  /// the account rather than on its own.
  final UserRole? role;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController institutionController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode institutionFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  late final List<TextEditingController> _controllers = <TextEditingController>[
    nameController,
    institutionController,
    emailController,
    phoneController,
    passwordController,
  ];

  /// The papers this role has to attach, in the order the form asks for them.
  /// Empty for a planner, which is what collapses the section away entirely.
  late final List<AccountDocument> documents = AccountDocument.forRole(role);

  /// Whether the form asks which body the account acts for.
  bool get needsInstitution => role == UserRole.institution;

  /// Whether this account will be reviewed before it is usable.
  bool get isReviewed => documents.isNotEmpty;

  final Map<AccountDocument, DocumentFile> _attachments =
      <AccountDocument, DocumentFile>{};
  final Map<AccountDocument, DocumentError> _documentErrors =
      <AccountDocument, DocumentError>{};

  NameError? _nameError;
  InstitutionError? _institutionError;
  EmailError? _emailError;
  PhoneError? _phoneError;
  PasswordError? _passwordError;

  bool _isNameSatisfied = false;
  bool _isInstitutionSatisfied = false;
  bool _isEmailSatisfied = false;
  bool _isPhoneSatisfied = false;
  bool _isPasswordSatisfied = false;

  NameError? get nameError => _nameError;
  InstitutionError? get institutionError => _institutionError;
  EmailError? get emailError => _emailError;
  PhoneError? get phoneError => _phoneError;
  PasswordError? get passwordError => _passwordError;

  /// Whether each field's value already meets its format, answered on every
  /// keystroke rather than only on submit.
  ///
  /// The form shows a field's rule while the field is being typed into, and
  /// these are what tell it the rule has been met and the instruction can go.
  bool get isNameSatisfied => _isNameSatisfied;
  bool get isInstitutionSatisfied => _isInstitutionSatisfied;
  bool get isEmailSatisfied => _isEmailSatisfied;
  bool get isPhoneSatisfied => _isPhoneSatisfied;
  bool get isPasswordSatisfied => _isPasswordSatisfied;

  /// The file attached to [document], or `null` while it is empty.
  DocumentFile? fileFor(AccountDocument document) => _attachments[document];

  /// What the field shows once something is attached.
  String? fileNameFor(AccountDocument document) =>
      _attachments[document]?.name;

  /// Why [document] was rejected on the last submit, or `null`.
  DocumentError? errorFor(AccountDocument document) =>
      _documentErrors[document];

  /// Whether every document the role must supply is attached.
  ///
  /// An optional document never holds the form up — see
  /// [AccountDocument.isOptional].
  bool get areDocumentsSatisfied => documents
      .where((AccountDocument document) => !document.isOptional)
      .every(_attachments.containsKey);

  /// Whether every field currently satisfies its format, and the button may
  /// therefore be tapped.
  bool get canSubmit =>
      _isNameSatisfied &&
      (!needsInstitution || _isInstitutionSatisfied) &&
      _isEmailSatisfied &&
      _isPhoneSatisfied &&
      _isPasswordSatisfied &&
      areDocumentsSatisfied &&
      !isBusy;

  /// Moves the keyboard from one field to the next.
  ///
  /// The institution field sits between the name and the email, so the chain
  /// steps over it for the roles that are not asked for one.
  void moveFocusAfterName() {
    if (needsInstitution) {
      institutionFocusNode.requestFocus();
    } else {
      emailFocusNode.requestFocus();
    }
  }

  void moveFocusToEmail() => emailFocusNode.requestFocus();
  void moveFocusToPhone() => phoneFocusNode.requestFocus();
  void moveFocusToPassword() => passwordFocusNode.requestFocus();

  /// Opens the file browser for [document] and keeps what comes back.
  ///
  /// The picker's own extension filter is a convenience, not a guarantee — a
  /// platform may ignore it and a file can always be renamed — so the choice
  /// is checked here before it is kept. A rejected file leaves whatever was
  /// already attached alone: losing a good document because the next pick was
  /// too big would be worse than the rejection itself.
  Future<void> pickDocument(AccountDocument document) async {
    final DocumentFile? file = await _picker();
    // The user backed out of the browser, which is not a complaint.
    if (file == null) return;

    final DocumentError? rejection = _validateDocumentFile(file);
    if (rejection != null) {
      _documentErrors[document] = rejection;
      notifyListeners();
      return;
    }

    _attachments[document] = file;
    // Attaching answers whatever the field was complaining about, so the
    // error goes with it rather than waiting for the next submit.
    _documentErrors.remove(document);
    notifyListeners();
  }

  DocumentError? _validateDocumentFile(DocumentFile file) {
    if (!InputRules.isAcceptableDocumentType(file.extension)) {
      return const DocumentWrongType();
    }
    if (file.sizeInBytes > InputRules.maxDocumentBytes) {
      return const DocumentTooLarge(InputRules.maxDocumentMegabytes);
    }
    return null;
  }

  /// Detaches whatever is on [document].
  void removeDocument(AccountDocument document) {
    if (_attachments.remove(document) == null) return;
    notifyListeners();
  }

  /// Validates the form and creates the account.
  ///
  /// Returns whether the caller should report success.
  Future<bool> submit() async {
    if (!_validate()) return false;

    final bool? succeeded = await runGuarded(_createAccount);
    return succeeded ?? false;
  }

  /// Placeholder for the real sign-up call.
  ///
  /// There is no backend, so this waits and then accepts. Replace the body
  /// when `AuthService` lands; the shape of this method does not change.
  Future<bool> _createAccount() async {
    await Future<void>.delayed(_fakeRequestDuration);
    return true;
  }

  /// Re-checks every field on each keystroke, but notifies only when one of
  /// the answers changes — otherwise typing would rebuild the screen for
  /// nothing.
  void _onFieldChanged() {
    final bool isNameSatisfied =
        _validateName(nameController.text.trim()) == null;
    final bool isInstitutionSatisfied =
        _validateInstitution(institutionController.text.trim()) == null;
    final bool isEmailSatisfied =
        _validateEmail(emailController.text.trim()) == null;
    final bool isPhoneSatisfied = _validatePhone(phoneController.text) == null;
    final bool isPasswordSatisfied =
        _validatePassword(passwordController.text) == null;

    if (isNameSatisfied == _isNameSatisfied &&
        isInstitutionSatisfied == _isInstitutionSatisfied &&
        isEmailSatisfied == _isEmailSatisfied &&
        isPhoneSatisfied == _isPhoneSatisfied &&
        isPasswordSatisfied == _isPasswordSatisfied) {
      return;
    }

    _isNameSatisfied = isNameSatisfied;
    _isInstitutionSatisfied = isInstitutionSatisfied;
    _isEmailSatisfied = isEmailSatisfied;
    _isPhoneSatisfied = isPhoneSatisfied;
    _isPasswordSatisfied = isPasswordSatisfied;
    notifyListeners();
  }

  /// Fills every error and reports whether the form is valid.
  bool _validate() {
    _nameError = _validateName(nameController.text.trim());
    _institutionError = needsInstitution
        ? _validateInstitution(institutionController.text.trim())
        : null;
    _emailError = _validateEmail(emailController.text.trim());
    _phoneError = _validatePhone(phoneController.text);
    _passwordError = _validatePassword(passwordController.text);

    _documentErrors
      ..clear()
      ..addEntries(
        documents
            .where(
              (AccountDocument document) =>
                  !document.isOptional && !_attachments.containsKey(document),
            )
            .map(
              (AccountDocument document) =>
                  MapEntry<AccountDocument, DocumentError>(
                    document,
                    const DocumentMissing(),
                  ),
            ),
      );

    notifyListeners();

    return _nameError == null &&
        _institutionError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passwordError == null &&
        _documentErrors.isEmpty;
  }

  NameError? _validateName(String name) {
    if (name.isEmpty) return const NameRequired();
    if (name.length < InputRules.minNameLength) {
      return const NameTooShort(InputRules.minNameLength);
    }
    return null;
  }

  InstitutionError? _validateInstitution(String institution) {
    if (institution.isEmpty) return const InstitutionRequired();
    if (institution.length < InputRules.minInstitutionLength) {
      return const InstitutionTooShort(InputRules.minInstitutionLength);
    }
    return null;
  }

  EmailError? _validateEmail(String email) {
    if (email.isEmpty) return const EmailRequired();
    if (!InputRules.emailPattern.hasMatch(email)) return const EmailInvalid();
    return null;
  }

  PhoneError? _validatePhone(String phone) {
    if (phone.trim().isEmpty) return const PhoneRequired();
    if (!InputRules.isPhoneComplete(phone)) {
      return const PhoneInvalid(
        requiredDigits: InputRules.phoneLength,
        leadingDigit: InputRules.phoneLeadingDigit,
      );
    }
    return null;
  }

  PasswordError? _validatePassword(String password) {
    if (password.isEmpty) return const PasswordRequired();
    if (password.length < InputRules.minPasswordLength) {
      return const PasswordTooShort(InputRules.minPasswordLength);
    }
    return null;
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers) {
      controller
        ..removeListener(_onFieldChanged)
        ..dispose();
    }
    nameFocusNode.dispose();
    institutionFocusNode.dispose();
    emailFocusNode.dispose();
    phoneFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }
}
