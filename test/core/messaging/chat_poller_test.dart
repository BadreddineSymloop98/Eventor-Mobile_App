import 'dart:async';

import 'package:eventor/core/messaging/chat_poller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ticks once per interval while running', (
    WidgetTester tester,
  ) async {
    // Timer.periodic only runs on the fake clock once a binding exists.
    await tester.pumpWidget(const SizedBox());
    int ticks = 0;
    final TimerChatUpdates poller = TimerChatUpdates(
      followAppLifecycle: false,
    );
    addTearDown(poller.stop);

    poller.start(() async {
      ticks++;
    });

    await tester.pump(const Duration(seconds: 5));
    expect(ticks, 1);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    expect(ticks, 3);
  });

  testWidgets('pause stops ticks; resume ticks at once then on interval', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    int ticks = 0;
    final TimerChatUpdates poller = TimerChatUpdates(
      followAppLifecycle: false,
    );
    addTearDown(poller.stop);

    poller.start(() async {
      ticks++;
    });

    await tester.pump(const Duration(seconds: 5));
    expect(ticks, 1);

    poller.pause();
    await tester.pump(const Duration(seconds: 10));
    expect(ticks, 1); // no ticks while paused

    poller.resume();
    await tester.pump(Duration.zero); // flush resume's immediate tick
    expect(ticks, 2);

    await tester.pump(const Duration(seconds: 5));
    expect(ticks, 3);
  });

  testWidgets('stop ends ticking forever; a later resume does nothing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    int ticks = 0;
    final TimerChatUpdates poller = TimerChatUpdates(
      followAppLifecycle: false,
    );
    addTearDown(poller.stop);

    poller.start(() async {
      ticks++;
    });
    await tester.pump(const Duration(seconds: 5));
    expect(ticks, 1);

    poller.stop();
    await tester.pump(const Duration(seconds: 10));
    expect(ticks, 1);

    poller.resume();
    await tester.pump(const Duration(seconds: 10));
    expect(ticks, 1);
  });

  testWidgets('a slow tick is never overlapped by the next one', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    int calls = 0;
    final Completer<void> firstTick = Completer<void>();
    final TimerChatUpdates poller = TimerChatUpdates(
      followAppLifecycle: false,
    );
    addTearDown(poller.stop);

    poller.start(() async {
      calls++;
      await firstTick.future;
    });

    await tester.pump(const Duration(seconds: 5));
    expect(calls, 1); // the 5s tick started and is now awaiting the completer

    // The 10s and 15s ticks land while the first is still in flight, and
    // must be skipped rather than queued.
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 1);

    firstTick.complete();
    await tester.pump(Duration.zero); // let the in-flight tick settle
    expect(calls, 1); // completing the tick does not itself schedule one

    await tester.pump(const Duration(seconds: 5)); // the 20s tick
    expect(calls, 2);
  });

  testWidgets('a throwing tick is swallowed and ticking continues', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    int calls = 0;
    final TimerChatUpdates poller = TimerChatUpdates(
      followAppLifecycle: false,
    );
    addTearDown(poller.stop);

    poller.start(() async {
      calls++;
      throw StateError('poll failed');
    });

    await tester.pump(const Duration(seconds: 5));
    expect(calls, 1);

    await tester.pump(const Duration(seconds: 5));
    expect(calls, 2);

    await tester.pump(const Duration(seconds: 5));
    expect(calls, 3);
  });

  testWidgets(
    'follows app lifecycle: hidden pauses, coming back ticks at once',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      int ticks = 0;
      final TimerChatUpdates poller = TimerChatUpdates();
      addTearDown(poller.stop);

      poller.start(() async {
        ticks++;
      });

      await tester.pump(const Duration(seconds: 5));
      expect(ticks, 1);

      // AppLifecycleListener enforces the platform's legal transition order,
      // so hiding steps through inactive first rather than jumping straight
      // from resumed to hidden.
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.inactive,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump(const Duration(seconds: 10));
      expect(ticks, 1); // paused while hidden

      // Leaving hidden (toward inactive) is the "shown" transition, and it
      // fires before the app is fully resumed again.
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.inactive,
      );
      await tester.pump(Duration.zero); // flush resume's immediate tick
      expect(ticks, 2);

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump(const Duration(seconds: 5));
      expect(ticks, 3);
    },
  );
}
