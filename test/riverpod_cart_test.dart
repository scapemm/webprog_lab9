import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/riverpod/cart_notifier.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  test('add twice and apply SAVE10 -> total is 88.2', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cartProvider.notifier);
    notifier.add(catalog[0]);
    notifier.add(catalog[0]);
    notifier.applyCoupon('SAVE10');

    expect(container.read(cartProvider).total, 88.2);
  });

  test('checkout failure keeps lines and status failure', () async {
    final mockCheckoutApi = MockCheckoutApi();
    when(() => mockCheckoutApi.submit(any()))
        .thenThrow(const CheckoutException('Card declined'));

    final container = ProviderContainer(
      overrides: [checkoutApiProvider.overrideWithValue(mockCheckoutApi)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(cartProvider.notifier);
    notifier.add(catalog[0]);
    notifier.add(catalog[0]);

    await notifier.checkout();

    final state = container.read(cartProvider);
    expect(state.status, CheckoutStatus.failure);
    expect(state.lines.length, 1);
    expect(state.lines.first.qty, 2);
    expect(state.checkoutError, 'Card declined');
  });
}
