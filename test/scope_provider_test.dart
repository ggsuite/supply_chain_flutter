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
  late Scope root;
  late Scope vertices;
  late Scope columns;

  setUp(() {
    Scope.testRestIdCounter();
    Node.testResetIdCounter();

    scm = Scm(isTest: true);
    root = Scope.root(key: 'root', scm: scm);
    vertices = Scope(
      bluePrint: const ScopeBluePrint(key: 'vertices'),
      parent: root,
    );
    columns = Scope(
      bluePrint: const ScopeBluePrint(key: 'columns'),
      parent: vertices,
    );
  });

  /// Builds a probe reading the provided scope via ScopeProvider.of
  Widget probe(void Function(BuildContext context) onBuild) => Builder(
    builder: (context) {
      onBuild(context);
      return const SizedBox();
    },
  );

  group('ScopeProvider', () {
    group('of', () {
      testWidgets('should return the provided scope', (tester) async {
        late Scope provided;
        await tester.pumpWidget(
          ScopeProvider(
            scope: root,
            child: probe((context) => provided = ScopeProvider.of(context)),
          ),
        );
        expect(provided, same(root));
      });

      testWidgets('should throw without a ScopeProvider above', (tester) async {
        Object? error;
        await tester.pumpWidget(
          probe((context) {
            try {
              ScopeProvider.of(context);
            } catch (e) {
              error = e;
            }
          }),
        );
        expect(error, isA<FlutterError>());
      });
    });

    group('maybeOf', () {
      testWidgets('should return null without a ScopeProvider above', (
        tester,
      ) async {
        Scope? provided = root;
        await tester.pumpWidget(
          probe((context) => provided = ScopeProvider.maybeOf(context)),
        );
        expect(provided, isNull);
      });
    });

    group('childScope', () {
      testWidgets('should select a child of the inherited scope', (
        tester,
      ) async {
        late Scope provided;
        await tester.pumpWidget(
          ScopeProvider(
            scope: root,
            child: ScopeProvider(
              childScope: 'vertices',
              child: probe((context) => provided = ScopeProvider.of(context)),
            ),
          ),
        );
        expect(provided, same(vertices));
      });

      testWidgets('should select a nested child via a path', (tester) async {
        late Scope provided;
        await tester.pumpWidget(
          ScopeProvider(
            scope: root,
            child: ScopeProvider(
              childScope: 'vertices/columns',
              child: probe((context) => provided = ScopeProvider.of(context)),
            ),
          ),
        );
        expect(provided, same(columns));
      });

      testWidgets('should throw when the child scope does not exist', (
        tester,
      ) async {
        await tester.pumpWidget(
          ScopeProvider(
            scope: root,
            child: const ScopeProvider(
              childScope: 'unknown',
              child: SizedBox(),
            ),
          ),
        );
        expect(tester.takeException(), isA<FlutterError>());
      });
    });

    group('constructor', () {
      test('should assert that either scope or childScope is given', () {
        expect(
          () => ScopeProvider(child: const SizedBox()),
          throwsAssertionError,
        );
        expect(
          () => ScopeProvider(
            scope: root,
            childScope: 'vertices',
            child: const SizedBox(),
          ),
          throwsAssertionError,
        );
      });
    });

    group('updateShouldNotify', () {
      testWidgets('should rebuild dependents when the scope changes', (
        tester,
      ) async {
        final scopes = <Scope>[];
        final child = probe((context) => scopes.add(ScopeProvider.of(context)));

        await tester.pumpWidget(ScopeProvider(scope: root, child: child));
        await tester.pumpWidget(ScopeProvider(scope: vertices, child: child));
        await tester.pumpWidget(ScopeProvider(scope: vertices, child: child));

        expect(scopes, [root, vertices]);
      });
    });
  });
}
