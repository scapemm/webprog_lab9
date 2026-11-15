import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartNotifier extends Notifier<CartState> {
  final List<CartState> _history = <CartState>[];

  bool get canUndo => _history.isNotEmpty;

  @override
  CartState build() => const CartState();

  void _remember() {
    _history.add(state);
  }

  void add(Product product) {
    _remember();
    state = state.copyWith(lines: state.lines.withProduct(product));
  }

  void remove(String productId) {
    _remember();
    state = state.copyWith(lines: state.lines.without(productId));
  }

  void changeQty(String productId, int delta) {
    final nextLines = state.lines.changeQty(productId, delta);
    if (nextLines == state.lines) {
      return;
    }

    _remember();
    state = state.copyWith(lines: nextLines);
  }

  void applyCoupon(String rawCode) {
    final code = rawCode.trim();
    _remember();

    if (code == 'SAVE10') {
      state = state.copyWith(coupon: code, couponError: '');
      return;
    }

    state = state.copyWith(coupon: code, couponError: 'Invalid coupon code');
  }

  Future<void> checkout() async {
    state = state.copyWith(
      status: CheckoutStatus.submitting,
      checkoutError: '',
      orderId: '',
    );

    try {
      final api = ref.read(checkoutApiProvider);
      final orderId = await api.submit(state.total);
      state = state.copyWith(
        status: CheckoutStatus.success,
        orderId: orderId,
        checkoutError: '',
        lines: const <CartLine>[],
        coupon: '',
        couponError: '',
      );
    } on CheckoutException catch (error) {
      state = state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: error.message,
      );
    }
  }

  void undo() {
    if (_history.isEmpty) {
      return;
    }
    state = _history.removeLast();
  }
}

final checkoutApiProvider = Provider<CheckoutApi>((ref) => CheckoutApi());

final cartProvider = NotifierProvider.autoDispose<CartNotifier, CartState>(
  CartNotifier.new,
);

final canUndoProvider = Provider.autoDispose((ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).canUndo;
});
