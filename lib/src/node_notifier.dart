// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter/foundation.dart';
import 'package:supply_chain/supply_chain.dart';

/// A [ValueNotifier] acting as a supply chain leaf node.
///
/// The notifier creates a node within [scope]. The node consumes the given
/// [suppliers]. Whenever all suppliers have delivered their products,
/// [combine] merges the products into a new value and all listeners are
/// notified.
///
/// Feed the notifier into `CustomPainter(repaint: ...)` or a
/// `ValueListenableBuilder` to update the UI on supply chain changes.
///
/// Note: [ValueNotifier] skips values that are `==` to the current one.
/// Return fresh instances from [combine] or make sure changed products
/// are not equal to their predecessors.
class NodeNotifier<T> extends ValueNotifier<T> {
  /// Creates a leaf node in [scope] listening to [suppliers].
  ///
  /// - [combine] merges the supplier products into the notified value.
  ///   Products arrive in the order of [suppliers].
  /// - [initialValue] is used until the first production happened.
  /// - [key] must be camelCase and unique within [scope].
  ///   If omitted, a unique key is generated.
  NodeNotifier({
    required Scope scope,
    required List<String> suppliers,
    required this.combine,
    required T initialValue,
    String? key,
  }) : super(initialValue) {
    assert(!scope.isDisposed, 'The scope must not be disposed.');

    node = Node<T>(
      bluePrint: NodeBluePrint<T>(
        key: key ?? _uniqueKey(),
        initialProduct: initialValue,
        suppliers: suppliers,
        produce: (components, previousProduct, node) {
          final result = combine(components);
          value = result;
          return result;
        },
      ),
      scope: scope,
    );
  }

  /// The leaf node created by this notifier
  late final Node<T> node;

  /// The function merging the supplier products into the notified value.
  ///
  /// May be replaced, e.g. when a widget rebuilds with a new closure. The
  /// new function takes effect on the next production, i.e. when a supplier
  /// delivers a new product.
  T Function(List<dynamic> components) combine;

  // ...........................................................................
  @override
  void dispose() {
    // Dispose the node first. A leaf node has no customers and is
    // erased from its scope synchronously.
    node.dispose();
    super.dispose();
  }

  // ...........................................................................
  static int _instanceCounter = 0;
  static String _uniqueKey() => 'nodeNotifier${_instanceCounter++}';
}
