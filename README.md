# supply_chain_flutter

supply_chain_flutter offers Flutter widgets fitting into the supply chain
ecosystem.

## Building blocks

- `NodeNotifier<T>`: A `ValueNotifier` that acts as a supply chain leaf node.
  It consumes a list of supplier nodes and notifies its listeners whenever
  a new product was produced. Feed it into `CustomPainter(repaint: ...)`
  or a `ValueListenableBuilder` to update the UI.
- `NodeBuilder<T>`: A widget rebuilding its subtree whenever the combined
  product of its supplier nodes changes.
- `ScmTickDriver`: Drives a supply chain manager from Flutter's frame
  pipeline. Mount it once near the app root. It calls `scm.tick()` once per
  frame (only when there is pending work), which makes nodes with
  `Priority.frame` produce and nominates animated nodes.
- `ScopeProvider`: Provides a supply chain scope to its descendants. It can
  provide a given scope or select a child scope of the scope provided by a
  parent `ScopeProvider`. Read it with `ScopeProvider.of(context)`.
