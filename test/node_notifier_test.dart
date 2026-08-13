// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter_test/flutter_test.dart';
import 'package:supply_chain/supply_chain.dart';
import 'package:supply_chain_flutter/supply_chain_flutter.dart';

void main() {
  late Scm scm;
  late Scope scope;
  late Node<int> supplierA;
  late Node<int> supplierB;

  setUp(() {
    Scope.testResetIdCounter();
    Node.testResetIdCounter();

    scm = Scm(isTest: true);
    scope = Scope.root(key: 'root', scm: scm);

    supplierA = Node<int>(
      bluePrint: const NodeBluePrint<int>(key: 'supplierA', initialProduct: 1),
      scope: scope,
    );

    supplierB = Node<int>(
      bluePrint: const NodeBluePrint<int>(key: 'supplierB', initialProduct: 2),
      scope: scope,
    );

    scm.flush();
  });

  NodeNotifier<int> createSumNotifier({String? key}) => NodeNotifier<int>(
    scope: scope,
    suppliers: ['supplierA', 'supplierB'],
    combine: (components) {
      final [int a, int b] = components;
      return a + b;
    },
    initialValue: 0,
    key: key,
  );

  group('NodeNotifier', () {
    group('constructor', () {
      test('should create a leaf node within the scope', () {
        final notifier = createSumNotifier(key: 'sum');
        expect(scope.node<int>('sum'), notifier.node);
        expect(notifier.node.bluePrint.suppliers, ['supplierA', 'supplierB']);
        notifier.dispose();
      });

      test('should generate unique keys when no key is given', () {
        final notifier0 = createSumNotifier();
        final notifier1 = createSumNotifier();
        expect(
          notifier0.node.bluePrint.key,
          isNot(notifier1.node.bluePrint.key),
        );
        notifier0.dispose();
        notifier1.dispose();
      });

      test('should return initialValue until the first production', () {
        final notifier = createSumNotifier();
        expect(notifier.value, 0);
        notifier.dispose();
      });
    });

    group('value', () {
      test('should combine the supplier products after production', () {
        final notifier = createSumNotifier();
        scm.flush();
        expect(notifier.value, 1 + 2);
        notifier.dispose();
      });

      test('should update when a supplier product changes', () {
        final notifier = createSumNotifier();
        scm.flush();

        supplierA.product = 10;
        scm.flush();
        expect(notifier.value, 10 + 2);
        notifier.dispose();
      });

      test('should receive the components in supplier order', () {
        final notifier = NodeNotifier<List<int>>(
          scope: scope,
          suppliers: ['supplierB', 'supplierA'],
          combine: (components) => components.cast<int>(),
          initialValue: const [],
        );
        scm.flush();
        expect(notifier.value, [2, 1]);
        notifier.dispose();
      });
    });

    group('listeners', () {
      test('should notify once per production wave', () {
        final notifier = createSumNotifier();
        scm.flush();

        var calls = 0;
        notifier.addListener(() => calls++);

        supplierA.product = 100;
        scm.flush();
        expect(calls, 1);
        expect(notifier.value, 100 + 2);
        notifier.dispose();
      });
    });

    group('combine', () {
      test('should apply a replaced combine on the next production', () {
        final notifier = createSumNotifier();
        scm.flush();
        expect(notifier.value, 1 + 2);

        // Replace the combine function
        notifier.combine = (components) {
          final [int a, int b] = components;
          return a * b;
        };

        // The current value stays until the next production
        expect(notifier.value, 1 + 2);

        // A supplier change triggers a production using the new combine
        supplierA.product = 4;
        scm.flush();
        expect(notifier.value, 4 * 2);
        notifier.dispose();
      });
    });

    group('dispose', () {
      test('should erase the leaf node from the scope', () {
        final notifier = createSumNotifier(key: 'sum');
        expect(scope.node<int>('sum'), isNotNull);

        notifier.dispose();
        expect(scope.node<int>('sum'), isNull);
      });
    });

    group('multiple instances', () {
      test('should coexist within the same scope', () {
        final notifier0 = createSumNotifier();
        final notifier1 = createSumNotifier();
        scm.flush();

        supplierB.product = 20;
        scm.flush();

        expect(notifier0.value, 1 + 20);
        expect(notifier1.value, 1 + 20);
        notifier0.dispose();
        notifier1.dispose();
      });
    });
  });
}
