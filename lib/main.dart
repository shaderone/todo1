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
                          tasks.add(inputController.text);
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
                tasks.isEmpty
                    ? Text("You have no Todos!")
                    : Expanded(
                      child: ListView.builder(
                        itemCount: tasks.length,
                        physics: BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          //print("index = $index");
                          String task = tasks[index];
                          return ListTile(
                            leading: Container(
                              constraints: BoxConstraints.tightFor(
                                width: 20,
                                height: 24,
                              ),
                              child: Checkbox(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                value: true,
                                onChanged: (value) {},
                              ),
                            ),
                            title: Text(
                              //"Buy milk from the whatshop",
                              task,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit),
                                Icon(Icons.delete),
                              ],
                            ),
                            contentPadding: EdgeInsets.zero,
                            minLeadingWidth: 0,

                            //visualDensity: VisualDensity.compact,
                          );
                        },
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
