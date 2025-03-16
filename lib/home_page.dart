import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import 'models/todo_model.dart';

var uuid = Uuid();

enum TaskMode { create, edit }

class HomePage extends StatefulWidget {
  // ignore: constant_identifier_names
  static const TODOLIST = 'todos';
  final Isar isar;
  const HomePage(this.isar, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController inputController = TextEditingController();
  //to store new tasks
  List<Todo> tasks = []; //? list for the ui
  //to track whether the text is in create or edit mode
  TaskMode taskMode = TaskMode.create;
  // to store the index of the task currently in edit mode
  int editingIndex = -1;
  bool canPop = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() => readTodos()); // to prevent setState() from interfering with initState()
  }

  Future<void> readTodos() async {
    // * the isar.todos is the name given by the isar_generator
    tasks = await widget.isar.todos.where().findAll();
  }

  @override
  Widget build(BuildContext context) {
    //print("build called");
    return PopScope(
      // * canPop decides whether the back button should work as it is expected.
      canPop: canPop,
      // * Before the app exits, onPopInvokedWithResult runs. It tells whether the app actually popped or not via didPop:
      onPopInvokedWithResult: (didPop, result) {
        // * if didPop = true, the app already exited — no need to do anything.
        // * if didPop = false, app did not exit (most likely because keyboard was open).
        if (!didPop) {
          // * In that case, first remove focus (hide keyboard).
          FocusScope.of(context).unfocus();
          // * After hiding keyboard, set canPop = true to allow the app to exit on the next back press.
          setState(() {
            canPop = true;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("TODOBAR.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          toolbarHeight: 75,
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              onPressed: () async => await widget.isar.writeTxn(() async => await widget.isar.clear()),
              icon: Icon(Icons.clean_hands_rounded),
            ),
          ],
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
                Expanded(
                  child: StreamBuilder(
                    stream: widget.isar.todos.watchLazy(fireImmediately: true),
                    builder: (context, _) {
                      return FutureBuilder<List<Todo>>(
                        future: widget.isar.todos.where().findAll(),
                        builder: (context, futureSnapshot) {
                          if (futureSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
                            return Text("You have no Todos!");
                          }
                          return ListView.builder(
                            itemCount: futureSnapshot.data!.length,
                            physics: BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              Todo todoItem = futureSnapshot.data![index];
                              return ListTile(
                                leading: Container(
                                  constraints: BoxConstraints.tightFor(width: 20, height: 24),
                                  child: Checkbox(
                                    visualDensity: VisualDensity.compact,
                                    value: todoItem.isDone,
                                    onChanged: (value) {
                                      todoItem.isDone = value!;
                                      saveData(todoItem);
                                    },
                                  ),
                                ),
                                title: Text(
                                  todoItem.task,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      todoItem.isDone
                                          ? TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
                                          : null,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton.outlined(
                                      onPressed: () => onEdit(index: index, todo: todoItem),
                                      icon:
                                          taskMode == TaskMode.edit && todoItem.id == tasks[editingIndex].id
                                              ? Icon(Icons.close, color: Colors.red)
                                              : Icon(Icons.edit),
                                    ),
                                    IconButton.outlined(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text("Delete ${todoItem.task}?", softWrap: true),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text("No"),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    final navigator = Navigator.of(context);
                                                    await widget.isar.writeTxn(() async {
                                                      await widget.isar.todos.delete(todoItem.isarId); // delete
                                                    });
                                                    navigator.pop();
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
                          );
                        },
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

  //* controls adding and updating todo
  Future<void> manageTodo() async {
    if (inputController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Task cannot be empty!")));
      return;
    } else {
      //capitalize the first letter and get the task value
      String taskValue = inputController.text.trim();
      if (taskValue.isNotEmpty) {
        taskValue = taskValue[0].toUpperCase() + taskValue.substring(1);
      }

      //if its editing mode, update the value in the list to the new value
      if (taskMode == TaskMode.edit) {
        tasks[editingIndex].task = taskValue;
        tasks[editingIndex].isDone = false; // reset the completion status
        saveData(tasks[editingIndex]);
      } else {
        saveData(Todo(id: uuid.v4(), task: taskValue, isDone: false));
      }

      setState(() {
        // reset mode back to default
        taskMode = TaskMode.create;
      });
    }
    // ? To hide keyboard after create/edit
    //FocusManager.instance.primaryFocus?.unfocus();
    inputController.clear();
  }

  Future<void> saveData(Todo todo) async {
    await widget.isar.writeTxn(() async {
      await widget.isar.todos.put(todo);
    });
  }

  void onEdit({required int index, required Todo todo}) {
    readTodos();
    setState(() {
      taskMode = TaskMode.edit;
      editingIndex = index;
      inputController.text = todo.task;
    });
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }
} // end of Myapp
