import 'package:flutter/material.dart';
import 'package:flutter_multi_grid_reorderables/flutter_multi_grid_reorderables.dart';
import 'package:flutter_multi_grid_reorderables/group.dart';


void main() {
  runApp(SizedBox.fromSize(size: const Size(100, 1000), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Blocks',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FlutterMultiGridReorderable<String, String>(
        data: [ Group<String, String>(
            "Group A", 
            [
              "1",
              "2",
              "3",
              "4",
              "5"
            ]
          ),
          Group<String, String>(
            "Gorup B", 
            [
              "6",
              "7",
              "8",
              "9",
              "10"
            ]
          ),
        ],
        groupTitleBuilder: (groupData) => Text(groupData),
        groupButtonBuilder: (groupData) => TextButton(
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                ),
                onPressed: () { },
                child: const Icon(Icons.add),
              ),
        blockBuilder: (str) => Text(str),
      ),
    );
  }
}
