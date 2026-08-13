// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter/material.dart';
import 'package:supply_chain/supply_chain.dart';
import 'package:supply_chain_flutter/supply_chain_flutter.dart';

void main() {
  // Create a supply chain with a root scope and a counter node.
  final scm = Scm();
  final scope = Scope.root(key: 'example', scm: scm);

  final counter = Node<int>(
    bluePrint: const NodeBluePrint<int>(key: 'counter', initialProduct: 0),
    scope: scope,
  );

  runApp(ExampleApp(scope: scope, counter: counter));
}

/// A counter app driven by a supply chain.
class ExampleApp extends StatelessWidget {
  /// Constructor
  const ExampleApp({super.key, required this.scope, required this.counter});

  /// The root scope of the supply chain
  final Scope scope;

  /// The counter node feeding the UI
  final Node<int> counter;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'supply_chain_flutter example',
      home:
          // ScmTickDriver drives scm.tick() once per Flutter frame.
          ScmTickDriver(
            scm: scope.scm,
            child:
                // ScopeProvider makes the scope available to descendants.
                ScopeProvider(
                  scope: scope,
                  child: Scaffold(
                    appBar: AppBar(title: const Text('supply_chain_flutter')),
                    body: Center(
                      // NodeBuilder rebuilds whenever the counter node
                      // produces.
                      child: Builder(
                        builder: (context) => NodeBuilder<int>(
                          scope: ScopeProvider.of(context),
                          suppliers: const ['counter'],
                          combine: (components) {
                            final [int count] = components;
                            return count;
                          },
                          initialValue: 0,
                          builder: (context, value) => Text(
                            'Counter: $value',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ),
                    ),
                    floatingActionButton: FloatingActionButton(
                      onPressed: () => counter.product = counter.product + 1,
                      child: const Icon(Icons.add),
                    ),
                  ),
                ),
          ),
    );
  }
}
