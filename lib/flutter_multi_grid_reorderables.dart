import 'package:flutter/material.dart';
import 'group.dart';

class FlutterMultiGridReorderable<G, T> extends StatefulWidget {
  final List<Group<G, T>> data;
  final Widget Function(T item) blockBuilder;
  final Widget Function(G groupData) groupTitleBuilder;
  final Widget Function(G groupData) groupButtonBuilder;

  const FlutterMultiGridReorderable({
    super.key, 
    required this.data,
    required this.blockBuilder,
    required this.groupTitleBuilder,
    required this.groupButtonBuilder
  });

  @override
  _FlutterMultiGridReorderableState<G, T> createState() => _FlutterMultiGridReorderableState<G, T>();
}

class _FlutterMultiGridReorderableState<G, T> extends State<FlutterMultiGridReorderable<G, T>> {
  static const numberOfColumns = 5;

  late List<_GroupInternal<G, T>> groups;

  @override
  void initState() {
    super.initState();
    groups = List<_GroupInternal<G, T>>.generate(
      widget.data.length,
      (index) => _GroupInternal<G, T>(
        widget.data[index].groupData,
        List<_BlockInternal<T>>.generate(
          widget.data[index].children.length,
          (blockIndex) => _BlockInternal<T>(widget.data[index].children[blockIndex]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reorderable Grid'),
      ),
      body: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, groupIndex) {
          final group = groups[groupIndex];

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
                    _BlockInternal<T>? block;
                    bool isAddButton = false;
                    if (index == group.blocks.length) {
                      isAddButton = true;
                    } else {
                      block = group.blocks[index];
                    }

                    return _buildDragTarget(context, group, block, isAddButton, index);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _animateBlocksRearrangement() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        for (final group in groups) {
          for (var i = 0; i < group.blocks.length; i++) {
            group.blocks[i].data = group.blocks[i].data;
          }
        }
      });
    });
  }

  Widget _buildDragTarget(BuildContext context, _GroupInternal<G, T> group, _BlockInternal<T>? block, bool isAddButton, int index) {
    if (isAddButton) {
      return DragTarget<_BlockInternal<T>>(
        onWillAccept: (value) {
          return true;
        },
        onAccept: (value) {
          setState(() {
            final targetGroup = group;
            final sourceGroup = groups.firstWhere(
              (group) => group.blocks.contains(value),
            );
            sourceGroup.blocks.remove(value);
            targetGroup.blocks.add(value);
            value.isBeingDragged = false;
            value.isTargeted = false;
            value.showDropIndicator = false;
          });
        },
        builder: (context, candidateData, rejectedData) {
          return _GridItemWidget(
            isBeingDragged: false, 
            isHoveredOn: candidateData.isNotEmpty, 
            child:  SizedBox.expand(
              child: widget.groupButtonBuilder(group.groupData),
            ),
          );

        },
      );
    } else {
      return DragTarget<_BlockInternal<T>>(
        onAccept: (value) {
          setState(() {
            final targetGroup = group;
            final sourceGroup = groups.firstWhere(
              (group) => group.blocks.contains(value),
            );
            
            final sourceIndex = sourceGroup.blocks.indexOf(value);
            final targetIndex = targetGroup.blocks.indexOf(block!);

            var insertIndex = sourceGroup == targetGroup && sourceIndex < targetIndex
              ?  targetIndex - 1
              : targetIndex;

            sourceGroup.blocks.remove(value);
            targetGroup.blocks.insert(insertIndex, value);
            
            
            if (sourceGroup != targetGroup || sourceIndex != targetIndex) {
              _animateBlocksRearrangement();
            }
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

  Widget _buildBlockWidget(BuildContext context, _BlockInternal<T> block, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final blockSize = constraints.maxWidth;
        return LongPressDraggable<_BlockInternal<T>>(
          data: block,
          feedback: Material(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
              ),
              padding: const EdgeInsets.all(8.0),
              width: blockSize,
              height: blockSize,
              child: Center(
                child: widget.blockBuilder(block.data as T),
              ),
            ),
          ),
          onDragStarted: () {
            setState(() {
              block.isBeingDragged = true;
            });
          },
          onDragEnd: (details) {
            setState(() {
              block.isBeingDragged = false;
              block.isTargeted = false;
              block.showDropIndicator = false;
            });
          },
          onDraggableCanceled: (velocity, offset) {
            setState(() {
              block.isBeingDragged = false;
            });
          },
          onDragUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset localOffset = box.globalToLocal(details.globalPosition);
            final double indicatorWidth = box.size.width * 0.5;
            final bool isLeft = localOffset.dx < indicatorWidth;
            final bool isRight = localOffset.dx > box.size.width - indicatorWidth;
            final bool isTop = localOffset.dy < indicatorWidth;
            final bool isBottom = localOffset.dy > box.size.height - indicatorWidth;

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
        color: isBeingDragged ? Colors.grey.withOpacity(0.7) : null,
        boxShadow: isHoveredOn
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.9),
                  blurRadius: 8.0,
                  spreadRadius: 4.0,
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: child
      ),
    );
  }
}

class _BlockInternal<T> {
  T? data;
  bool isBeingDragged;
  bool isTargeted;
  bool showDropIndicator;

  _BlockInternal(this.data)
      : isBeingDragged = false,
        isTargeted = false,
        showDropIndicator = false;
}

class _GroupInternal<G, T> {
  List<_BlockInternal<T>> blocks;
  G groupData;

  _GroupInternal(this.groupData, this.blocks);
}
