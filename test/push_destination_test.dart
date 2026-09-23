import 'package:flutter_test/flutter_test.dart';
import 'package:nexmile_rider/core/push/push_destination.dart';
import 'package:nexmile_rider/core/router/app_router.dart';

void main() {
  group('PushDestination.fromData', () {
    test('an offer refreshes the board on the way in', () {
      // The one notification that is not a courtesy: the order sits going cold
      // until a rider takes it, and a board a minute stale may not show it.
      final PushDestination? destination = PushDestination.fromData(
        <String, Object?>{'type': 'order.offer', 'order_id': '123'},
      );

      expect(destination, isNotNull);
      expect(destination!.routeName, AppRoutes.home);
      expect(destination.refreshBoard, isTrue);
    });

    test('every other order type opens the rider surface without a refetch',
        () {
      for (final String type in <String>[
        'order.accepted',
        'order.rider_assigned',
        'order.picked_up',
        'order.delivered',
        'order.cancelled',
      ]) {
        final PushDestination? destination =
            PushDestination.fromData(<String, Object?>{'type': type});

        expect(destination?.routeName, AppRoutes.home, reason: type);
        expect(destination?.refreshBoard, isFalse, reason: type);
      }
    });

    test('a promotion does not interrupt a shift', () {
      for (final String type in <String>['promo', 'promotion', 'news']) {
        expect(
          PushDestination.fromData(<String, Object?>{'type': type}),
          isNull,
          reason: type,
        );
      }
    });

    test('a push this build cannot place lands nowhere', () {
      expect(PushDestination.fromData(const <String, Object?>{}), isNull);
      expect(
        PushDestination.fromData(<String, Object?>{'type': 'shift.reminder'}),
        isNull,
      );
    });
  });
}
