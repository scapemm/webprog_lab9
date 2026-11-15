import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit({CheckoutApi? checkoutApi})
      : _checkoutApi = checkoutApi ?? CheckoutApi(),
        super(const CartState());

  final CheckoutApi _checkoutApi;
  final List<CartState> _history = <CartState>[];

  bool get canUndo => _history.isNotEmpty;

  void add(Product product) {
    _history.add(state);
    emit(state.copyWith(lines: state.lines.withProduct(product)));
  }

  void remove(String productId) {
    _history.add(state);
    emit(state.copyWith(lines: state.lines.without(productId)));
  }

  void changeQty(String productId, int delta) {
    final nextLines = state.lines.changeQty(productId, delta);
    if (nextLines == state.lines) {
      return;
    }

    _history.add(state);
    emit(state.copyWith(lines: nextLines));
  }

  void applyCoupon(String rawCode) {
    final code = rawCode.trim();
    _history.add(state);
    emit(
      state.copyWith(
        coupon: code,
        couponError: code == 'SAVE10' ? '' : 'Invalid coupon code',
      ),
    );
  }

  Future<void> checkout() async {
    emit(
      state.copyWith(
        status: CheckoutStatus.submitting,
        checkoutError: '',
        orderId: '',
      ),
    );

    try {
      final orderId = await _checkoutApi.submit(state.total);
      emit(
        state.copyWith(
          status: CheckoutStatus.success,
          orderId: orderId,
          lines: const <CartLine>[],
          coupon: '',
          couponError: '',
          checkoutError: '',
        ),
      );
    } on CheckoutException catch (error) {
      emit(
        state.copyWith(
          status: CheckoutStatus.failure,
          checkoutError: error.message,
        ),
      );
    }
  }

  void undo() {
    if (_history.isEmpty) {
      return;
    }
    emit(_history.removeLast());
  }
}
