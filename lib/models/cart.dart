import 'package:flutter/foundation.dart';

class Product {
  const Product({required this.id, required this.name, required this.price});

  final String id;
  final String name;
  final double price;

  @override
  bool operator ==(Object other) {
    return other is Product &&
        other.id == id &&
        other.name == name &&
        other.price == price;
  }

  @override
  int get hashCode => Object.hash(id, name, price);
}

const catalog = [
  Product(id: 'p1', name: 'Keyboard', price: 49),
  Product(id: 'p2', name: 'Mouse', price: 25),
  Product(id: 'p3', name: 'Monitor', price: 199),
];

class CartLine {
  const CartLine({required this.product, required this.qty});

  final Product product;
  final int qty;

  double get subtotal => product.price * qty;

  CartLine copyWith({int? qty}) =>
      CartLine(product: product, qty: qty ?? this.qty);

  @override
  bool operator ==(Object other) {
    return other is CartLine && other.product == product && other.qty == qty;
  }

  @override
  int get hashCode => Object.hash(product, qty);
}

class CartState {
  const CartState({
    this.lines = const <CartLine>[],
    this.coupon = '',
    this.couponError = '',
    this.status = CheckoutStatus.idle,
    this.orderId = '',
    this.checkoutError = '',
  });

  final List<CartLine> lines;
  final String coupon;
  final String couponError;
  final CheckoutStatus status;
  final String orderId;
  final String checkoutError;

  CartState copyWith({
    List<CartLine>? lines,
    String? coupon,
    String? couponError,
    CheckoutStatus? status,
    CheckoutStatus? checkoutStatus,
    String? orderId,
    String? checkoutError,
  }) {
    final nextStatus = status ?? checkoutStatus ?? this.status;

    return CartState(
      lines: lines ?? this.lines,
      coupon: coupon ?? this.coupon,
      couponError: couponError ?? this.couponError,
      status: nextStatus,
      orderId: orderId ?? this.orderId,
      checkoutError: checkoutError ?? this.checkoutError,
    );
  }

  CheckoutStatus get checkoutStatus => status;

  double get subtotal => lines.subtotal;
  int get itemCount => lines.itemCount;
  double get discount => coupon == 'SAVE10' ? subtotal * 0.10 : 0;
  double get total => subtotal - discount;

  @override
  bool operator ==(Object other) {
    return other is CartState &&
        listEquals(lines, other.lines) &&
        coupon == other.coupon &&
        couponError == other.couponError &&
        status == other.status &&
        orderId == other.orderId &&
        checkoutError == other.checkoutError;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(lines),
    coupon,
    couponError,
    status,
    orderId,
    checkoutError,
  );
}

enum CheckoutStatus { idle, submitting, success, failure }

/// Pure, style-independent cart logic. Every state holder calls these.
extension CartLines on List<CartLine> {
  List<CartLine> withProduct(Product p) {
    final i = indexWhere((l) => l.product.id == p.id);
    if (i == -1) {
      return [...this, CartLine(product: p, qty: 1)];
    }
    return [
      for (final l in this)
        if (l.product.id == p.id) l.copyWith(qty: l.qty + 1) else l,
    ];
  }

  List<CartLine> changeQty(String productId, int delta) {
    final i = indexWhere((l) => l.product.id == productId);
    if (i == -1) {
      return this;
    }

    final nextQty = this[i].qty + delta;
    if (nextQty <= 0) {
      return [
        for (final l in this)
          if (l.product.id != productId) l,
      ];
    }

    return [
      for (final l in this)
        if (l.product.id == productId) l.copyWith(qty: nextQty) else l,
    ];
  }

  List<CartLine> without(String productId) => [
    for (final l in this)
      if (l.product.id != productId) l,
  ];

  double get subtotal => fold(0.0, (s, l) => s + l.subtotal);
  int get itemCount => fold(0, (s, l) => s + l.qty);
}
