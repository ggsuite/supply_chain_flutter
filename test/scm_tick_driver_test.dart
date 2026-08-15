// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supply_chain/supply_chain.dart';
import 'package:supply_chain_flutter/supply_chain_flutter.dart';

void main() {
  late Scm scm;
  late Scope scope;
  late Node<int> supplier;
  late Node<int> customer;

  setUp(() {
    Scope.testResetIdCounter();
    Node.testResetIdCounter();

    scm = Scm(isTest: true);
    scope = Scope.root(key: 'root', scm: scm);

    supplier = Node<int>(
      bluePrint: const NodeBluePrint<int>(key: 'supplier', initialProduct: 1),
      scope: scope,
    );

    customer = Node<int>(
      bluePrint: NodeBluePrint<int>(
        key: 'customer',
        initialProduct: 0,
        suppliers: ['supplier'],
        produce: (components, previousProduct, node) {
          final [int supplier] = components;
          return supplier * 10;
        },
      ),
      scope: scope,
    );

    scm.flush();
  });

  group('ScmTickDriver', () {
    testWidgets('should tick the scm once per frame', (tester) async {
      await tester.pumpWidget(ScmTickDriver(scm: scm, child: const SizedBox()));

      // Change a supplier. In test mode the tick issued by the ticker
      // queues tasks which flush() drains deterministically.
      supplier.product = 2;
      await tester.pump();
      scm.flush(tick: false);

      expect(customer.product, 2 * 10);
    });

    testWidgets('should dispose the ticker on unmount', (tester) async {
      await tester.pumpWidget(ScmTickDriver(scm: scm, child: const SizedBox()));
      await tester.pumpWidget(const SizedBox());

      // No pending-ticker exception after unmount and pumping ends the test
      // successfully.
      supplier.product = 3;
      await tester.pump();
    });

    testWidgets('should tick a swapped scm after didUpdateWidget', (
      tester,
    ) async {
      await tester.pumpWidget(ScmTickDriver(scm: scm, child: const SizedBox()));

      // Swap the scm
      final scm1 = Scm(isTest: true);
      final scope1 = Scope.root(key: 'root1', scm: scm1);
      final supplier1 = Node<int>(
        bluePrint: const NodeBluePrint<int>(key: 'supplier', initialProduct: 1),
        scope: scope1,
      );
      final customer1 = Node<int>(
        bluePrint: NodeBluePrint<int>(
          key: 'customer',
          initialProduct: 0,
          suppliers: ['supplier'],
          produce: (components, previousProduct, node) {
            final [int supplier] = components;
            return supplier + 100;
          },
        ),
        scope: scope1,
      );
      scm1.flush();

      await tester.pumpWidget(
        ScmTickDriver(scm: scm1, child: const SizedBox()),
      );

      supplier1.product = 5;
      await tester.pump();
      scm1.flush(tick: false);

      expect(customer1.product, 5 + 100);
    });

    testWidgets('should build the child', (tester) async {
      await tester.pumpWidget(
        ScmTickDriver(
          scm: scm,
          child: const Text('child', textDirection: TextDirection.ltr),
        ),
      );
      expect(find.text('child'), findsOneWidget);
    });

    testWidgets('should stop ticking while muted by TickerMode', (
      tester,
    ) async {
      // A real scm driven purely by the ticker
      final realScm = Scm();
      final realScope = Scope.root(key: 'realRoot', scm: realScm);
      final realSupplier = Node<int>(
        bluePrint: const NodeBluePrint<int>(key: 'supplier', initialProduct: 1),
        scope: realScope,
      );
      final realCustomer = Node<int>(
        bluePrint: NodeBluePrint<int>(
          key: 'customer',
          initialProduct: 0,
          suppliers: ['supplier'],
          produce: (components, previousProduct, node) {
            final [int supplier] = components;
            return supplier * 10;
          },
        ),
        scope: realScope,
      );

      // Mount with the ticker muted
      await tester.pumpWidget(
        TickerMode(
          enabled: false,
          child: ScmTickDriver(scm: realScm, child: const SizedBox()),
        ),
      );

      // Change a supplier. Without a tick the frame priority customer
      // does not produce.
      realSupplier.product = 2;
      await tester.pump();
      await tester.pump();
      expect(realCustomer.product, 0);

      // Enable the ticker again - now production catches up
      await tester.pumpWidget(
        TickerMode(
          enabled: true,
          child: ScmTickDriver(scm: realScm, child: const SizedBox()),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(realCustomer.product, 2 * 10);

      // Unmount to stop the ticker
      await tester.pumpWidget(const SizedBox());
    });
  });
}
