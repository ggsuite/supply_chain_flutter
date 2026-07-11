// @license
// Copyright (c) ggsuite. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supply_chain/supply_chain.dart';

import 'node_notifier.dart';

/// A widget rebuilding when the products of its suppliers change.
///
/// Creates a leaf node in [scope] listening to [suppliers]. Whenever a new
/// product was produced, [combine] merges the supplier products into a value
/// and [builder] rebuilds the subtree with it.
class NodeBuilder<T> extends StatefulWidget {
  /// Constructor
  const NodeBuilder({
    super.key,
    required this.scope,
    required this.suppliers,
    required this.combine,
    required this.initialValue,
    required this.builder,
    this.nodeKey,
  });

  /// The scope the leaf node is created in
  final Scope scope;

  /// The keys of the supplier nodes to listen to
  final List<String> suppliers;

  /// Merges the supplier products into the built value.
  ///
  /// When the widget rebuilds with a new [combine], it is forwarded to the
  /// leaf node and takes effect on the next production. Prefer routing
  /// mutable state through supplier nodes rather than capturing it in this
  /// closure, so changes are reflected reactively.
  final T Function(List<dynamic> components) combine;

  /// The value used until the first production happened
  final T initialValue;

  /// Builds the subtree for the current value
  final Widget Function(BuildContext context, T value) builder;

  /// The key of the created leaf node. Auto-generated when null.
  final String? nodeKey;

  @override
  State<NodeBuilder<T>> createState() => _NodeBuilderState<T>();
}

// #############################################################################
class _NodeBuilderState<T> extends State<NodeBuilder<T>> {
  late NodeNotifier<T> _notifier;

  @override
  void initState() {
    super.initState();
    _createNotifier();
  }

  @override
  void didUpdateWidget(covariant NodeBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final needsRecreate =
        oldWidget.scope != widget.scope ||
        oldWidget.nodeKey != widget.nodeKey ||
        !listEquals(oldWidget.suppliers, widget.suppliers);

    if (needsRecreate) {
      _notifier.dispose();
      _createNotifier();
    } else {
      // Forward the fresh combine so the leaf node does not keep a stale
      // closure. Takes effect on the next production.
      _notifier.combine = widget.combine;
    }
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  void _createNotifier() {
    _notifier = NodeNotifier<T>(
      scope: widget.scope,
      suppliers: widget.suppliers,
      combine: widget.combine,
      initialValue: widget.initialValue,
      key: widget.nodeKey,
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<T>(
    valueListenable: _notifier,
    builder: (context, value, _) => widget.builder(context, value),
  );
}
