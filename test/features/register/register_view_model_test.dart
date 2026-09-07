import 'package:eventor/core/constants/input_rules.dart';
import 'package:eventor/core/errors/validation_error.dart';
import 'package:eventor/core/services/document_picker.dart';
import 'package:eventor/features/register/model/account_document.dart';
import 'package:eventor/features/register/view_model/register_view_model.dart';
import 'package:eventor/features/role_selection/model/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

/// A file that passes every rule, so a test can attach without thinking.
const DocumentFile _validPdf = DocumentFile(
  name: 'id-card.pdf',
  sizeInBytes: 1024,
  extension: 'pdf',
);

/// Stands in for the platform browser, handing back whatever the test chose.
DocumentPicker _pickerReturning(DocumentFile? file) => () async => file;

void main() {
  late RegisterViewModel viewModel;

  setUp(() => viewModel = RegisterViewModel());
  tearDown(() => viewModel.dispose());

  /// Fills every field with a value that passes, so a test can spoil one of
  /// them and watch only that one's answer change.
  void fillValidForm() {
    viewModel.nameController.text = 'Zaki';
    viewModel.emailController.text = 'zaki@example.com';
    viewModel.phoneController.text = '0501234567';
    viewModel.passwordController.text = 'secret123';
  }

  group('RegisterViewModel per-field state', () {
    test('starts with nothing satisfied', () {
      expect(viewModel.isNameSatisfied, isFalse);
      expect(viewModel.isEmailSatisfied, isFalse);
      expect(viewModel.isPhoneSatisfied, isFalse);
      expect(viewModel.isPasswordSatisfied, isFalse);
      expect(viewModel.canSubmit, isFalse);
    });

    test('answers for each field independently as it is typed into', () {
      viewModel.nameController.text = 'Zaki';

      expect(viewModel.isNameSatisfied, isTrue);
      expect(viewModel.isEmailSatisfied, isFalse);
      expect(viewModel.canSubmit, isFalse);
    });

    test('holds off until a value actually meets its rule', () {
      // One letter is below the minimum, so the name is not satisfied yet.
      viewModel.nameController.text = 'Z';
      expect(viewModel.isNameSatisfied, isFalse);

      viewModel.nameController.text = 'Za';
      expect(viewModel.isNameSatisfied, isTrue);
    });

    test('wants a phone number of exactly the local length', () {
      viewModel.phoneController.text = '050123456';
      expect(viewModel.isPhoneSatisfied, isFalse);

      viewModel.phoneController.text = '0501234567';
      expect(viewModel.isPhoneSatisfied, isTrue);
    });

    test('turns away a phone number that does not open with a zero', () {
      // Ten digits, but not a local number — an international form pasted in
      // without its "+" would look like this.
      viewModel.phoneController.text = '9661234567';
      expect(viewModel.isPhoneSatisfied, isFalse);
    });

    test('reads through spacing a pasted number brought with it', () {
      viewModel.phoneController.text = '050 123 4567';
      expect(viewModel.isPhoneSatisfied, isTrue);
    });

    test('treats a half-typed address as unsatisfied', () {
      viewModel.emailController.text = 'zaki@ex';
      expect(viewModel.isEmailSatisfied, isFalse);

      viewModel.emailController.text = 'zaki@example.com';
      expect(viewModel.isEmailSatisfied, isTrue);
    });

    test('allows submission only once every field is satisfied', () {
      fillValidForm();

      expect(viewModel.isNameSatisfied, isTrue);
      expect(viewModel.isEmailSatisfied, isTrue);
      expect(viewModel.isPhoneSatisfied, isTrue);
      expect(viewModel.isPasswordSatisfied, isTrue);
      expect(viewModel.canSubmit, isTrue);
    });

    test('withdraws submission when a field is emptied again', () {
      fillValidForm();
      viewModel.phoneController.text = '';

      expect(viewModel.isPhoneSatisfied, isFalse);
      expect(viewModel.canSubmit, isFalse);
    });

    test('reports a bad phone number with the rule it broke', () async {
      fillValidForm();
      viewModel.phoneController.text = '1234567890';

      expect(await viewModel.submit(), isFalse);
      expect(
        viewModel.phoneError,
        isA<PhoneInvalid>()
            .having(
              (PhoneInvalid error) => error.requiredDigits,
              'requiredDigits',
              InputRules.phoneLength,
            )
            .having(
              (PhoneInvalid error) => error.leadingDigit,
              'leadingDigit',
              InputRules.phoneLeadingDigit,
            ),
      );
    });

    test('notifies when a single field flips, not only the whole form', () {
      int notifications = 0;
      viewModel.addListener(() => notifications++);

      // The form is nowhere near submittable, so the only thing that changed
      // is this one field — and the screen still has to hear about it to drop
      // the field's instruction.
      viewModel.nameController.text = 'Zaki';

      expect(notifications, greaterThan(0));
    });
  });

  group('RegisterViewModel role shape', () {
    test('asks a planner for no documents and no institution', () {
      final RegisterViewModel planner = RegisterViewModel(
        role: UserRole.planner,
      );
      addTearDown(planner.dispose);

      expect(planner.documents, isEmpty);
      expect(planner.isReviewed, isFalse);
      expect(planner.needsInstitution, isFalse);
      // Nothing to attach, so the documents half of the gate is already met.
      expect(planner.areDocumentsSatisfied, isTrue);
    });

    test('asks a provider for its trading papers', () {
      final RegisterViewModel provider = RegisterViewModel(
        role: UserRole.provider,
        picker: _pickerReturning(_validPdf),
      );
      addTearDown(provider.dispose);

      expect(provider.documents, <AccountDocument>[
        AccountDocument.identityCard,
        AccountDocument.commercialRegister,
        AccountDocument.taxRegistration,
      ]);
      expect(provider.isReviewed, isTrue);
      expect(provider.needsInstitution, isFalse);
    });

    test('asks an institution for its accreditation and who it acts for', () {
      final RegisterViewModel institution = RegisterViewModel(
        role: UserRole.institution,
        picker: _pickerReturning(_validPdf),
      );
      addTearDown(institution.dispose);

      expect(institution.documents, <AccountDocument>[
        AccountDocument.identityCard,
        AccountDocument.accreditation,
        AccountDocument.authorisationLetter,
        AccountDocument.associationStatutes,
      ]);
      expect(institution.needsInstitution, isTrue);
    });

    test('falls back to the plain form when no role was carried over', () {
      final RegisterViewModel unknown = RegisterViewModel();
      addTearDown(unknown.dispose);

      expect(unknown.documents, isEmpty);
      expect(unknown.needsInstitution, isFalse);
    });
  });

  group('RegisterViewModel documents', () {
    late RegisterViewModel provider;

    setUp(
      () => provider = RegisterViewModel(
        role: UserRole.provider,
        picker: _pickerReturning(_validPdf),
      ),
    );
    tearDown(() => provider.dispose());

    void fillTypedFields(RegisterViewModel target) {
      target.nameController.text = 'Zaki';
      target.emailController.text = 'zaki@example.com';
      target.phoneController.text = '0501234567';
      target.passwordController.text = 'secret123';
    }

    test('holds the button until every required document is attached',
        () async {
      fillTypedFields(provider);
      expect(provider.canSubmit, isFalse);

      for (final AccountDocument document in provider.documents) {
        await provider.pickDocument(document);
      }

      expect(provider.areDocumentsSatisfied, isTrue);
      expect(provider.canSubmit, isTrue);
    });

    test('does not let an optional document hold the form up', () async {
      final RegisterViewModel institution = RegisterViewModel(
        role: UserRole.institution,
        picker: _pickerReturning(_validPdf),
      );
      addTearDown(institution.dispose);

      fillTypedFields(institution);
      institution.institutionController.text = 'Université d\'Alger 1';

      for (final AccountDocument document in institution.documents
          .where((AccountDocument d) => !d.isOptional)) {
        await institution.pickDocument(document);
      }

      // The statutes are still missing, and that is allowed.
      expect(
        institution.fileNameFor(AccountDocument.associationStatutes),
        isNull,
      );
      expect(institution.canSubmit, isTrue);
    });

    test('reports every missing document on submit', () async {
      fillTypedFields(provider);
      await provider.pickDocument(AccountDocument.identityCard);

      expect(await provider.submit(), isFalse);
      expect(provider.errorFor(AccountDocument.identityCard), isNull);
      expect(
        provider.errorFor(AccountDocument.commercialRegister),
        isA<DocumentMissing>(),
      );
      expect(
        provider.errorFor(AccountDocument.taxRegistration),
        isA<DocumentMissing>(),
      );
    });

    test('clears a document error as soon as something is attached', () async {
      fillTypedFields(provider);
      await provider.submit();
      expect(
        provider.errorFor(AccountDocument.commercialRegister),
        isA<DocumentMissing>(),
      );

      await provider.pickDocument(AccountDocument.commercialRegister);

      expect(provider.errorFor(AccountDocument.commercialRegister), isNull);
    });

    test('detaching a document closes the gate again', () async {
      fillTypedFields(provider);
      for (final AccountDocument document in provider.documents) {
        await provider.pickDocument(document);
      }
      expect(provider.canSubmit, isTrue);

      provider.removeDocument(AccountDocument.taxRegistration);

      expect(provider.canSubmit, isFalse);
    });
  });

  group('RegisterViewModel institution field', () {
    late RegisterViewModel institution;

    setUp(
      () => institution = RegisterViewModel(
        role: UserRole.institution,
        picker: _pickerReturning(_validPdf),
      ),
    );
    tearDown(() => institution.dispose());

    test('is required for the role that acts on behalf of one', () async {
      institution.nameController.text = 'Zaki';
      institution.emailController.text = 'zaki@example.com';
      institution.phoneController.text = '0501234567';
      institution.passwordController.text = 'secret123';
      for (final AccountDocument document in institution.documents) {
        await institution.pickDocument(document);
      }

      expect(institution.canSubmit, isFalse);

      institution.institutionController.text = 'Université d\'Alger 1';

      expect(institution.isInstitutionSatisfied, isTrue);
      expect(institution.canSubmit, isTrue);
    });

    test('reports the reason it was rejected', () async {
      expect(await institution.submit(), isFalse);
      expect(institution.institutionError, isA<InstitutionRequired>());
    });

    test('is not checked for a role that is never asked for one', () async {
      final RegisterViewModel provider = RegisterViewModel(
        role: UserRole.provider,
        picker: _pickerReturning(_validPdf),
      );
      addTearDown(provider.dispose);

      await provider.submit();

      // The controller is empty, but the provider form never showed the field.
      expect(provider.institutionError, isNull);
    });
  });

  group('RegisterViewModel document validation', () {
    RegisterViewModel providerPicking(DocumentFile? file) => RegisterViewModel(
      role: UserRole.provider,
      picker: _pickerReturning(file),
    );

    test('keeps a file that meets both rules', () async {
      final RegisterViewModel viewModel = providerPicking(_validPdf);
      addTearDown(viewModel.dispose);

      await viewModel.pickDocument(AccountDocument.identityCard);

      expect(
        viewModel.fileNameFor(AccountDocument.identityCard),
        'id-card.pdf',
      );
      expect(viewModel.errorFor(AccountDocument.identityCard), isNull);
    });

    test('turns away a file over the size limit', () async {
      final RegisterViewModel viewModel = providerPicking(
        DocumentFile(
          name: 'huge-scan.pdf',
          sizeInBytes: InputRules.maxDocumentBytes + 1,
          extension: 'pdf',
        ),
      );
      addTearDown(viewModel.dispose);

      await viewModel.pickDocument(AccountDocument.identityCard);

      expect(viewModel.fileNameFor(AccountDocument.identityCard), isNull);
      expect(
        viewModel.errorFor(AccountDocument.identityCard),
        isA<DocumentTooLarge>().having(
          (DocumentTooLarge error) => error.maximumMegabytes,
          'maximumMegabytes',
          InputRules.maxDocumentMegabytes,
        ),
      );
    });

    test('turns away a file that is neither a PDF nor an image', () async {
      final RegisterViewModel viewModel = providerPicking(
        const DocumentFile(
          name: 'notes.docx',
          sizeInBytes: 2048,
          extension: 'docx',
        ),
      );
      addTearDown(viewModel.dispose);

      await viewModel.pickDocument(AccountDocument.identityCard);

      expect(viewModel.fileNameFor(AccountDocument.identityCard), isNull);
      expect(
        viewModel.errorFor(AccountDocument.identityCard),
        isA<DocumentWrongType>(),
      );
    });

    test('accepts a photograph of a card, not only a scan', () async {
      final RegisterViewModel viewModel = providerPicking(
        const DocumentFile(
          name: 'id.JPG',
          sizeInBytes: 2048,
          // The platform may report the extension in any case.
          extension: 'JPG',
        ),
      );
      addTearDown(viewModel.dispose);

      await viewModel.pickDocument(AccountDocument.identityCard);

      expect(viewModel.fileNameFor(AccountDocument.identityCard), 'id.JPG');
    });

    test('treats a cancelled pick as nothing having happened', () async {
      final RegisterViewModel viewModel = providerPicking(null);
      addTearDown(viewModel.dispose);

      await viewModel.pickDocument(AccountDocument.identityCard);

      expect(viewModel.fileNameFor(AccountDocument.identityCard), isNull);
      // Backing out of the browser is not a complaint about the field.
      expect(viewModel.errorFor(AccountDocument.identityCard), isNull);
    });

    test('a rejected pick leaves an already-good file alone', () async {
      DocumentFile? next = _validPdf;
      final RegisterViewModel viewModel = RegisterViewModel(
        role: UserRole.provider,
        picker: () async => next,
      );
      addTearDown(viewModel.dispose);

      await viewModel.pickDocument(AccountDocument.identityCard);
      expect(
        viewModel.fileNameFor(AccountDocument.identityCard),
        'id-card.pdf',
      );

      next = const DocumentFile(
        name: 'notes.docx',
        sizeInBytes: 2048,
        extension: 'docx',
      );
      await viewModel.pickDocument(AccountDocument.identityCard);

      // Losing a good document because the next pick was bad would be worse
      // than the rejection itself.
      expect(
        viewModel.fileNameFor(AccountDocument.identityCard),
        'id-card.pdf',
      );
      expect(
        viewModel.errorFor(AccountDocument.identityCard),
        isA<DocumentWrongType>(),
      );
    });
  });
}
