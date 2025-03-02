import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'models/todo_model.dart';

void main() {
  runApp(MyApp());
}

var uuid = Uuid();

enum TaskMode { create, edit }

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
  //bool isEditing = false; // * change it to enum
  TaskMode taskMode = TaskMode.create;
  // to store the index of the task currently in edit mode
  int editingIndex = -1;
  bool canPop = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PopScope(
        // * canPop decides whether the back button should work as it is expected.
        canPop: canPop,
        // * Before the app exits, onPopInvokedWithResult runs. It tells whether the app actually popped or not via didPop:
        onPopInvokedWithResult: (didPop, result) {
          // * if didPop = true, the app already exited — no need to do anything.
          // * if didPop = false, app did not exit (most likely because keyboard was open).
          // * In that case, first remove focus (hide keyboard).
          FocusScope.of(context).unfocus();
          // * After hiding keyboard, set canPop = true to allow the app to exit on the next back press.
          if (!didPop) {
            setState(() {
              canPop = true;
            });
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text("TODOBAR.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            centerTitle: true,
            toolbarHeight: 75,
            backgroundColor: Colors.black,
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // ? input
                      Flexible(
                        child: TextField(
                          controller: inputController,
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 3)),
                            hintText: "Enter a task",
                          ),
                          keyboardType: TextInputType.multiline,
                          //maxLines: 3,
                        ),
                      ),
                      SizedBox(width: 10),
                      // ? action button
                      Builder(
                        builder: (context) {
                          return FilledButton.icon(
                            onPressed: manageTodo,
                            label: taskMode == TaskMode.edit ? Text("Update") : Text("add"),
                            style: FilledButton.styleFrom(backgroundColor: Colors.black),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  tasks.isEmpty
                      ? Text("You have no Todos!")
                      // ? todo items
                      : Expanded(
                        child: ListView.builder(
                          itemCount: tasks.length,
                          physics: BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            Todo task = tasks[index];
                            return ListTile(
                              leading: Container(
                                constraints: BoxConstraints.tightFor(width: 20, height: 24),
                                child: Checkbox(
                                  //materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  value: task.isCompleted, //make it dynamic
                                  onChanged:
                                      (value) => setState(() {
                                        task.isCompleted = value!;
                                      }),
                                ),
                              ),
                              title: Text(
                                task.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    task.isCompleted
                                        ? TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
                                        : null,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton.outlined(
                                    onPressed: () => onEdit(index: index, todo: task),
                                    icon:
                                        taskMode == TaskMode.edit && task.id == tasks[editingIndex].id
                                            ? Icon(Icons.close, color: Colors.red)
                                            : Icon(Icons.edit),
                                  ),
                                  IconButton.outlined(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: Text("Delete ${task.text}?", softWrap: true),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text("No"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    tasks.removeWhere((Todo todo) => todo.id == task.id);
                                                  });
                                                  Navigator.of(context).pop();
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
      ),
    );
  }

  // controls adding and updating todo
  void manageTodo() {
    if (inputController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Task cannot be empty!")));
      return;
    } else {
      //capitalize the first letter
      String taskValue = inputController.text.trim();
      if (taskValue.isNotEmpty) {
        taskValue = taskValue[0].toUpperCase() + taskValue.substring(1);
      }

      setState(() {
        if (taskMode == TaskMode.edit) {
          //if its editing mode, update the value in the list to the new value
          tasks[editingIndex].text = taskValue;
          tasks[editingIndex].isCompleted = false;
        }
        //if its create mode, add the value in the list to the as new todo
        else {
          tasks.add(Todo(id: uuid.v4(), text: taskValue, isCompleted: false));
        }
        // reset mode back to default
        taskMode = TaskMode.create;
      });
    }
    // ? To hide keyboard after create/edit
    //FocusManager.instance.primaryFocus?.unfocus();
    inputController.clear();
  }

  void onEdit({required int index, required Todo todo}) {
    setState(() {
      taskMode = taskMode == TaskMode.create ? TaskMode.edit : TaskMode.create;
      editingIndex = index;
      inputController.text = todo.text;
    });
    if (taskMode == TaskMode.create) {
      inputController.clear();
    }
  }
} // end of Myapp
