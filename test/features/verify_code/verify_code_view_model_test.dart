import 'package:eventor/features/verify_code/view_model/verify_code_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The countdown is a real [Timer], so these run inside `testWidgets` — its
  /// fake clock is what `tester.pump(duration)` moves, and a plain `test`
  /// would sit through thirty real seconds instead.
  group('VerifyCodeViewModel resend cooldown', () {
    testWidgets('starts counting the moment the screen is built',
        (WidgetTester tester) async {
      final VerifyCodeViewModel viewModel = VerifyCodeViewModel();
      addTearDown(viewModel.dispose);

      expect(
        viewModel.resendSecondsRemaining,
        VerifyCodeViewModel.resendCooldown.inSeconds,
      );
      expect(viewModel.canResend, isFalse);
    });

    testWidgets('counts down a second at a time',
        (WidgetTester tester) async {
      final VerifyCodeViewModel viewModel = VerifyCodeViewModel();
      addTearDown(viewModel.dispose);

      await tester.pump(const Duration(seconds: 1));
      expect(
        viewModel.resendSecondsRemaining,
        VerifyCodeViewModel.resendCooldown.inSeconds - 1,
      );

      await tester.pump(const Duration(seconds: 9));
      expect(
        viewModel.resendSecondsRemaining,
        VerifyCodeViewModel.resendCooldown.inSeconds - 10,
      );
    });

    testWidgets('opens the offer up at zero and stops there',
        (WidgetTester tester) async {
      final VerifyCodeViewModel viewModel = VerifyCodeViewModel();
      addTearDown(viewModel.dispose);

      await tester.pump(VerifyCodeViewModel.resendCooldown);

      expect(viewModel.resendSecondsRemaining, 0);
      expect(viewModel.canResend, isTrue);

      // The timer cancelled itself rather than counting past zero.
      await tester.pump(const Duration(seconds: 5));
      expect(viewModel.resendSecondsRemaining, 0);
    });

    testWidgets('tells the screen each second, so the number can be seen',
        (WidgetTester tester) async {
      final VerifyCodeViewModel viewModel = VerifyCodeViewModel();
      addTearDown(viewModel.dispose);

      int notifications = 0;
      viewModel.addListener(() => notifications++);

      await tester.pump(const Duration(seconds: 3));

      expect(notifications, 3);
    });

    testWidgets('refuses a resend while the wait is still running',
        (WidgetTester tester) async {
      final VerifyCodeViewModel viewModel = VerifyCodeViewModel();
      addTearDown(viewModel.dispose);

      expect(await viewModel.resend(), isFalse);
      // Nothing was sent, so nothing restarted the wait either.
      expect(
        viewModel.resendSecondsRemaining,
        VerifyCodeViewModel.resendCooldown.inSeconds,
      );
    });

    testWidgets('attributes a resend to the resend line, not to Verify',
        (WidgetTester tester) async {
      final VerifyCodeViewModel viewModel = VerifyCodeViewModel();
      addTearDown(viewModel.dispose);

      await tester.pump(VerifyCodeViewModel.resendCooldown);

      final Future<bool> sending = viewModel.resend();
      await tester.pump();

      // The screen is busy, but the work belongs to the resend — the Verify
      // button must not spin for it.
      expect(viewModel.isBusy, isTrue);
      expect(viewModel.isResending, isTrue);
      expect(viewModel.isVerifying, isFalse);

      await tester.pump(const Duration(seconds: 3));
      await sending;

      expect(viewModel.isResending, isFalse);
    });

    testWidgets('attributes a verification to Verify',
        (WidgetTester tester) async {
      final VerifyCodeViewModel viewModel = VerifyCodeViewModel();
      addTearDown(viewModel.dispose);

      viewModel.codeController.text = '123456';

      final Future<bool> verifying = viewModel.verify();
      await tester.pump();

      expect(viewModel.isVerifying, isTrue);
      expect(viewModel.isResending, isFalse);

      await tester.pump(const Duration(seconds: 3));
      await verifying;
    });

    testWidgets('does not stack a second timer across resend cycles',
        (WidgetTester tester) async {
      final VerifyCodeViewModel viewModel = VerifyCodeViewModel();
      addTearDown(viewModel.dispose);

      // Run the wait out and ask for another code, twice over. A countdown
      // that cleared its own field while a newer timer held it used to leave
      // that newer one ticking unreferenced, and the next wait then fell two
      // seconds a second.
      for (int cycle = 0; cycle < 2; cycle++) {
        await tester.pump(VerifyCodeViewModel.resendCooldown);
        expect(viewModel.resendSecondsRemaining, 0);

        final Future<bool> sending = viewModel.resend();
        await tester.pump(const Duration(seconds: 3));
        expect(await sending, isTrue);
      }

      await tester.pump(const Duration(seconds: 1));

      expect(
        viewModel.resendSecondsRemaining,
        VerifyCodeViewModel.resendCooldown.inSeconds - 1,
      );
    });

    testWidgets('restarts the wait once a new code has gone out',
        (WidgetTester tester) async {
      final VerifyCodeViewModel viewModel = VerifyCodeViewModel();
      addTearDown(viewModel.dispose);

      await tester.pump(VerifyCodeViewModel.resendCooldown);
      expect(viewModel.canResend, isTrue);

      final Future<bool> sending = viewModel.resend();
      // Let the stand-in request finish.
      await tester.pump(const Duration(seconds: 3));

      expect(await sending, isTrue);
      expect(
        viewModel.resendSecondsRemaining,
        VerifyCodeViewModel.resendCooldown.inSeconds,
      );
      expect(viewModel.canResend, isFalse);
    });
  });
}
