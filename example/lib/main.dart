import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_multi_grid_reorderables/flutter_multi_grid_reorderables.dart';
import 'package:flutter_multi_grid_reorderables/group.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final StreamController<bool> _isBeingDragged =
      StreamController<bool>.broadcast();

  final groupsData = [
    Group<String, String>(
        "Group A", List.generate(10, (index) => (index + 1).toString())),
    Group<String, String>(
        "Gorup B", List.generate(10, (index) => (index + 11).toString())),
    Group<String, String>(
        "Gorup C", List.generate(10, (index) => (index + 21).toString())),
    Group<String, String>(
        "Gorup D", List.generate(10, (index) => (index + 31).toString())),
    Group<String, String>(
        "Gorup E", List.generate(10, (index) => (index + 41).toString())),
    Group<String, String>(
        "Gorup F", List.generate(10, (index) => (index + 51).toString())),
    Group<String, String>(
        "Gorup G", List.generate(10, (index) => (index + 61).toString())),
    Group<String, String>(
        "Gorup H", List.generate(10, (index) => (index + 71).toString())),
    Group<String, String>(
        "Gorup I", List.generate(10, (index) => (index + 81).toString())),
    Group<String, String>(
        "Gorup J", List.generate(10, (index) => (index + 91).toString()))
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Blocks',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<bool>(
          stream: _isBeingDragged.stream,
          builder: (context, snapshot) {
            return Scaffold(
              appBar: AppBar(
                title: Text(snapshot.data == true
                    ? "Drag in progress"
                    : "Flutter Drag and Drop"),
                actions: [
                  DragTarget<ItemData<String>>(
                    onWillAccept: (value) {
                      return true;
                    },
                    onAccept: (value) {
                      setState(() {
                        for (var g in groupsData) {g.children.remove(value.data);}
                      });
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Icon(
                        Icons.delete,
                        color: candidateData.isNotEmpty
                            ? Colors.red
                            : Colors.white,
                        shadows: candidateData.isNotEmpty
                            ? [const Shadow(color: Colors.red, blurRadius: 4)]
                            : [],
                      );
                    },
                  )
                ],
              ),
              body: FlutterMultiGridReorderable<String, String>(
                data: groupsData,
                groupTitleBuilder: (groupData) => Text(groupData.data),
                groupButtonBuilder: (groupData) => TextButton(
                  style: ButtonStyle(
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.black),
                  ),
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
                blockBuilder: (str) => Text(str),
                onDragStarted: (str) => _isBeingDragged.add(true),
                onDragEnd: (str) => _isBeingDragged.add(false),
              ),
            );
          }),
    );
  }
}
