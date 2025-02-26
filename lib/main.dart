import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TextEditingController inputController = TextEditingController();
  String task = '';
  List<String> tasks = [];
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text("Todo App"),
          backgroundColor: Colors.blueAccent,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Flexible(
                      child: TextField(
                        controller: inputController,
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(),
                          hintText: "Enter a task",
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          task = inputController.text;
                        });
                      },
                      label: Icon(Icons.check),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text("You have no Todos!"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
