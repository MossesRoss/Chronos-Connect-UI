import 'package:flutter/material.dart';
import 'task.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final List<Task> _tasks = [
    Task(title: 'Morning Workout', progress: 0.3),
    Task(title: 'Read a Book', progress: 0.7, isCompleted: true),
    Task(title: 'Plan for the Day', progress: 0.9),
    Task(title: 'Learn Flutter Basics', progress: 0.5),
  ];
  void _showAddTaskDialog(BuildContext context) {
    TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Task Title'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    _tasks.add(Task(title: titleController.text));
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Color _getColorForProgress(double progress) {
    if (progress < 0.5) {
      // Red to Yellow
      return Color.lerp(Colors.red, Colors.yellow, progress / 0.5)!;
    } else {
      // Yellow to Green
      return Color.lerp(Colors.yellow, Colors.green, (progress - 0.5) / 0.5)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Tracker'),
      ),
      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Dismissible(
            key: Key(task.title), // Unique key for each task
            onDismissed: (direction) {
              final taskToRemove = task; // Capture the task before setState
              setState(() {
                if (direction == DismissDirection.endToStart) {
                  // Swipe right to left: Delete task
                  final indexToRemove = _tasks.indexOf(taskToRemove);
                  if (indexToRemove != -1) {
                    _tasks.removeAt(indexToRemove);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${taskToRemove.title} deleted')),
                    );
                  }
                } else if (direction == DismissDirection.startToEnd) {
                  // Swipe left to right: Mark as completed
                  taskToRemove.isCompleted = true;
                  final indexToRemove = _tasks.indexOf(taskToRemove);
                  if (indexToRemove != -1) {
                    _tasks.removeAt(indexToRemove);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${taskToRemove.title} marked as completed')),
                    );
                  }
                  // If _hideCompleted is true, the task will automatically be removed from the visible list on the next build.
                }
              });
            },
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20.0),
              child: const Icon(Icons.check, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              title: Text(task.title),
              subtitle: Text('Progress: ${(task.progress * 100).toStringAsFixed(0)}%'),
              tileColor: _getColorForProgress(task.progress),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTaskDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}