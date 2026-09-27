import 'dart:async';
import 'dart:typed_data';

import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/messaging/models/chat_message.dart';
import 'package:eventor/core/messaging/models/report_reason.dart';
import 'package:eventor/core/messaging/picked_image.dart';
import 'package:eventor/features/chat/view_model/chat_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../feature_test_helpers.dart';
import 'chat_test_support.dart';

void main() {
  late ChatHarness h;

  setUp(() => h = ChatHarness());

  Future<ChatViewModel> ready({String conversationId = 'c-lumiere'}) async {
    final ChatViewModel viewModel = h.build(conversationId: conversationId);
    await flushAsync();
    return viewModel;
  }

  PickedImage image(String name, {int bytes = 1024}) => PickedImage(
    name: name,
    bytes: Uint8List(bytes),
    extension: name.split('.').last,
  );

  BubbleItem newest(ChatViewModel viewModel) => bubbles(viewModel).first;

  group('sending text', () {
    test('shows at once, then becomes the server message (D8)', () async {
      final ChatViewModel viewModel = await ready();
      h.messaging.sendGate = Completer<void>();

      final Future<SendOutcome> sending = viewModel.send(' hi ');

      expect(newest(viewModel).entry.state, EntryState.sending);
      expect(newest(viewModel).entry.message.body, 'hi');
      expect(h.messaging.calls, contains('sendText:c-lumiere:hi'));

      h.messaging.sendGate!.complete();

      expect(await sending, isA<SendSent>());
      expect(newest(viewModel).entry.message.id, 'sent-1');
      expect(newest(viewModel).entry.state, EntryState.sent);
      expect(
        bubbles(viewModel).where((BubbleItem b) => b.entry.isPending),
        isEmpty,
      );
    });

    test('blank text is not sent (D7)', () async {
      final ChatViewModel viewModel = await ready();

      expect(await viewModel.send('   '), isA<SendIgnored>());
      expect(h.count('sendText'), 0);
    });

    test('a closed chat sends nothing', () async {
      h.messaging.details['c-closed'] = detailWith(<String, Object?>{
        'id': 'c-closed',
        'canWrite': false,
      });
      final ChatViewModel viewModel = await ready(conversationId: 'c-closed');

      expect(await viewModel.send('hi'), isA<SendIgnored>());
      expect(h.count('sendText'), 0);
    });

    test('a failure reads "Not sent" and a tap sends it again', () async {
      final ChatViewModel viewModel = await ready();
      h.messaging.sendError = const NetworkFailure();

      expect(await viewModel.send('hi'), isA<SendFailed>());
      expect(newest(viewModel).entry.state, EntryState.failed);

      h.messaging.sendError = null;
      final String localId = newest(viewModel).entry.message.id;

      expect(await viewModel.retry(localId), isA<SendSent>());
      expect(newest(viewModel).entry.message.id, 'sent-1');
    });

    test('dispute chats write through the dispute route', () async {
      final ChatViewModel viewModel = await ready(conversationId: 'c-dispute');

      await viewModel.send('x');

      expect(h.messaging.calls, contains('sendDisputeText:d-2041:x'));
    });
  });

  group('a chat closed under us', () {
    Future<void> closesOn(Failure failure) async {
      final ChatViewModel viewModel = await ready();
      h.messaging.sendError = failure;

      expect(await viewModel.send('hi'), isA<SendClosed>());
      expect(viewModel.composerMode, ComposerMode.closed);
      expect(newest(viewModel).entry.state, EntryState.failed);

      h.messaging.sendError = null;
      expect(
        await viewModel.retry(newest(viewModel).entry.message.id),
        isA<SendIgnored>(),
      );
    }

    test(
      '409 CONVERSATION_CLOSED',
      () => closesOn(
        apiFailure(ApiErrorCode.conversationClosed, statusCode: 409),
      ),
    );

    test(
      '403 CONVERSATION_CLOSED',
      () => closesOn(
        apiFailure(ApiErrorCode.conversationClosed, statusCode: 403),
      ),
    );

    test(
      'CONVERSATION_READ_ONLY',
      () => closesOn(
        apiFailure(ApiErrorCode.conversationReadOnly, statusCode: 403),
      ),
    );
  });

  group('photos', () {
    test('a GIF is refused before it is attached', () async {
      final ChatViewModel viewModel = await ready();

      expect(viewModel.attach(image('a.gif')), ImageProblem.wrongType);
      expect(viewModel.attachment, isNull);
    });

    test('a photo over the limit is refused', () async {
      final ChatViewModel viewModel = await ready();

      expect(
        viewModel.attach(image('a.jpg', bytes: 10 * 1024 * 1024 + 1)),
        ImageProblem.tooLarge,
      );
    });

    test('a photo goes out with its caption, shown from memory', () async {
      final ChatViewModel viewModel = await ready();
      expect(viewModel.attach(image('a.jpg')), isNull);
      h.messaging.sendGate = Completer<void>();

      final Future<SendOutcome> sending = viewModel.send('cap');

      expect(newest(viewModel).entry.localImage?.name, 'a.jpg');
      expect(viewModel.attachment, isNull);
      expect(h.messaging.calls, contains('sendPhoto:c-lumiere:a.jpg:cap'));

      h.messaging.sendGate!.complete();
      expect(await sending, isA<SendSent>());
    });

    test('a photo alone needs no text', () async {
      final ChatViewModel viewModel = await ready();
      viewModel.attach(image('a.png'));

      expect(await viewModel.send(''), isA<SendSent>());
      expect(h.messaging.calls, contains('sendPhoto:c-lumiere:a.png:null'));
    });

    test('FILE_TOO_LARGE from the server is a photo problem', () async {
      final ChatViewModel viewModel = await ready();
      viewModel.attach(image('a.jpg'));
      h.messaging.sendError = apiFailure(
        ApiErrorCode.fileTooLarge,
        statusCode: 413,
      );

      final SendOutcome outcome = await viewModel.send('');

      expect(outcome, isA<SendPhotoRejected>());
      expect((outcome as SendPhotoRejected).problem, ImageProblem.tooLarge);
    });

    test('disputes and drafts take no photos', () async {
      final ChatViewModel dispute = await ready(conversationId: 'c-dispute');
      final ChatViewModel draft = h.build(
        draft: const ChatDraftPeer(userId: 'p-1', name: 'Salle Yasmine'),
      );
      final ChatViewModel direct = await ready();

      expect(dispute.canAttach, isFalse);
      expect(draft.canAttach, isFalse);
      expect(direct.canAttach, isTrue);
    });
  });

  group('drafts (decision 2)', () {
    ChatViewModel draft() => h.build(
      draft: const ChatDraftPeer(userId: 'p-1', name: 'Salle Yasmine'),
    );

    test('the first send creates the chat and hands it over', () async {
      final ChatViewModel viewModel = draft();

      final SendOutcome outcome = await viewModel.send('Hello');

      expect(
        h.messaging.calls,
        containsAllInOrder(<String>['start:p-1:Hello', 'messages:c-new:null']),
      );
      expect(outcome, isA<SendStarted>());
      final SendStarted started = outcome as SendStarted;
      expect(started.conversationId, 'c-new');
      expect(started.opening.page?.items.single.body, 'Hello');
    });

    test('a refused recipient puts the text back', () async {
      h.messaging.startError = apiFailure(
        ApiErrorCode.recipientInvalid,
        statusCode: 422,
      );
      final ChatViewModel viewModel = draft();

      final SendOutcome outcome = await viewModel.send('Hello');

      expect(outcome, isA<SendStartRejected>());
      expect((outcome as SendStartRejected).text, 'Hello');
      expect(viewModel.thread, isEmpty);
    });

    test('a network failure can be retried', () async {
      h.messaging.startError = const NetworkFailure();
      final ChatViewModel viewModel = draft();

      expect(await viewModel.send('Hello'), isA<SendFailed>());

      h.messaging.startError = null;
      final SendOutcome outcome = await viewModel.retry(
        newest(viewModel).entry.message.id,
      );

      expect(outcome, isA<SendStarted>());
      expect(h.count('start:p-1:Hello'), 2);
    });

    test('a second send while the first is starting is ignored', () async {
      final ChatViewModel viewModel = draft();
      h.messaging.gate = Completer<void>();

      final Future<SendOutcome> first = viewModel.send('a');
      final SendOutcome second = await viewModel.send('b');

      expect(second, isA<SendIgnored>());
      h.messaging.gate!.complete();
      expect(await first, isA<SendStarted>());
      expect(h.count('start:'), 1);
    });
  });

  test('a poll that brings our message mid-send leaves one bubble', () async {
    final ChatViewModel viewModel = await ready();
    h.messaging.sendGate = Completer<void>();
    final Future<SendOutcome> sending = viewModel.send('poll race');

    // The server already stored the message; the poll finds it before the
    // send's own answer arrives. The fake's answer reuses the id sent-1.
    h.messaging.threads['c-lumiere']!.add(
      message(
        'sent-1',
        at: DateTime.parse('2026-03-12T12:00:00Z').toLocal(),
        mine: true,
        body: 'poll race',
      ),
    );
    await h.updates.tick();
    h.messaging.sendGate!.complete();
    await sending;

    expect(
      bubbleIds(viewModel).where((String id) => id == 'sent-1'),
      hasLength(1),
    );
    expect(
      bubbles(viewModel).where((BubbleItem b) => b.entry.isPending),
      isEmpty,
    );
    expect(bubbles(viewModel), hasLength(6));
  });

  test('a send answered while a poll is out survives the stale page', () async {
    final _StalePolls messaging = _StalePolls();
    h = ChatHarness(messaging: messaging);
    final ChatViewModel viewModel = await ready();

    messaging.pollGate = Completer<void>();
    final Future<void> poll = h.updates.tick();
    expect(await viewModel.send('mid poll'), isA<SendSent>());
    messaging.pollGate!.complete();
    await poll;

    expect(bubbleIds(viewModel), contains('sent-1'));
  });

  group('reports (D16)', () {
    late ChatViewModel viewModel;
    late ChatMessage photo;

    setUp(() async {
      viewModel = await ready();
      photo = bubbles(viewModel)
          .firstWhere((BubbleItem b) => b.entry.message.id == 'm-4')
          .entry
          .message;
    });

    test('a blank note is not sent', () async {
      final ReportOutcome outcome = await viewModel.reportMessage(
        photo,
        ReportReason.spam,
        '  ',
      );

      expect(h.messaging.calls, contains('reportMessage:m-4:spam:null'));
      expect((outcome as ReportSent).created, isTrue);
    });

    test('says when it was already reported', () async {
      h.messaging.reportCreated = false;

      final ReportOutcome outcome = await viewModel.reportPeer(
        ReportReason.fake,
        ' scam ',
      );

      expect(h.messaging.calls, contains('reportUser:p-lumiere:fake:scam'));
      expect((outcome as ReportSent).created, isFalse);
    });

    test('a failure is handed back', () async {
      h.messaging.failNext = const NetworkFailure();

      expect(
        await viewModel.reportMessage(photo, ReportReason.other, null),
        isA<ReportFailed>(),
      );
    });

    test('a draft reports the provider it is addressed to', () async {
      final ChatViewModel draft = h.build(
        draft: const ChatDraftPeer(userId: 'p-1', name: 'Salle Yasmine'),
      );

      await draft.reportPeer(ReportReason.spam, null);

      expect(h.messaging.calls, contains('reportUser:p-1:spam:null'));
    });
  });
}

/// Answers a newest-page request from a snapshot taken when the request
/// left, and holds it on [pollGate] — the server's view before a send that
/// lands while the poll is out.
class _StalePolls extends FakeMessagingRepository {
  Completer<void>? pollGate;

  @override
  Future<MessagePage> messages(String conversationId, {String? before}) async {
    final Completer<void>? gate = pollGate;
    if (gate == null || before != null) {
      return super.messages(conversationId, before: before);
    }
    final List<ChatMessage> snapshot = List<ChatMessage>.of(
      threads[conversationId] ?? <ChatMessage>[],
    );
    await gate.future;
    return MessagePage(items: snapshot, hasMore: false, nextBefore: null);
  }
}
