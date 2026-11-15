import 'package:bloc_test/bloc_test.dart';
import 'package:cart_four_ways/bloc/cart_bloc.dart';
import 'package:cart_four_ways/bloc/cart_event.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  blocTest<CartBloc, CartState>(
    'add twice and apply SAVE10 -> total is 88.2',
    build: CartBloc.new,
    act: (bloc) {
      bloc.add(CartProductAdded(catalog[0]));
      bloc.add(CartProductAdded(catalog[0]));
      bloc.add(const CartCouponApplied('SAVE10'));
    },
    verify: (bloc) => expect(bloc.state.total, 88.2),
  );

  blocTest<CartBloc, CartState>(
    'checkout failure keeps lines and status failure',
    build: () {
      final mockCheckoutApi = MockCheckoutApi();
      when(() => mockCheckoutApi.submit(any())).thenThrow(
        const CheckoutException('Card declined'),
      );
      return CartBloc(checkoutApi: mockCheckoutApi);
    },
    act: (bloc) {
      bloc.add(CartProductAdded(catalog[0]));
      bloc.add(CartProductAdded(catalog[0]));
      bloc.add(const CartCheckoutRequested());
    },
    verify: (bloc) {
      expect(bloc.state.status, CheckoutStatus.failure);
      expect(bloc.state.lines.length, 1);
      expect(bloc.state.lines.first.qty, 2);
      expect(bloc.state.checkoutError, 'Card declined');
    },
  );

  late MockCheckoutApi mockCheckoutApi;

  blocTest<CartBloc, CartState>(
    'duplicate checkout requests are dropped',
    build: () {
      mockCheckoutApi = MockCheckoutApi();
      when(() => mockCheckoutApi.submit(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return 'ORD-42';
      });
      return CartBloc(checkoutApi: mockCheckoutApi);
    },
    act: (bloc) async {
      bloc.add(const CartCheckoutRequested());
      bloc.add(const CartCheckoutRequested());
      await Future<void>.delayed(const Duration(milliseconds: 150));
    },
    verify: (bloc) {
      expect(bloc.state.status, CheckoutStatus.success);
      expect(bloc.state.orderId, 'ORD-42');
      verify(() => mockCheckoutApi.submit(any())).called(1);
    },
  );
}
