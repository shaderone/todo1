import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models/todo_model.dart';

var uuid = Uuid();

enum TaskMode { create, edit }

class HomePage extends StatefulWidget {
  // ignore: constant_identifier_names
  static const TODOLIST = 'todos';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    readTodos();
  }

  Future<void> readTodos() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    //prefs.clear();
    List<String>? todos = prefs.getStringList(HomePage.TODOLIST);
    if (todos == null) {
      print("nothing");
      tasks = [];
      return;
    } else {
      // ? traverse through the map of strings
      // ? take each map/json and convert it to dart object then store it in a list
      //List<Map<String, dynamic>> todoMap = todos.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      setState(() {
        tasks = todos.map((todoItem) => Todo.fromMapToModel(jsonDecode(todoItem))).toList();
      });
    }
  }

  TextEditingController inputController = TextEditingController();
  //to store new tasks
  List<Todo> tasks = []; //? list for the ui
  //to track whether the text is in create or edit mode
  TaskMode taskMode = TaskMode.create;
  // to store the index of the task currently in edit mode
  int editingIndex = -1;
  bool canPop = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
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
          //centerTitle: true,
          toolbarHeight: 75,
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              onPressed: () async {
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.clear();
                setState(() {
                  tasks.clear();
                });
              },
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
                tasks.isEmpty
                    ? Text("You have no Todos!")
                    // ? todo items
                    : Expanded(
                      child: ListView.builder(
                        //itemCount: tasks.length,
                        itemCount: tasks.length,
                        physics: BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          //Todo task = tasks[index];
                          Todo todoItem = tasks[index];
                          return ListTile(
                            leading: Container(
                              constraints: BoxConstraints.tightFor(width: 20, height: 24),
                              child: Checkbox(
                                //materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                value: todoItem.isDone, //make it dynamic
                                onChanged:
                                    (value) => setState(() {
                                      todoItem.isDone = value!;
                                    }),
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
                                              onPressed: () {
                                                setState(() {
                                                  tasks.removeWhere((Todo todo) => todo.id == todoItem.id);
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

      setState(() {
        //if its editing mode, update the value in the list to the new value
        if (taskMode == TaskMode.edit) {
          tasks[editingIndex].task = taskValue;
          tasks[editingIndex].isDone = false; // reset the completion status
        }
        //if its create mode, add the value in the list to the as new todo
        else {
          // ? first add the todo to a local List
          tasks.add(Todo(id: uuid.v4(), task: taskValue, isDone: false));
          // ? also save the data to localstorage : sharedpreference
          saveData();
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
      inputController.text = todo.task;
    });
    if (taskMode == TaskMode.create) {
      inputController.clear();
    }
  }

  Future<void> saveData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // ? convert the Todo objects in the tasks[] to a list of json-encoded maps.
    // because in sharedpreference we store multiple data in the form of a stringified-field-list. (or simply json like format)
    //first we need to convert all the todoItems to a map type because that the most similar dataype to json syntax (key-value). it is also a natively supported datatype by json
    List<String> todoList = tasks.map((todoItem) => jsonEncode(todoItem.convertModeltoMap())).toList();
    // ? Then store it in the localstorage
    await prefs.setStringList(HomePage.TODOLIST, todoList);
  }
} // end of Myapp
