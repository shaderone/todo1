// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(MyApp());
}

var uuid = Uuid();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TextEditingController inputController = TextEditingController();
  //to store new tasks
  List<Todo> tasks = [];
  //to track whether the text is in create or edit mode
  bool isEditing = false;
  // to store the index of the task currently in edit mode
  int editingIndex = -1;

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
                    Builder(
                      builder: (context) {
                        return FilledButton.icon(
                          onPressed: () {
                            //capitalize the first letter
                            String taskValue =
                                inputController.text
                                    .trim()[0]
                                    .toUpperCase() +
                                inputController.text.trim().substring(
                                  1,
                                );
                            if (taskValue.isEmpty) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Task cannot be empty!",
                                  ),
                                ),
                              );
                              return;
                            } else {
                              setState(() {
                                isEditing
                                    ? tasks[editingIndex].text =
                                        taskValue
                                    : tasks.add(
                                      Todo(
                                        id: uuid.v4(),
                                        text: taskValue,
                                        isCompleted: false,
                                      ),
                                    );

                                isEditing = false;
                              });
                            }
                            FocusManager.instance.primaryFocus
                                ?.unfocus();
                            inputController.clear();
                          },
                          label: Icon(Icons.check),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
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
                          Todo task = tasks[index];
                          return ListTile(
                            leading: Container(
                              constraints: BoxConstraints.tightFor(
                                width: 20,
                                height: 24,
                              ),
                              child: Checkbox(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                value:
                                    task.isCompleted, //make it dynamic
                                onChanged: (value) {
                                  setState(() {
                                    task.isCompleted = value!;
                                  });
                                },
                              ),
                            ),
                            title: Text(
                              task.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  task.isCompleted
                                      ? TextStyle(
                                        decoration:
                                            TextDecoration
                                                .lineThrough,
                                        color: Colors.grey,
                                      )
                                      : null,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton.outlined(
                                  onPressed: () {
                                    setState(() {
                                      isEditing = true;
                                      editingIndex = index;
                                      inputController.text =
                                          task.text;
                                    });
                                  },
                                  icon: Icon(Icons.edit),
                                ),
                                IconButton.outlined(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text(
                                            "Delete ${task.text}?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(
                                                  context,
                                                ).pop();
                                              },
                                              child: Text("No"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  tasks.removeWhere(
                                                    (Todo todo) =>
                                                        todo.id ==
                                                        task.id,
                                                  );
                                                });
                                                Navigator.of(
                                                  context,
                                                ).pop();
                                              },
                                              child: Text("Yes"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  icon: Icon(Icons.delete),
                                ),
                              ],
                            ),
                            contentPadding: EdgeInsets.zero,
                            minLeadingWidth: 0,
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

class Todo {
  String id;
  bool isCompleted;
  String text;

  Todo({
    required this.id,
    required this.isCompleted,
    required this.text,
  });
}
