// @license
// Copyright (c) ggsuite. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter/widgets.dart';
import 'package:supply_chain/supply_chain.dart';

/// Provides a supply chain scope to its descendants.
///
/// Either provide a [scope] directly or select a [childScope] of the scope
/// provided by the next [ScopeProvider] above:
///
/// ```dart
/// ScopeProvider(
///   scope: root,
///   child: ScopeProvider(
///     childScope: 'vertices',
///     child: ..., // ScopeProvider.of(context) returns root/vertices
///   ),
/// )
/// ```
///
/// Descendants read the scope with [ScopeProvider.of].
class ScopeProvider extends StatelessWidget {
  /// Constructor
  const ScopeProvider({
    super.key,
    this.scope,
    this.childScope,
    required this.child,
  }) : assert(
         (scope == null) != (childScope == null),
         'Provide either a scope or a childScope.',
       );

  /// The scope provided to the children
  final Scope? scope;

  /// The path of a child scope selected from the inherited scope,
  /// e.g. `vertices` or `geometry/columns`
  final String? childScope;

  /// The child widget
  final Widget child;

  // ...........................................................................
  /// The scope provided by the closest [ScopeProvider] above [context]
  static Scope of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      throw FlutterError(
        'ScopeProvider.of() called with a context '
        'containing no ScopeProvider.',
      );
    }
    return scope;
  }

  /// Like [of], but returns null when there is no [ScopeProvider] above
  static Scope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InheritedScope>()?.scope;

  // ...........................................................................
  @override
  Widget build(BuildContext context) {
    return _InheritedScope(scope: _resolveScope(context), child: child);
  }

  // ...........................................................................
  Scope _resolveScope(BuildContext context) {
    if (scope != null) {
      return scope!;
    }

    final parent = of(context);
    final result = parent.findChildScope(childScope!);
    if (result == null) {
      throw FlutterError(
        'ScopeProvider: The scope "${parent.key}" '
        'has no child scope "$childScope".',
      );
    }
    return result;
  }
}

// #############################################################################
class _InheritedScope extends InheritedWidget {
  const _InheritedScope({required this.scope, required super.child});

  final Scope scope;

  @override
  bool updateShouldNotify(covariant _InheritedScope oldWidget) =>
      oldWidget.scope != scope;
}
