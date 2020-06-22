import 'dart:async';

import 'package:drag_and_drop_lists/drag_and_drop_builder_parameters.dart';
import 'package:drag_and_drop_lists/drag_and_drop_item.dart';
import 'package:drag_and_drop_lists/drag_and_drop_item_target.dart';
import 'package:drag_and_drop_lists/drag_and_drop_item_wrapper.dart';
import 'package:drag_and_drop_lists/drag_and_drop_list_interface.dart';
import 'package:drag_and_drop_lists/programmatic_expansion_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class DragAndDropListExpansion implements DragAndDropListExpansionInterface {
  final Widget title;
  final Widget subtitle;
  final Widget trailing;
  final Widget leading;
  final bool initiallyExpanded;
  final Function(bool) onExpansionChanged;
  final Color backgroundColor;
  final List<DragAndDropItem> children;
  final Key key;
  final Widget contentsWhenEmpty;
  final Widget lastTarget;
  ValueNotifier<bool> _expanded = ValueNotifier<bool>(true);
  GlobalKey<ProgrammaticExpansionTileState> _expansionKey = GlobalKey<ProgrammaticExpansionTileState>();

  DragAndDropListExpansion(
      {this.children,
      this.title,
      this.subtitle,
      this.trailing,
      this.leading,
      this.initiallyExpanded = false,
      this.backgroundColor,
      this.onExpansionChanged,
      this.contentsWhenEmpty,
      this.lastTarget,
      this.key}) {
    _expanded.value = initiallyExpanded;
  }

  @override
  Widget generateWidget(DragAndDropBuilderParameters params) {
    var contents = _generateDragAndDropListInnerContents(params);

    Widget expandable = ProgrammaticExpansionTile(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      leading: leading,
      backgroundColor: backgroundColor,
      initiallyExpanded: _expanded.value,
      onExpansionChanged: _onSetExpansion,
      key: _expansionKey,
      children: contents,
    );

    if (params.listDecoration != null) {
      expandable = Container(
        decoration: params.listDecoration,
        child: expandable,
      );
    }

    if (params.listPadding != null) {
      expandable = Padding(
        padding: params.listPadding,
        child: expandable,
      );
    }

    Widget toReturn = ValueListenableBuilder(
      valueListenable: _expanded,
      child: expandable,
      builder: (context, error, child) {
        if (!_expanded.value) {
          return Stack(
            children: <Widget>[
              child,
              Positioned.fill(
                child: DragTarget<DragAndDropItem>(
                  builder: (context, candidateData, rejectedData) {
                    if (candidateData != null && candidateData.isNotEmpty) {}
                    return Container();
                  },
                  onWillAccept: (incoming) {
                    _startExpansionTimer();
                    return false;
                  },
                  onLeave: (incoming) {
                    _stopExpansionTimer();
                  },
                  onAccept: (incoming) {
                  },
                ),
              )
            ],
          );
        }
        else {
          return child;
        }
      },
    );

    return toReturn;
  }

  List<Widget> _generateDragAndDropListInnerContents(DragAndDropBuilderParameters params) {
    var contents = List<Widget>();
    if (children != null && children.isNotEmpty) {
      children.forEach((element) => contents.add(DragAndDropItemWrapper(
            child: element,
            onPointerDown: params.onPointerDown,
            onPointerUp: params.onPointerUp,
            onPointerMove: params.onPointerMove,
            onItemReordered: params.onItemReordered,
            sizeAnimationDuration: params.itemSizeAnimationDuration,
            ghostOpacity: params.itemGhostOpacity,
            ghost: params.itemGhost,
            dragOnLongPress: params.dragOnLongPress,
            draggingWidth: params.draggingWidth,
            axis: params.axis,
            verticalAlignment: params.verticalAlignment,
          )));
      contents.add(DragAndDropItemTarget(
        parent: this,
        parameters: params,
        onReorderOrAdd: params.onItemDropOnLastTarget,
        child: lastTarget ??
            Container(
              height: 20,
            ),
      ));
    } else {
      contents.add(
        contentsWhenEmpty ??
            Text(
              'Empty list',
              style: TextStyle(
                fontStyle: FontStyle.italic,
              ),
            ),
      );
      contents.add(
        DragAndDropItemTarget(
          parent: this,
          parameters: params,
          onReorderOrAdd: params.onItemDropOnLastTarget,
          child: lastTarget ??
              Container(
                height: 20,
              ),
        ),
      );
    }
    return contents;
  }

  @override
  toggleExpanded() {
    if (_expanded.value)
      collapse();
    else
      expand();
  }

  @override
  collapse() {
    if (!_expanded.value) {
      _expanded.value = false;
      _expansionKey.currentState.collapse();
    }
  }

  @override
  expand() {
    if (!_expanded.value) {
      _expanded.value = true;
      _expansionKey.currentState.expand();
    }
  }

  _onSetExpansion(bool expanded) {
    _expanded.value = expanded;

    if (onExpansionChanged != null)
      onExpansionChanged(expanded);
  }

  @override
  get isExpanded => _expanded;

  Timer _expansionTimer;
  _startExpansionTimer() async {
    _expansionTimer = Timer(Duration(milliseconds: 400), _expansionCallback);
  }

  _stopExpansionTimer() async {
    if (_expansionTimer.isActive) {
      _expansionTimer.cancel();
    }
  }

  _expansionCallback() {
    expand();
  }
}