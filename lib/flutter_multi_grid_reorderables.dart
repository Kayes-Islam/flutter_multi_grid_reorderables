import 'package:flutter/material.dart';
import 'group.dart';

class FlutterMultiGridReorderable<G, T> extends StatefulWidget {
  final List<Group<G, T>> data;
  final Widget Function(T item) blockBuilder;
  final Widget Function(Group<G,T>) groupTitleBuilder;
  final Widget Function(Group<G,T>) groupButtonBuilder;
  final void Function(T item)? onDragStarted;
  final void Function(T item)? onDragEnd;

  final List<_GroupInternal<G, T>> _groups;

  FlutterMultiGridReorderable(
      {super.key,
      required this.data,
      required this.blockBuilder,
      required this.groupTitleBuilder,
      required this.groupButtonBuilder,
      this.onDragStarted,
      this.onDragEnd,
      }): _groups = List<_GroupInternal<G, T>>.generate(
              data.length,
              (index) => _GroupInternal<G, T>(
                data[index],
                List<_ItemDataImplementation<T>>.generate(
                  data[index].children.length,
                  (blockIndex) =>
                      _ItemDataImplementation<T>(data[index].children[blockIndex]),
                ),
              ),
            );

  @override
  _FlutterMultiGridReorderableState<G, T> createState() =>
      _FlutterMultiGridReorderableState<G, T>();
}

class _FlutterMultiGridReorderableState<G, T>
    extends State<FlutterMultiGridReorderable<G, T>> {
  static const numberOfColumns = 5;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: widget._groups.length,
        itemBuilder: (context, groupIndex) {
          final group = widget._groups[groupIndex];

          return Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.groupTitleBuilder(group.groupData),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: group.blocks.length + 1,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: numberOfColumns,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemBuilder: (context, index) {
                    _ItemDataImplementation<T>? block;
                    bool isAddButton = false;
                    if (index == group.blocks.length) {
                      isAddButton = true;
                    } else {
                      block = group.blocks[index];
                    }

                    return _buildDragTarget(
                        context, group, block, isAddButton, index);
                  },
                ),
              ],
            ),
          );
        },
      );
  }

  void _animateBlocksRearrangement() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        for (final group in widget._groups) {
          for (var i = 0; i < group.blocks.length; i++) {
            group.blocks[i].data = group.blocks[i].data;
          }
        }
      });
    });
  }

  Widget _buildDragTarget(BuildContext context, _GroupInternal<G, T> group,
      _ItemDataImplementation<T>? block, bool isAddButton, int index) {
    if (isAddButton) {
      return DragTarget<_ItemDataImplementation<T>>(
        onWillAccept: (value) {
          return true;
        },
        onAccept: (value) {
          setState(() {
            final targetGroup = group.groupData;
            final sourceGroup = widget.data.firstWhere(
              (group) => group.children.contains(value.data),
            );

            value.isBeingDragged = false;
            value.isTargeted = false;
            value.showDropIndicator = false;

            sourceGroup.children.remove(value.data);
            targetGroup.children.add(value.data!);
          });
        },
        builder: (context, candidateData, rejectedData) {
          return _GridItemWidget(
            isBeingDragged: false,
            isHoveredOn: candidateData.isNotEmpty,
            child: SizedBox.expand(
              child: widget.groupButtonBuilder(group.groupData),
            ),
          );
        },
      );
    } else {
      return DragTarget<_ItemDataImplementation<T>>(
        onAccept: (value) {
          setState(() {
            final targetGroup = group.groupData;
            final sourceGroup = widget.data.firstWhere(
              (group) => group.children.contains(value.data),
            );

            final sourceIndex = sourceGroup.children.indexOf(value.data!);
            final targetIndex = targetGroup.children.indexOf(block!.data!);

            var insertIndex =
                sourceGroup == targetGroup && sourceIndex < targetIndex
                    ? targetIndex - 1
                    : targetIndex;

            sourceGroup.children.remove(value.data);
            targetGroup.children.insert(insertIndex, value.data!);

            // sourceGroup.blocks.remove(value);
            // targetGroup.blocks.insert(insertIndex, value);

            // if (sourceGroup != targetGroup || sourceIndex != targetIndex) {
            //   _animateBlocksRearrangement();
            // }
          });

          value.isBeingDragged = false;
          value.isTargeted = false;
          block!.isTargeted = false;
          value.showDropIndicator = false;
        },
        onWillAccept: (value) {
          setState(() {
            block!.isTargeted = true;
          });
          return true;
        },
        onLeave: (value) {
          setState(() {
            block!.isTargeted = false;
          });
        },
        builder: (context, candidateData, rejectedData) {
          return _buildBlockWidget(context, block!, index);
        },
      );
    }
  }

  Widget _buildBlockWidget(
      BuildContext context, _ItemDataImplementation<T> block, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final blockSize = constraints.maxWidth;
        return LongPressDraggable<_ItemDataImplementation<T>>(
          data: block,
          feedback: Opacity(
            opacity: 0.8,
            child: Material(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                width: blockSize,
                height: blockSize,
                child: Center(
                  child: widget.blockBuilder(block.data as T),
                ),
              ),
            ),
          ),
          onDragStarted: () {
            setState(() {
              block.isBeingDragged = true;
            });

            
            if(widget.onDragStarted != null){
              widget.onDragStarted!(block.data!);
            }
          },
          onDragEnd: (details) {
            setState(() {
              block.isBeingDragged = false;
              block.isTargeted = false;
              block.showDropIndicator = false;
            });

            if(widget.onDragEnd != null){
              widget.onDragEnd!(block.data!);
            }
          },
          onDraggableCanceled: (velocity, offset) {
            setState(() {
              block.isBeingDragged = false;
            });
          },
          onDragUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset localOffset =
                box.globalToLocal(details.globalPosition);
            final double indicatorWidth = box.size.width * 0.5;
            final bool isLeft = localOffset.dx < indicatorWidth;
            final bool isRight =
                localOffset.dx > box.size.width - indicatorWidth;
            final bool isTop = localOffset.dy < indicatorWidth;
            final bool isBottom =
                localOffset.dy > box.size.height - indicatorWidth;

            setState(() {
              block.isTargeted = isLeft || isRight || isTop || isBottom;
              block.showDropIndicator = block.isTargeted;
            });
          },
          child: _GridItemWidget(
            isBeingDragged: block.isBeingDragged,
            isHoveredOn: block.isTargeted,
            child: Center(
              child: widget.blockBuilder(block.data as T),
            ),
          ),
        );
      },
    );
  }
}

class _GridItemWidget extends StatelessWidget {
  const _GridItemWidget({
    required this.isBeingDragged,
    required this.isHoveredOn,
    required this.child,
  });

  final Widget child;
  final bool isBeingDragged;
  final bool isHoveredOn;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isBeingDragged ? Colors.grey : null,
        boxShadow: isHoveredOn
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.9),
                  blurRadius: 8.0,
                  // spreadRadius: 4.0,
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.all(8.0),
      child: Center(child: child),
    );
  }
}

class _ItemDataImplementation<T> implements ItemData<T>{
  @override
  T? data;
  
  bool isBeingDragged;
  bool isTargeted;
  bool showDropIndicator;

  _ItemDataImplementation(this.data)
      : isBeingDragged = false,
        isTargeted = false,
        showDropIndicator = false;
}

abstract class ItemData<T>{
  T? get data;
}

class _GroupInternal<G, T> {
  List<_ItemDataImplementation<T>> blocks;
  Group<G,T> groupData;

  _GroupInternal(this.groupData, this.blocks);
}
