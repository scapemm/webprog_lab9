import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';

class SetStateCartPage extends StatefulWidget {
  const SetStateCartPage({super.key});

  @override
  State<SetStateCartPage> createState() => _SetStateCartPageState();
}

class _SetStateCartPageState extends State<SetStateCartPage> {
  CartState _state = const CartState();
  final List<CartState> _history = <CartState>[];
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _recordHistory() {
    _history.add(_state);
  }

  void _applyCoupon() {
    final value = _couponController.text.trim();
    if (value == 'SAVE10') {
      setState(() {
        _recordHistory();
        _state = _state.copyWith(coupon: value, couponError: '');
      });
      return;
    }

    setState(() {
      _recordHistory();
      _state = _state.copyWith(
        coupon: value,
        couponError: 'Invalid coupon code',
      );
    });
  }

  void _add(Product product) {
    setState(() {
      _recordHistory();
      _state = _state.copyWith(lines: _state.lines.withProduct(product));
    });
  }

  void _remove(String id) {
    setState(() {
      _recordHistory();
      _state = _state.copyWith(lines: _state.lines.without(id));
    });
  }

  void _changeQty(String id, int delta) {
    final next = _state.lines.changeQty(id, delta);
    if (next.length == _state.lines.length &&
        next.every(
          (line) => _state.lines.any(
            (old) => old.product.id == line.product.id && old.qty == line.qty,
          ),
        )) {
      return;
    }

    setState(() {
      _recordHistory();
      _state = _state.copyWith(lines: next);
    });
  }

  Future<void> _checkout() async {
    setState(() {
      _state = _state.copyWith(
        checkoutStatus: CheckoutStatus.submitting,
        checkoutError: '',
        orderId: '',
      );
    });

    try {
      final orderId = await CheckoutApi().submit(_state.total);
      if (!mounted) return;

      setState(() {
        _state = _state.copyWith(
          checkoutStatus: CheckoutStatus.success,
          orderId: orderId,
          lines: const <CartLine>[],
          coupon: '',
          couponError: '',
          checkoutError: '',
        );
        _couponController.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order $orderId placed successfully')),
      );
    } on CheckoutException catch (error) {
      if (!mounted) return;
      setState(() {
        _state = _state.copyWith(
          checkoutStatus: CheckoutStatus.failure,
          checkoutError: error.message,
        );
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          content: Text(error.message),
          leading: const Icon(Icons.error_outline, color: Colors.red),
          actions: [
            TextButton(
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    }
  }

  void _undo() {
    if (_history.isEmpty) return;

    setState(() {
      _state = _history.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalText = _state.total.toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · setState'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: _history.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CartBody(
              lines: _state.lines,
              onAdd: _add,
              onRemove: _remove,
              onQtyChanged: _changeQty,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        decoration: InputDecoration(
                          labelText: 'Coupon code',
                          hintText: 'SAVE10',
                          errorText: _state.couponError.isEmpty
                              ? null
                              : _state.couponError,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _applyCoupon,
                      child: const Text('Apply'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Items'),
                            Text(_state.itemCount.toString()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text(_state.subtotal.toStringAsFixed(2)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount'),
                            Text(_state.discount.toStringAsFixed(2)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [const Text('Total'), Text(totalText)],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        _state.checkoutStatus == CheckoutStatus.submitting
                        ? null
                        : _checkout,
                    icon: _state.checkoutStatus == CheckoutStatus.submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shopping_cart_checkout),
                    label: Text(
                      _state.checkoutStatus == CheckoutStatus.submitting
                          ? 'Checking out...'
                          : 'Checkout',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
