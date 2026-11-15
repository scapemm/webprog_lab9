import 'package:bloc_test/bloc_test.dart';
import 'package:cart_four_ways/cubit/cart_cubit.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  blocTest<CartCubit, CartState>(
    'add twice and apply SAVE10 -> total is 88.2',
    build: CartCubit.new,
    act: (cubit) {
      cubit.add(catalog[0]);
      cubit.add(catalog[0]);
      cubit.applyCoupon('SAVE10');
    },
    verify: (cubit) => expect(cubit.state.total, 88.2),
  );

  blocTest<CartCubit, CartState>(
    'checkout failure keeps lines and status failure',
    build: () {
      final mockCheckoutApi = MockCheckoutApi();
      when(() => mockCheckoutApi.submit(any())).thenThrow(
        const CheckoutException('Card declined'),
      );
      return CartCubit(checkoutApi: mockCheckoutApi);
    },
    act: (cubit) async {
      cubit.add(catalog[0]);
      cubit.add(catalog[0]);
      await cubit.checkout();
    },
    verify: (cubit) {
      expect(cubit.state.status, CheckoutStatus.failure);
      expect(cubit.state.lines.length, 1);
      expect(cubit.state.lines.first.qty, 2);
      expect(cubit.state.checkoutError, 'Card declined');
    },
  );
}
