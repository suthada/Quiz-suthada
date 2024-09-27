import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:quiz_suthada/screen/signin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SigninScreen(),
        '/todo': (context) => const TodoApp(),
      },
    );
  }
}

class TodoApp extends StatefulWidget {
  const TodoApp({
    super.key,
  });

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late TextEditingController _nameController;
  late TextEditingController _detailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _detailController = TextEditingController();
  }

  void _showAddEditDialog(BuildContext context, {DocumentSnapshot? task}) {
    bool isEditing = task != null;
    _nameController.text = isEditing ? task['name'] : '';
    _detailController.text = isEditing ? task['detail'] : '';
    bool status = isEditing ? task['status'] : false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? "Edit task" : "Add new task"),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Task name",
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _detailController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Task detail",
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Task status:"),
                        ChoiceChip(
                          label: Text(status ? "Completed" : "Pending"),
                          selected: status,
                          onSelected: (selected) {
                            setState(() {
                              status = selected;
                            });
                          },
                          selectedColor: Colors.green,
                          avatar: Icon(
                            status ? Icons.check_circle : Icons.pending,
                            color: status ? Colors.white : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    final data = {
                      'name': _nameController.text,
                      'detail': _detailController.text,
                      'status': status,
                    };

                    if (isEditing) {
                      FirebaseFirestore.instance
                          .collection("tasks")
                          .doc(task.id)
                          .update(data);
                    } else {
                      FirebaseFirestore.instance.collection("tasks").add(data);
                    }

                    _nameController.clear();
                    _detailController.clear();
                    Navigator.pop(context);
                  },
                  child: Text(isEditing ? "Update" : "Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteTask(String taskId) {
    FirebaseFirestore.instance.collection("tasks").doc(taskId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Todo"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Navigate to SigninScreen
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("tasks").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No tasks"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var task = snapshot.data!.docs[index];
              bool isCompleted = task['status'];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isCompleted ? Colors.green : Colors.orange,
                        child: Icon(
                          isCompleted ? Icons.check : Icons.pending,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        task['name'],
                        style: TextStyle(
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(task['detail']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _showAddEditDialog(context, task: task),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteTask(task.id),
                          ),
                        ],
                      ),
                      onTap: () {
                        FirebaseFirestore.instance
                            .collection("tasks")
                            .doc(task.id)
                            .update({'status': !isCompleted});
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "Click to ${isCompleted ? 'mark as pending' : 'complete'}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
