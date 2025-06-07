import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'task_service.dart';
import 'task.dart';

Future<void> main() async {
  // CRUCIAL: Ensures that Flutter's engine is ready before you run any other code.
  WidgetsFlutterBinding.ensureInitialized();

  // CRUCIAL: Initializes the Hive database in your app's local storage.
  await Hive.initFlutter();
  // CRUCIAL: Registers the 'TaskAdapter'. This is a piece of code, generated
  // by a command, that tells Hive how to save and load your 'Task' objects.
  // This line will show an error until you run the build_runner command.
  Hive.registerAdapter(TaskAdapter());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // A simplified, yet effective theme setup.
    final baseTheme = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5AAAFF), // Primary blue
      brightness: Brightness.dark,
      secondary: const Color(0xFFCC6600), // Accent orange/redwood
      background: const Color(0xFF1E1E1E),
      surface: const Color(0xFF2C2C2C),
    );

    final finalTheme = baseTheme.copyWith(
      colorScheme: colorScheme,
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: colorScheme.onPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        color: colorScheme.surface,
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        backgroundColor: colorScheme.background,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.secondary,
      ),
    );

    return MaterialApp(
      title: 'Life Tracker',
      theme: finalTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _addTaskFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // CRUCIAL: We use `context.read` here because this is a one-time call
      // inside initState to fetch initial data.
      final taskService = context.read<TaskService>();
      taskService.openTaskBox().then((_) {
        taskService.fetchTasks().catchError((error) {
          // FIX: Check if the widget is still mounted before using its context.
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load initial tasks: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        });
      });
    });
  }

  Color _getColorForProgress(double progress, BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final theme = Theme.of(context);
    return Color.lerp(
      theme.colorScheme.errorContainer.withOpacity(0.5),
      theme.colorScheme.primary,
      clampedProgress,
    )!;
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final taskService = context.read<TaskService>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Task'),
        content: Form(
          key: _addTaskFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Task Title', hintText: 'Enter task name', prefixIcon: Icon(Icons.title)),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter a task title';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: targetController,
                decoration: const InputDecoration(labelText: 'Target Value', hintText: 'e.g., 100', prefixIcon: Icon(Icons.track_changes)),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a target value';
                  final number = double.tryParse(value);
                  if (number == null) return 'Please enter a valid number';
                  if (number <= 0) return 'Target must be greater than 0';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_addTaskFormKey.currentState!.validate()) {
                final title = titleController.text.trim();
                final target = double.parse(targetController.text);
                Navigator.pop(dialogContext); // Close dialog first

                // Use a variable for the mounted check to avoid a linting warning
                final isMounted = mounted;
                try {
                  await taskService.addTask(title, target);
                  // FIX: Check if the widget is still mounted before showing SnackBar.
                  if (!isMounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Task "$title" added'), backgroundColor: Colors.green[700]),
                  );
                } catch (e) {
                  // FIX: Check if the widget is still mounted before showing SnackBar.
                  if (!isMounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add task: $e'), backgroundColor: Theme.of(context).colorScheme.error),
                  );
                }
              }
            },
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  void _showUpdateProgressDialog(BuildContext context, Task task) {
    double currentProgressPercent = task.progressPercent;
    final taskService = context.read<TaskService>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Update Progress: ${task.title}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Current Progress: ${currentProgressPercent.toStringAsFixed(0)}%"),
                Slider(
                  value: currentProgressPercent,
                  min: 0.0,
                  max: 100.0,
                  divisions: 100,
                  label: "${currentProgressPercent.toStringAsFixed(0)}%",
                  onChanged: (newValue) {
                    setStateDialog(() {
                      currentProgressPercent = newValue;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final newProgressFraction = (currentProgressPercent / 100.0).clamp(0.0, 1.0);
                  final newCurrentValue = task.target * newProgressFraction;

                  // Use a variable for the mounted check
                  final isMounted = mounted;
                  try {
                    await taskService.updateTask(task.copyWith(
                      progress: newProgressFraction,
                      current: newCurrentValue,
                      isCompleted: newProgressFraction >= 1.0,
                    ));
                    // FIX: Check if the widget is still mounted before showing SnackBar.
                    if (!isMounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Progress for "${task.title}" updated'), backgroundColor: Colors.green[700]),
                    );
                  } catch (e) {
                    // FIX: Check if the widget is still mounted before showing SnackBar.
                    if (!isMounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update progress: $e'), backgroundColor: Theme.of(context).colorScheme.error),
                    );
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // CRUCIAL: We use `context.watch` here in the build method. This tells Flutter
    // to rebuild this widget whenever the data in TaskService changes.
    final taskService = context.watch<TaskService>();
    final theme = Theme.of(context);

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Text('Control Center', style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onPrimary)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Life Tracker'),
        actions: [
          if (taskService.isLoading && taskService.tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Tasks',
              onPressed: taskService.isLoading ? null : taskService.fetchTasks,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: taskService.fetchTasks,
        child: Column(
          children: [
            if (taskService.errorMessage != null)
              Container(
                color: theme.colorScheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.onError),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(taskService.errorMessage!, style: TextStyle(color: theme.colorScheme.onError), overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.colorScheme.onError, size: 20),
                      onPressed: () => context.read<TaskService>().setError(null),
                    )
                  ],
                ),
              ),
            Expanded(
              child: (taskService.isLoading && taskService.tasks.isEmpty)
                  ? const Center(child: CircularProgressIndicator())
                  : (taskService.tasks.isEmpty)
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.list_alt_rounded, size: 60, color: theme.colorScheme.secondary),
                    const SizedBox(height: 16),
                    Text("No tasks yet!", style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text("Tap the '+' button to add your first task.", style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: taskService.tasks.length,
                itemBuilder: (context, index) {
                  final task = taskService.tasks[index];
                  return Dismissible(
                    key: ValueKey(task.id),
                    background: Container(
                      color: Colors.green.shade600,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      color: theme.colorScheme.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Delete', style: TextStyle(color: theme.colorScheme.onError, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Icon(Icons.delete_outline, color: theme.colorScheme.onError),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Task?'),
                            content: Text('Are you sure you want to delete "${task.title}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: theme.colorScheme.error))),
                            ],
                          ),
                        ) ?? false;
                      }
                      return true;
                    },
                    onDismissed: (direction) async {
                      final service = context.read<TaskService>();
                      if (direction == DismissDirection.endToStart) {
                        await service.deleteTask(task.id);
                      } else {
                        final newStatus = !task.isCompleted;
                        await service.updateTask(task.copyWith(
                          isCompleted: newStatus,
                          progress: newStatus ? 1.0 : 0.0,
                          current: newStatus ? task.target : 0.0,
                        ));
                      }
                    },
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        title: Text(task.title, style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none, color: task.isCompleted ? Colors.grey : null, fontWeight: FontWeight.w500)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: LinearProgressIndicator(
                            value: task.progress.clamp(0.0, 1.0),
                            backgroundColor: theme.colorScheme.surface.withAlpha(150),
                            valueColor: AlwaysStoppedAnimation<Color>(_getColorForProgress(task.progress, context)),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${task.progressPercent.toStringAsFixed(0)}%', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Icon(task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: task.isCompleted ? Colors.green.shade600 : theme.colorScheme.secondary),
                          ],
                        ),
                        onTap: () => _showUpdateProgressDialog(context, task),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        tooltip: 'Add New Task',
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}
