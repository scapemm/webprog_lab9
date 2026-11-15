import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../widgets/cart_body.dart';
import 'cart_cubit.dart';

class CubitCartPage extends StatefulWidget {
  const CubitCartPage({super.key});

  @override
  State<CubitCartPage> createState() => _CubitCartPageState();
}

class _CubitCartPageState extends State<CubitCartPage> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CartCubit(),
      child: Builder(
        builder: (context) {
          final cartCubit = context.read<CartCubit>();

          return BlocListener<CartCubit, CartState>(
            listenWhen: (previous, current) => previous.status != current.status,
            listener: (context, cart) {
              if (cart.status == CheckoutStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order ${cart.orderId} placed successfully')),
                );
              }

              if (cart.status == CheckoutStatus.failure) {
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
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Cart · Cubit'),
                actions: [
                  IconButton(
                    tooltip: 'Undo',
                    onPressed: cartCubit.canUndo ? cartCubit.undo : null,
                    icon: const Icon(Icons.undo),
                  ),
                ],
              ),
              body: BlocBuilder<CartCubit, CartState>(
                builder: (context, cart) {
                  return Column(
                    children: [
                      Expanded(
                        child: CartBody(
                          lines: cart.lines,
                          onAdd: cartCubit.add,
                          onRemove: cartCubit.remove,
                          onQtyChanged: cartCubit.changeQty,
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
                                      cartCubit.applyCoupon(_couponController.text),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Items'),
                                        Text(cart.itemCount.toString()),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Subtotal'),
                                        Text(cart.subtotal.toStringAsFixed(2)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Discount'),
                                        Text(cart.discount.toStringAsFixed(2)),
                                      ],
                                    ),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Total'),
                                        Text(cart.total.toStringAsFixed(2)),
                                      ],
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
                                    cart.status == CheckoutStatus.submitting
                                    ? null
                                    : () async => cartCubit.checkout(),
                                icon:
                                    cart.status == CheckoutStatus.submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
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
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
