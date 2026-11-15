import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bloc/cart_page_bloc.dart';
import 'cubit/cart_page_cubit.dart';
import 'riverpod/cart_page_riverpod.dart';
import 'setstate/cart_page_setstate.dart';

void main() {
  runApp(const ProviderScope(child: CartFourWaysApp()));
}

class CartFourWaysApp extends StatelessWidget {
  const CartFourWaysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart Four Ways')),
      body: Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            FilledButton(
              onPressed: () => _openPage(context, const SetStateCartPage()),
              child: const Text('SetState Cart'),
            ),
            FilledButton(
              onPressed: () => _openPage(context, const RiverpodCartPage()),
              child: const Text('Riverpod Cart'),
            ),
            FilledButton(
              onPressed: () => _openPage(context, const CubitCartPage()),
              child: const Text('Cubit Cart'),
            ),
            FilledButton(
              onPressed: () => _openPage(context, const BlocCartPage()),
              child: const Text('Bloc Cart'),
            ),
          ],
        ),
      ),
    );
  }
}
