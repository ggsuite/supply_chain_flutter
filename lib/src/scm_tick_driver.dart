// @license
// Copyright (c) 2019 - 2024 ggsuite. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:supply_chain/supply_chain.dart';

/// Drives a supply chain manager from Flutter's frame pipeline.
///
/// Mount this widget once near the app root. It calls [Scm.tick] once per
/// frame. Without a tick, nodes with `Priority.frame` never produce and
/// animated nodes are never nominated.
///
/// Ticks run in `handleBeginFrame`. The production microtasks are drained
/// before `handleDrawFrame`, i.e. products and their repaints land in the
/// same frame.
///
/// Idle frames are not ticked: an idle tick would leave the scm's
/// production gate open and the next product change would produce
/// immediately instead of being coalesced into the following frame.
///
/// The ticker is muted by [TickerMode], e.g. when the enclosing route is
/// not visible.
class ScmTickDriver extends StatefulWidget {
  /// Constructor
  const ScmTickDriver({super.key, required this.scm, required this.child});

  /// The supply chain manager to be ticked once per frame
  final Scm scm;

  /// The child widget
  final Widget child;

  @override
  State<ScmTickDriver> createState() => _ScmTickDriverState();
}

// #############################################################################
class _ScmTickDriverState extends State<ScmTickDriver>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();

    // Reading widget.scm on every tick makes scm swaps in didUpdateWidget
    // work without recreating the ticker.
    _ticker = createTicker((_) => _tick())..start();
  }

  void _tick() {
    final scm = widget.scm;

    // Only tick when there is pending work. See class comment.
    final hasWork =
        scm.nominatedNodes.isNotEmpty ||
        scm.preparedNodes.isNotEmpty ||
        scm.animatedNodes.isNotEmpty;

    if (hasWork) {
      scm.tick();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
