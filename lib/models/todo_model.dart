class Todo {
  String id;
  bool isDone;
  String task;

  Todo({required this.id, required this.isDone, required this.task});

  // ? converts model to map/json type
  Map<String, dynamic> convertModeltoMap() {
    return {'id': id, 'task': task, 'is_done': isDone};
  }

  // ? converts map/json to model
  factory Todo.fromMapToModel(Map<String, dynamic> map) {
    return Todo(id: map['id'], isDone: map['is_done'], task: map['task']);
  }
}
