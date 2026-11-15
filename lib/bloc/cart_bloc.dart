import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import 'cart_event.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({CheckoutApi? checkoutApi})
      : _checkoutApi = checkoutApi ?? CheckoutApi(),
        super(const CartState()) {
    on<CartProductAdded>(_onProductAdded);
    on<CartProductRemoved>(_onProductRemoved);
    on<CartQtyChanged>(_onQtyChanged);
    on<CartCouponApplied>(_onCouponApplied);
    on<CartCheckoutRequested>(_onCheckoutRequested, transformer: droppable());
    on<CartUndoRequested>(_onUndoRequested);
  }

  final CheckoutApi _checkoutApi;
  final List<CartState> _history = <CartState>[];

  bool get canUndo => _history.isNotEmpty;

  void _remember() => _history.add(state);

  Future<void> _onProductAdded(
    CartProductAdded event,
    Emitter<CartState> emit,
  ) async {
    _remember();
    emit(state.copyWith(lines: state.lines.withProduct(event.product)));
  }

  Future<void> _onProductRemoved(
    CartProductRemoved event,
    Emitter<CartState> emit,
  ) async {
    _remember();
    emit(state.copyWith(lines: state.lines.without(event.productId)));
  }

  Future<void> _onQtyChanged(
    CartQtyChanged event,
    Emitter<CartState> emit,
  ) async {
    final nextLines = state.lines.changeQty(event.productId, event.delta);
    if (nextLines == state.lines) {
      return;
    }

    _remember();
    emit(state.copyWith(lines: nextLines));
  }

  Future<void> _onCouponApplied(
    CartCouponApplied event,
    Emitter<CartState> emit,
  ) async {
    final code = event.code.trim();
    _remember();
    emit(
      state.copyWith(
        coupon: code,
        couponError: code == 'SAVE10' ? '' : 'Invalid coupon code',
      ),
    );
  }

  Future<void> _onCheckoutRequested(
    CartCheckoutRequested event,
    Emitter<CartState> emit,
  ) async {
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

  Future<void> _onUndoRequested(
    CartUndoRequested event,
    Emitter<CartState> emit,
  ) async {
    if (_history.isEmpty) {
      return;
    }
    emit(_history.removeLast());
  }
}
