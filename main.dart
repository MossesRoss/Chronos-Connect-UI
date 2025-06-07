import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'task_service.dart';
import 'task.dart'; // Import the generated Hive adapter part file

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();


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
    // Define a custom color scheme inspired by NetSuite's dark bluish/redwood feel
    // These are example colors, you might want to fine-tune them
    final ColorScheme netSuiteColorScheme = ColorScheme(
      brightness: Brightness.dark, // Use dark brightness for the bluish feel
      primary: Color(0xFF5AAAFF), // A deep NetSuite blue
      onPrimary: Colors.white, // White text on primary
      primaryContainer: Color(0xFF004080), // Slightly lighter blue container
      onPrimaryContainer: Colors.white70, // Lighter text on container
      secondary: Color(0xFFCC6600), // A NetSuite-like orange/redwood accent
      onSecondary: Colors.white, // White text on secondary
      secondaryContainer: Color(0xFFE67300), // Lighter orange container
      onSecondaryContainer: Colors.white70, // Lighter text on container
      tertiary: Color(0xFF6699CC), // A lighter blue accent
      onTertiary: Colors.black87, // Dark text on tertiary
      tertiaryContainer: Color(0xFF80B3E6), // Lighter light blue
      onTertiaryContainer: Colors.black87, // Dark text on container
      error: Color(0xFFCF6679), // Standard dark theme error color
      onError: Colors.black, // Standard dark theme on error color
      errorContainer: Color(0xFFF2B8B5), // Standard dark theme error container
      onErrorContainer: Colors.black, // White text on background
      surface: Color(0xFF1E1E1E), // Dark surface color
      onSurface: Colors.white, // White text on surface
      surfaceContainerHighest: Color(0xFF424242), // Slightly lighter dark surface variant
      onSurfaceVariant: Colors.white70, // Lighter text on surface variant
      outline: Color(0xFF757575), // Outline color
      shadow: Colors.black, // Shadow color
      inverseSurface: Colors.white, // Inverse surface
      onInverseSurface: Colors.black, // On inverse surface
      inversePrimary: Color(0xFF6699CC), // Inverse primary
      surfaceTint: Color(0xFF003366), // Surface tint
    );


    final baseTheme = ThemeData(
      // Use the custom color scheme
      colorScheme: netSuiteColorScheme,
      useMaterial3: true, // Enable Material 3 design
      // Apply the font globally
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData(brightness: netSuiteColorScheme.brightness).textTheme),
      // Consistent input decoration using Material 3 style
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          // Adjusted border radius slightly for a sharper feel
          borderRadius: BorderRadius.circular(8.0), // Slightly less rounded
        ),
        filled: true,
        // Use surfaceVariant with opacity from the custom scheme
        fillColor: netSuiteColorScheme.surfaceContainerHighest.withValues(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
      // Style cards
      cardTheme: CardTheme(
        elevation: 4, // Slightly more elevation
        shape: RoundedRectangleBorder(
          // Adjusted border radius slightly for a sharper feel
          borderRadius: BorderRadius.circular(8.0), // Slightly less rounded
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        color: netSuiteColorScheme.surface, // Use surface color for cards
      ),
      // Style Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: netSuiteColorScheme.secondary, // Use secondary color for FAB
        foregroundColor: netSuiteColorScheme.onSecondary, // Use onSecondary for FAB text/icon
        shape: RoundedRectangleBorder( // Add a shape for a sharper look
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      // Style Dialogs
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Slightly less rounded dialog corners
        elevation: 8, // More elevation for dialogs
        backgroundColor: netSuiteColorScheme.surfaceContainerHighest, // Use surface variant for dialog background
        titleTextStyle: TextStyle(color: netSuiteColorScheme.onSurfaceVariant, fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: netSuiteColorScheme.onSurfaceVariant),
      ),
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: netSuiteColorScheme.primary, // Use primary color for AppBar
        foregroundColor: netSuiteColorScheme.onPrimary, // Use onPrimary for AppBar text/icons
        elevation: 4.0, // Add some elevation
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: netSuiteColorScheme.onPrimary,
        ),
      ),
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: netSuiteColorScheme.secondary, // Use secondary for progress color
        linearTrackColor: netSuiteColorScheme.surfaceContainerHighest, // Use surface variant for track
      ),
      // Icon Theme
      iconTheme: IconThemeData(
        color: netSuiteColorScheme.onSurface, // Default icon color
      ),
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: netSuiteColorScheme.tertiary, // Use tertiary for text buttons
        ),
      ),
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: netSuiteColorScheme.secondaryContainer, // Use secondary container for elevated buttons
          foregroundColor: netSuiteColorScheme.onSecondaryContainer, // Use onSecondaryContainer for text/icon
          shape: RoundedRectangleBorder( // Add a shape for a sharper look
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
      ),
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        tileColor: netSuiteColorScheme.surface, // Use surface color for list tiles
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder( // Add a shape for a sharper look
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );

    return MaterialApp(
      title: 'Life Tracker',
      theme: baseTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false, // Hide debug banner
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
    // Fetch tasks after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use context.read for one-time reads in initState/callbacks
      // Ensure Hive box is open before fetching tasks
      context.read<TaskService>().openTaskBox().then((_) {
        context.read<TaskService>().fetchTasks().catchError((error) {
          // Show error if initial fetch fails (TaskService also handles internal error state)
          if (mounted) { // Check if the widget is still in the tree
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load initial tasks: $error'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        });
      });
    });
  }

  // Helper to determine progress bar color based on 0.0-1.0 scale
  Color _getColorForProgress(double progress, BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final theme = Theme.of(context);
    // Interpolate between errorContainer (start) and primaryContainer (end)
    return Color.lerp(
      theme.colorScheme.errorContainer, // Start color (e.g., red-ish)
      theme.colorScheme.primaryContainer, // End color (e.g., primary-ish)
      clampedProgress,
    )!;
  }

  // --- Dialog to add a new task ---
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
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'Enter task name',
                  prefixIcon: Icon(Icons.title),
                ),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: targetController,
                decoration: const InputDecoration(
                  labelText: 'Target Value',
                  hintText: 'e.g., 100',
                  prefixIcon: Icon(Icons.track_changes),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a target value';
                  }
                  final number = double.tryParse(value);
                  if (number == null) {
                    return 'Please enter a valid number';
                  }
                  if (number <= 0) { // Ensure target is positive
                    return 'Target must be greater than 0';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton( // Use ElevatedButton for primary action
            onPressed: () async {
              if (_addTaskFormKey.currentState!.validate()) {
                final title = titleController.text.trim();
                final target = double.parse(targetController.text); // Already validated

                Navigator.pop(dialogContext); // Close dialog first
                try {
                  // When adding a task, backend should initialize progress/current
                  await taskService.addTask(title, target);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Task "$title" added'),
                        backgroundColor: Colors.green[700],
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add task: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  // --- Dialog to Update Progress (Uses 0-100 scale for UI) ---
  void _showUpdateProgressDialog(BuildContext context, Task task) {
    // Initialize slider with 0-100 scale based on task's current progress
    double currentProgressPercent = task.progressPercent; // Use the getter for initial value
    final taskService = context.read<TaskService>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Use StatefulBuilder to manage the slider's state within the dialog
        return StatefulBuilder(
            builder: (context, setStateDialog) { // Renamed setState to avoid conflict
              return AlertDialog(
                title: Text('Update Progress: ${task.title}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Current Progress: ${currentProgressPercent.toStringAsFixed(0)}%"),
                    Slider(
                      value: currentProgressPercent,
                      min: 0.0,
                      max: 100.0, // Use 0-100 scale for slider
                      divisions: 100, // Allow fine-grained control
                      label: "${currentProgressPercent.toStringAsFixed(0)}%", // Display percentage
                      onChanged: (newValue) {
                        setStateDialog(() { // Use the dialog's setState
                          currentProgressPercent = newValue;
                        });
                      },
                    ),
                    // Optional: Display Target/Current values if needed
                    // Text("Target: ${task.target.toStringAsFixed(0)}"),
                    // Text("Achieved: ${task.current.toStringAsFixed(0)}"),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      try {
                        // Convert back to 0.0-1.0 scale before updating
                        final newProgressFraction = (currentProgressPercent / 100.0).clamp(0.0, 1.0);

                        // Calculate the new current value based on target and new progress
                        final newCurrentValue = task.target * newProgressFraction;

                        // Update task with the new fractional progress and calculated current value
                        // Also mark as completed if progress reaches 100%
                        await taskService.updateTask(task.copyWith(
                          progress: newProgressFraction,
                          current: newCurrentValue, // Pass the calculated current value
                          isCompleted: newProgressFraction >= 1.0,
                        ));

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Progress for "${task.title}" updated'),
                              backgroundColor: Colors.green[700],
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update progress: $e'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Update'),
                  ),
                ],
              );
            }
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // Use context.watch to listen for changes in TaskService's state
    final taskService = context.watch<TaskService>();
    final theme = Theme.of(context); // Get theme for colors

    return Scaffold(
      // --- Drawer ---
      drawer: Drawer(
        backgroundColor: theme.colorScheme.surfaceContainerHighest, // Match dialog/input fill
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer, // Use a theme color
              ),
              child: Text(
                'Control Center',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: theme.colorScheme.onSurfaceVariant),
              title: Text('Home', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              onTap: () {
                // Close the drawer
                Navigator.pop(context);
                // Navigate to home (already there)
              },
            ),
            // Add more list tiles for other sections later
            // ListTile(
            //   leading: Icon(Icons.settings, color: theme.colorScheme.onSurfaceVariant),
            //   title: Text('Settings', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            //   onTap: () {
            //     // Close the drawer
            //     Navigator.pop(context);
            //     // Navigate to settings page
            //   },
            // ),
          ],
        ),
      ),
      // --- End Drawer ---
      appBar: AppBar(
        title: Text(
          'Life Tracker',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: theme.colorScheme.primary, // Use primary color for AppBar
        elevation: 4.0, // Add some elevation
        // Add a leading icon to open the drawer
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Open Control Center',
              color: theme.colorScheme.onPrimary,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          // Show loading indicator or refresh button
          if (taskService.isLoading && taskService.tasks.isEmpty) // Show spinner only on initial load
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: theme.colorScheme.onPrimary))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Tasks',
              color: theme.colorScheme.onPrimary, // Ensure icon color contrasts with AppBar
              onPressed: taskService.isLoading ? null : taskService.fetchTasks, // Disable while loading
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: taskService.fetchTasks,
        color: theme.colorScheme.secondary, // Color of the refresh indicator
        child: Column(
          children: [
            // Display Error Message Banner
            if (taskService.errorMessage != null && taskService.errorMessage!.isNotEmpty)
              Container(
                color: theme.colorScheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.onError),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        taskService.errorMessage!,
                        style: TextStyle(color: theme.colorScheme.onError),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.colorScheme.onError, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Dismiss Error',
                      onPressed: () => context.read<TaskService>().setError(null), // Clear error
                    )
                  ],
                ),
              ),

            // Task List or Loading/Empty State
            Expanded(
              child: (taskService.isLoading && taskService.tasks.isEmpty && taskService.errorMessage == null) // Show spinner only on initial load with no cached data/error
                  ? const Center(child: CircularProgressIndicator()) // Loading state
                  : (taskService.tasks.isEmpty && !taskService.isLoading && taskService.errorMessage == null) // Empty state only if not loading and no error
                  ? Center( // Empty state
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.list_alt_rounded, size: 60, color: theme.colorScheme.secondary),
                    const SizedBox(height: 16),
                    Text(
                      "No tasks yet!",
                      style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap the '+' button to add your first task.",
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : ListView.builder( // Task list
                padding: const EdgeInsets.symmetric(vertical: 8.0), // Padding for the list
                itemCount: taskService.tasks.length,
                itemBuilder: (context, index) {
                  final task = taskService.tasks[index];
                  // Use a unique key for Dismissible
                  // Using ValueKey is generally preferred over Key for list items
                  final dismissKey = ValueKey(task.id);

                  return Dismissible(
                    key: dismissKey,
                    background: Container( // Mark as complete background
                      color: Colors.green.shade600,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    secondaryBackground: Container( // Delete background
                      color: theme.colorScheme.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Delete', style: TextStyle(color: theme.colorScheme.onError, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.delete_outline, color: theme.colorScheme.onError),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) { // Deleting (swipe left)
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Task?'),
                            content: Text('Are you sure you want to delete "${task.title}"? This action cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                              ),
                            ],
                          ),
                        ) ?? false; // Return false if dialog is dismissed
                      } else { // Completing/Incompleting (swipe right)
                        // No confirmation needed, just perform the action
                        return true;
                      }
                    },
                    onDismissed: (direction) async {
                      // Note: The item is visually removed by Dismissible.
                      // Now, perform the backend action via the service.
                      final service = context.read<TaskService>();
                      final originalTitle = task.title; // Store for snackbar message

                      if (direction == DismissDirection.endToStart) { // Delete (swipe left)
                        try {
                          await service.deleteTask(task.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Task "$originalTitle" deleted'),
                                backgroundColor: theme.colorScheme.primary,
                              ),
                            );
                          }
                        } catch (e) {
                          // Error is handled by service, which shows banner and reverts UI
                          debugPrint("Error caught during deleteTask in UI: $e");
                        }
                      } else { // Toggle Complete (swipe right)
                        try {
                          final newCompletedStatus = !task.isCompleted;
                          double newProgressFraction;
                          double newCurrentValue;

                          if (newCompletedStatus) {
                            // If marking complete, set progress to 1.0 and current to target
                            newProgressFraction = 1.0;
                            newCurrentValue = task.target;
                          } else {
                            // If marking incomplete, revert to previous progress and current
                            // (or recalculate based on previous progress)
                            // Reverting to previous values is simpler here
                            newProgressFraction = task.progress;
                            newCurrentValue = task.current;
                            // Alternative: Recalculate based on previous progress
                            // newCurrentValue = task.progress * task.target;
                          }


                          await service.updateTask(task.copyWith(
                            isCompleted: newCompletedStatus,
                            progress: newProgressFraction, // Use the calculated fraction
                            current: newCurrentValue, // Use the calculated current value
                          ));

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Task "$originalTitle" marked ${newCompletedStatus ? "complete" : "incomplete"}'),
                                backgroundColor: Colors.green[700],
                              ),
                            );
                          }
                        } catch (e) {
                          // Error handled by service, shows banner and reverts UI
                          debugPrint("Error caught during updateTask (toggle) in UI: $e");
                        }
                      }
                      // Important: Do not manually remove from the list here.
                      // TaskService handles list updates (optimistically and on error)
                      // and calls notifyListeners() which rebuilds the ListView.
                    },
                    child: Card( // Wrap ListTile in a Card
                      // Use the task's ID as the key for the Card for better performance
                      key: ValueKey(task.id),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                            color: task.isCompleted ? theme.textTheme.bodySmall?.color : theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: LinearProgressIndicator(
                            value: task.progress.clamp(0.0, 1.0), // Expects 0.0-1.0
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getColorForProgress(task.progress, context),
                            ),
                            minHeight: 8, // Slightly thicker bar
                            borderRadius: BorderRadius.circular(4), // Rounded progress bar
                          ),
                        ),
                        trailing: Row( // Use Row for better alignment
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Display percentage using the getter
                            Text(
                              '${task.progressPercent.toStringAsFixed(0)}%', // Use the getter
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8), // Spacing
                            Icon(
                              task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: task.isCompleted ? Colors.green.shade600 : theme.colorScheme.secondary,
                              size: 24,
                            ),
                          ],
                        ),
                        onTap: () => _showUpdateProgressDialog(context, task), // Open dialog on tap
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended( // Use extended FAB
        onPressed: () => _showAddTaskDialog(context),
        tooltip: 'Add New Task',
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}