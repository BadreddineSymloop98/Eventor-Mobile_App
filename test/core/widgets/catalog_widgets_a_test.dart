import 'package:eventor/core/catalog/favourites_controller.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/widgets/atoms/app_icon.dart';
import 'package:eventor/core/widgets/atoms/app_network_image.dart';
import 'package:eventor/core/widgets/atoms/verified_badge.dart';
import 'package:eventor/core/widgets/molecules/app_toast.dart';
import 'package:eventor/core/widgets/molecules/favourite_button.dart';
import 'package:eventor/core/widgets/molecules/read_more_text.dart';
import 'package:eventor/core/widgets/molecules/section_header.dart';
import 'package:eventor/core/widgets/molecules/stat_strip.dart';
import 'package:eventor/core/widgets/molecules/state_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

Finder glyph(AppIcons icon) => find.byWidgetPredicate(
      (Widget widget) => widget is AppIcon && widget.icon == icon,
    );

void main() {
  group('AppNetworkImage.stableKey', () {
    const String signed =
        'https://api.example/api/v1/files/abc?variant=medium&exp=1790000000&sig=Zx9';

    test('drops the signature and keeps the size', () {
      expect(
        AppNetworkImage.stableKey(signed),
        'https://api.example/api/v1/files/abc?variant=medium',
      );
    });

    test('is the same for two signatures of one photo', () {
      const String resigned =
          'https://api.example/api/v1/files/abc?variant=medium&exp=1790000900&sig=Qq1';

      expect(AppNetworkImage.stableKey(resigned), AppNetworkImage.stableKey(signed));
    });

    test('tells two sizes of one photo apart', () {
      expect(
        AppNetworkImage.stableKey(
          'https://api.example/api/v1/files/abc?variant=thumb&exp=1&sig=a',
        ),
        isNot(AppNetworkImage.stableKey(signed)),
      );
    });

    test('leaves a URL with nothing to strip alone', () {
      expect(
        AppNetworkImage.stableKey('https://api.example/api/v1/files/abc'),
        'https://api.example/api/v1/files/abc',
      );
      expect(
        AppNetworkImage.stableKey('https://api.example/api/v1/files/abc?exp=1&sig=a'),
        'https://api.example/api/v1/files/abc',
      );
    });
  });

  group('AppNetworkImage', () {
    testWidgets('shows the category glyph when there is no photo',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const AppNetworkImage(
          url: null,
          width: 120,
          height: 80,
          placeholderIcon: AppIcons.flower,
        ),
      );

      expect(glyph(AppIcons.flower), findsOneWidget);
    });

    testWidgets('reads a mock photo from the bundle', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const AppNetworkImage(
          url: 'asset:assets/mock/photos/pexels-fleurs-1.webp',
          width: 120,
          height: 80,
        ),
      );

      final Image image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        'assets/mock/photos/pexels-fleurs-1.webp',
      );
    });
  });

  group('StateCard', () {
    testWidgets('offers a retry when loading failed', (WidgetTester tester) async {
      int retries = 0;
      await pumpAppWidget(tester, StateCard.error(onRetry: () => retries++));

      expect(find.text(l10n(tester).stateErrorTitle), findsOneWidget);
      await tester.tap(find.text(l10n(tester).stateRetry));

      expect(retries, 1);
    });

    testWidgets('offers its one way forward when empty', (WidgetTester tester) async {
      int taps = 0;
      await pumpAppWidget(
        tester,
        StateCard.empty(
          icon: AppIcons.heart,
          title: 'Nothing saved yet',
          body: 'Tap a heart to keep it here.',
          actionLabel: 'Explore',
          onAction: () => taps++,
        ),
      );

      await tester.tap(find.text('Explore'));

      expect(find.text('Nothing saved yet'), findsOneWidget);
      expect(taps, 1);
    });
  });

  group('SectionHeader', () {
    testWidgets('runs its link', (WidgetTester tester) async {
      int taps = 0;
      await pumpAppWidget(
        tester,
        SectionHeader(title: 'Ready Packs', actionLabel: 'See all', onAction: () => taps++),
      );

      await tester.tap(find.text('See all'));

      expect(taps, 1);
    });

    testWidgets('has no link without an action', (WidgetTester tester) async {
      await pumpAppWidget(tester, const SectionHeader(title: 'Reviews', actionLabel: 'See all'));

      expect(find.text('See all'), findsNothing);
    });
  });

  group('ReadMoreText', () {
    testWidgets('offers nothing for a short text', (WidgetTester tester) async {
      await pumpAppWidget(tester, const ReadMoreText('Two photographers.'));

      expect(find.text(l10n(tester).readMore), findsNothing);
    });

    testWidgets('expands and collapses a long one', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        ReadMoreText(List<String>.filled(80, 'A long description.').join(' ')),
      );

      await tester.tap(find.text(l10n(tester).readMore));
      await tester.pump();
      expect(find.text(l10n(tester).readLess), findsOneWidget);

      await tester.tap(find.text(l10n(tester).readLess));
      await tester.pump();
      expect(find.text(l10n(tester).readMore), findsOneWidget);
    });
  });

  group('StatStrip', () {
    testWidgets('keeps figures left to right in Arabic', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const StatStrip(<StatItem>[
          StatItem(value: '4.8', label: 'مراجعة', icon: AppIcons.starFilled),
          StatItem(value: '48', label: 'حجزًا مكتملًا'),
        ]),
        locale: arabicLocale,
      );

      expect(tester.widget<Text>(find.text('4.8')).textDirection, TextDirection.ltr);
      // The first item leads on the right in Arabic.
      expect(
        tester.getCenter(find.text('4.8')).dx,
        greaterThan(tester.getCenter(find.text('48')).dx),
      );
    });
  });

  testWidgets('VerifiedBadge says so', (WidgetTester tester) async {
    await pumpAppWidget(tester, const VerifiedBadge());

    expect(find.text(l10n(tester).verifiedProvider), findsOneWidget);
  });

  group('FavouriteButton', () {
    const FavouriteTarget studio = FavouriteTarget.service('s-1');
    late FakeFavouritesRepository repository;
    late FavouritesController controller;

    setUp(() {
      repository = FakeFavouritesRepository();
      controller = FavouritesController(repository);
    });

    tearDown(() => controller.dispose());

    Future<void> pumpHeart(WidgetTester tester, {bool initial = false}) {
      return pumpAppWidget(
        tester,
        ChangeNotifierProvider<FavouritesController>.value(
          value: controller,
          child: const Center(
            child: FavouriteButton(target: studio, initial: false),
          ),
        ),
      );
    }

    testWidgets('fills and saves when tapped', (WidgetTester tester) async {
      await pumpHeart(tester);
      expect(glyph(AppIcons.heart), findsOneWidget);

      await tester.tap(find.byType(FavouriteButton));
      await tester.pumpAndSettle();

      expect(glyph(AppIcons.heartFilled), findsOneWidget);
      expect(repository.calls, <String>['add:$studio']);
      expect(
        tester.getSemantics(find.byType(FavouriteButton)),
        isSemantics(label: l10n(tester).favouriteSaved, isButton: true),
      );
    });

    testWidgets('empties again and says so when the save fails',
        (WidgetTester tester) async {
      repository.failNext = const NetworkFailure();
      await pumpHeart(tester);

      await tester.tap(find.byType(FavouriteButton));
      await tester.pumpAndSettle();

      expect(glyph(AppIcons.heart), findsOneWidget);
      expect(find.text(l10n(tester).favouriteFailed), findsOneWidget);
    });
  });

  testWidgets('a toast with an action still goes away on its own',
      (WidgetTester tester) async {
    // Flutter keeps a SnackBar with an action up until dismissed unless told
    // otherwise; 17's undoable removal only commits once the toast closes.
    SnackBarClosedReason? reason;
    await pumpAppWidget(
      tester,
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async => reason = await showAppToast(
            context,
            'Removed',
            tone: AppToastTone.info,
            actionLabel: 'Undo',
            onAction: () {},
          ).closed,
          child: const Text('go'),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Removed'), findsNothing);
    expect(reason, SnackBarClosedReason.timeout);
  });

  testWidgets('a toast runs its action', (WidgetTester tester) async {
    int undos = 0;
    await pumpAppWidget(
      tester,
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showAppToast(
            context,
            'Removed',
            tone: AppToastTone.info,
            actionLabel: 'Undo',
            onAction: () => undos++,
          ),
          child: const Text('go'),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));

    expect(undos, 1);
  });
}
