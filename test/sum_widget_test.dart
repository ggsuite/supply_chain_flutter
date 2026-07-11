// @license
// Copyright (c) ggsuite. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supply_chain/supply_chain.dart';
import 'package:supply_chain_flutter/supply_chain_flutter.dart';

// #############################################################################
/// Two buttons increasing two supplier nodes and a text widget showing
/// their sum via a customer node
class _SumDemo extends StatelessWidget {
  const _SumDemo({
    required this.scm,
    required this.scope,
    required this.a,
    required this.b,
    required this.onCombine,
  });

  final Scm scm;
  final Scope scope;
  final Node<int> a;
  final Node<int> b;
  final void Function() onCombine;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ScmTickDriver(
        scm: scm,
        child: Scaffold(
          body: Column(
            children: [
              ElevatedButton(
                onPressed: () => a.product = a.product + 1,
                child: const Text('Increase A'),
              ),
              ElevatedButton(
                onPressed: () => b.product = b.product + 1,
                child: const Text('Increase B'),
              ),
              NodeBuilder<int>(
                scope: scope,
                suppliers: const ['a', 'b'],
                combine: (components) {
                  onCombine();
                  final [int a, int b] = components;
                  return a + b;
                },
                initialValue: 0,
                builder: (context, sum) => Text('Sum: $sum'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// #############################################################################
void main() {
  late Scm scm;
  late Scope scope;
  late Node<int> a;
  late Node<int> b;
  late int combineCalls;

  setUp(() {
    Scope.testResetIdCounter();
    Node.testResetIdCounter();

    // A real scm: production is driven by the ScmTickDriver, i.e. once
    // per frame.
    scm = Scm();
    scope = Scope.root(key: 'root', scm: scm);

    a = Node<int>(
      bluePrint: const NodeBluePrint<int>(key: 'a', initialProduct: 1),
      scope: scope,
    );
    b = Node<int>(
      bluePrint: const NodeBluePrint<int>(key: 'b', initialProduct: 2),
      scope: scope,
    );

    combineCalls = 0;
  });

  Widget demo() => _SumDemo(
    scm: scm,
    scope: scope,
    a: a,
    b: b,
    onCombine: () => combineCalls++,
  );

  /// Pumps until the chain has settled
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  group('Sum demo', () {
    testWidgets('should update the sum when one supplier changes', (
      tester,
    ) async {
      await tester.pumpWidget(demo());
      await settle(tester);
      expect(find.text('Sum: 3'), findsOneWidget);

      await tester.tap(find.text('Increase A'));
      await settle(tester);
      expect(find.text('Sum: 4'), findsOneWidget);

      await tester.tap(find.text('Increase B'));
      await settle(tester);
      expect(find.text('Sum: 5'), findsOneWidget);
    });

    testWidgets('should deliver multiple supplier changes within one frame '
        'as a single update', (tester) async {
      await tester.pumpWidget(demo());
      await settle(tester);
      expect(find.text('Sum: 3'), findsOneWidget);
      final callsBefore = combineCalls;

      // Change both suppliers within the same frame
      await tester.tap(find.text('Increase A'));
      await tester.tap(find.text('Increase B'));
      await settle(tester);

      // Both changes arrived in the sum ...
      expect(find.text('Sum: 5'), findsOneWidget);

      // ... but the customer combined only once
      expect(combineCalls, callsBefore + 1);

      // Idle frames do not trigger further combines
      await settle(tester);
      expect(combineCalls, callsBefore + 1);
    });
  });
}
