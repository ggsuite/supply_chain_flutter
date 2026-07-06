// @license
// Copyright (c) 2019 - 2024 ggsuite. All Rights Reserved.
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

  setUp(() {
    Scope.testRestIdCounter();
    Node.testResetIdCounter();

    scm = Scm(isTest: true);
    scope = Scope.root(key: 'root', scm: scm);

    supplier = Node<int>(
      bluePrint: const NodeBluePrint<int>(key: 'supplier', initialProduct: 1),
      scope: scope,
    );

    scm.flush();
  });

  Widget builder({
    Scope? bScope,
    String? nodeKey,
    int Function(List<dynamic> components)? combine,
  }) => NodeBuilder<int>(
    scope: bScope ?? scope,
    suppliers: const ['supplier'],
    combine:
        combine ??
        (components) {
          final [int supplier] = components;
          return supplier;
        },
    initialValue: 0,
    nodeKey: nodeKey,
    builder: (context, value) =>
        Text('$value', textDirection: TextDirection.ltr),
  );

  group('NodeBuilder', () {
    testWidgets('should build with initialValue first', (tester) async {
      await tester.pumpWidget(builder());
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should rebuild with the produced value', (tester) async {
      await tester.pumpWidget(builder());
      scm.flush();
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      supplier.product = 42;
      scm.flush();
      await tester.pump();
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('should recreate the node on scope swap', (tester) async {
      await tester.pumpWidget(builder(nodeKey: 'builderNode'));
      expect(scope.node<int>('builderNode'), isNotNull);

      final scope1 = Scope.root(key: 'root1', scm: scm);
      Node<int>(
        bluePrint: const NodeBluePrint<int>(key: 'supplier', initialProduct: 7),
        scope: scope1,
      );

      await tester.pumpWidget(builder(bScope: scope1, nodeKey: 'builderNode'));
      expect(scope.node<int>('builderNode'), isNull);
      expect(scope1.node<int>('builderNode'), isNotNull);

      scm.flush();
      await tester.pump();
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('should keep the node when nothing changed', (tester) async {
      await tester.pumpWidget(builder(nodeKey: 'builderNode'));
      final node = scope.node<int>('builderNode');

      await tester.pumpWidget(builder(nodeKey: 'builderNode'));
      expect(scope.node<int>('builderNode'), same(node));
    });

    testWidgets('should erase the node on unmount', (tester) async {
      await tester.pumpWidget(builder(nodeKey: 'builderNode'));
      expect(scope.node<int>('builderNode'), isNotNull);

      await tester.pumpWidget(const SizedBox());
      expect(scope.node<int>('builderNode'), isNull);
    });

    testWidgets('should forward a new combine without recreating the node', (
      tester,
    ) async {
      await tester.pumpWidget(builder(nodeKey: 'builderNode'));
      final node = scope.node<int>('builderNode');
      scm.flush();
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      // Rebuild with a new combine that doubles the supplier value
      await tester.pumpWidget(
        builder(
          nodeKey: 'builderNode',
          combine: (components) {
            final [int supplier] = components;
            return supplier * 2;
          },
        ),
      );

      // The node was not recreated ...
      expect(scope.node<int>('builderNode'), same(node));

      // ... and the new combine takes effect on the next production
      supplier.product = 5;
      scm.flush();
      await tester.pump();
      expect(find.text('10'), findsOneWidget);
    });
  });
}
