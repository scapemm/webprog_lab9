import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../widgets/cart_body.dart';
import 'cart_notifier.dart';

class RiverpodCartPage extends ConsumerStatefulWidget {
  const RiverpodCartPage({super.key});

  @override
  ConsumerState<RiverpodCartPage> createState() => _RiverpodCartPageState();
}

class _RiverpodCartPageState extends ConsumerState<RiverpodCartPage> {
  late final TextEditingController _couponController;

  @override
  void initState() {
    super.initState();
    _couponController = TextEditingController();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final canUndo = ref.watch(canUndoProvider);

    ref.listen<CheckoutStatus>(cartProvider.select((state) => state.status), (
      previous,
      next,
    ) {
      if (next == CheckoutStatus.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Order ${cart.orderId} placed')));
      }

      if (next == CheckoutStatus.failure) {
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            content: Text(cart.checkoutError),
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
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Riverpod'),
        actions: [
          IconButton(
            onPressed: canUndo ? cartNotifier.undo : null,
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CartBody(
              lines: cart.lines,
              onAdd: cartNotifier.add,
              onRemove: cartNotifier.remove,
              onQtyChanged: cartNotifier.changeQty,
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
                          errorText: cart.couponError.isEmpty
                              ? null
                              : cart.couponError,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () =>
                          cartNotifier.applyCoupon(_couponController.text),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const CartSummaryCard(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: cart.status == CheckoutStatus.submitting
                        ? null
                        : cartNotifier.checkout,
                    icon: cart.status == CheckoutStatus.submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shopping_cart_checkout),
                    label: Text(
                      cart.status == CheckoutStatus.submitting
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

class CartSummaryCard extends ConsumerWidget {
  const CartSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCount = ref.watch(
      cartProvider.select((state) => state.itemCount),
    );
    final subtotal = ref.watch(cartProvider.select((state) => state.subtotal));
    final discount = ref.watch(cartProvider.select((state) => state.discount));
    final total = ref.watch(cartProvider.select((state) => state.total));

    debugPrint('CartSummaryCard build: total=$total');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text('Items'), Text(itemCount.toString())],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text(subtotal.toStringAsFixed(2)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discount'),
                Text(discount.toStringAsFixed(2)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text('Total'), Text(total.toStringAsFixed(2))],
            ),
          ],
        ),
      ),
    );
  }
}
