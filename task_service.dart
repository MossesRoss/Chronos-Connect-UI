import 'dart:convert';
import 'dart:async'; // For TimeoutException
import 'dart:io'; // For SocketException, etc.
import 'package:flutter/foundation.dart'; // For ChangeNotifier, kDebugMode
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart'; // Import Hive
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive Flutter
import 'task.dart'; // Import the Task model and the generated part file

// Manages task data fetching and manipulation, notifying listeners of changes.
class TaskService extends ChangeNotifier {
  // --- Configuration ---
  // Define base URLs for emulator (debug) and deployed (release) environments
  // Ensure these URLs point to your Cloud Functions endpoints
  static final String _emulatorBaseUrl = 'https://us-central1-chronos-connect007.cloudfunctions.net/'; // Common Android emulator localhost
  // static final String _emulatorBaseUrl = 'http://127.0.0.1:5001/chronos-connect007/us-central1'; // Common iOS simulator/desktop localhost
  static const String _projectId = 'chronos-connect007';
  static const String _region = 'us-central1';
  // Deployed URL for Firebase Cloud Functions v2 (adjust if using v1)
  static const String _deployedBaseUrl = 'https://$_region-$_projectId.cloudfunctions.net';

  // Determine the base URL based on build mode (debug/release)
  static String get baseUrl {
    // IMPORTANT: Check your actual function URLs in Firebase Console/gcloud
    // Ensure they match these definitions.
    // Using kDebugMode is a common way to switch, but ensure it aligns
    // with how you run your emulators vs deployed app.
    return kDebugMode ? _emulatorBaseUrl : _deployedBaseUrl;
  }

  // API endpoint paths (relative to the baseUrl)
  static const String _getTasksEndpoint = '/getTasks';
  static const String _createTaskEndpoint = '/createTask';
  static const String _updateTaskEndpoint = '/updateTask';
  static const String _deleteTaskEndpoint = '/deleteTask'; // Assumes ID in path: /deleteTask/{taskId}

  // --- State ---
  List<Task> _tasks = []; // Private list of tasks
  bool _isLoading = false; // Indicates if an operation is in progress
  String? _errorMessage; // Stores the last error message

  // --- Hive Box ---
  // Late keyword means it will be initialized before first use
  late Box<Task> _taskBox;

  // --- Getters (Public access to state) ---
  List<Task> get tasks => List.unmodifiable(_tasks); // Return unmodifiable list
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- Internal State Management Helpers ---

  // Sets loading state and clears error, notifies listeners
  void _startLoading() {
    if (_isLoading) return; // Avoid concurrent loading states if needed
    _isLoading = true;
    _errorMessage = null; // Clear previous errors on new operation
    notifyListeners();
  }

  // Clears loading state, notifies listeners
  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  // Sets error message, stops loading, notifies listeners
  void setError(String? message) {
    _errorMessage = message;
    _isLoading = false; // Stop loading on error
    notifyListeners();
    if (message != null) {
      debugPrint("TaskService Error: $message"); // Log error for debugging
    }
  }

  // --- Hive Methods ---

  // Opens the Hive box for tasks
  Future<void> openTaskBox() async {
    // Check if the box is already open
    if (!Hive.isBoxOpen('tasks')) {
      _taskBox = await Hive.openBox<Task>('tasks');
    } else {
      _taskBox = Hive.box<Task>('tasks');
    }
    // Load tasks from Hive on initialization
    _tasks = _taskBox.values.toList();
    notifyListeners(); // Notify listeners that initial data is available
  }

  // Gets the opened Hive box
  Box<Task> _getTaskBox() {
    // Ensure the box is open before returning
    if (!Hive.isBoxOpen('tasks')) {
      // This case should ideally not happen if openTaskBox is called on startup
      // but adding a check for safety or throw an error
      throw Exception("Task box is not open. Call openTaskBox() first.");
    }
    return Hive.box<Task>('tasks');
  }

  // Saves tasks to Hive
  Future<void> _saveTasksToHive() async {
    final box = _getTaskBox();
    await box.clear(); // Clear the box
    await box.addAll(_tasks); // Add all current tasks from the list
  }

  // --- API Methods ---

  // Fetches tasks from the backend
  Future<void> fetchTasks() async {
    // First, load from Hive for immediate display
    try {
      await openTaskBox(); // Ensure box is open
      _tasks = _getTaskBox().values.toList();
      if (_tasks.isNotEmpty) {
        debugPrint("Loaded ${_tasks.length} tasks from Hive.");
        notifyListeners(); // Show cached data immediately
      }
    } catch (e) {
      debugPrint("Error loading tasks from Hive: $e");
      // Continue to fetch from network even if Hive load fails
    }

    _startLoading(); // Start loading indicator for network fetch
    try {
      final response = await http.post( // Assuming getTasks requires POST
        Uri.parse('$baseUrl$_getTasksEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({}), // Send empty JSON body if required by backend
      ).timeout(const Duration(seconds: 20)); // Network timeout

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Map JSON data to Task objects using Task.fromJson
        // Handle potential parsing errors gracefully if needed
        final fetchedTasks = data.map((item) {
          try {
            return Task.fromJson(item as Map<String, dynamic>);
          } catch (e) {
            debugPrint("Error parsing task JSON: $item, Error: $e");
            return null; // Skip invalid items
          }
        }).whereType<Task>().toList(); // Filter out nulls

        // Optional: Implement merge logic if needed (e.g., if local changes exist)
        // For now, we'll replace local data with fetched data
        _tasks = fetchedTasks;

        // Save fetched tasks to Hive
        await _saveTasksToHive();
        debugPrint("Fetched ${_tasks.length} tasks from network and saved to Hive.");

        setError(null); // Clear error on success
      } else {
        // Handle non-200 HTTP status codes
        setError('Failed to load tasks from network. Status: ${response.statusCode}, Body: ${response.body.substring(0, (response.body.length > 100 ? 100 : response.body.length))}...');
      }
    } on TimeoutException catch (e) {
      setError('Network timeout fetching tasks: $e');
    } on SocketException catch (e) {
      setError('Network error fetching tasks (check connection/URL): $e');
    } catch (e) {
      // Handle other errors (e.g., JSON decoding, network issues)
      setError('An unexpected error occurred fetching tasks: $e');
    } finally {
      // Ensure loading stops regardless of success or failure
      // Check if still loading before stopping, in case setError already stopped it
      if (_isLoading) {
        _stopLoading();
      }
    }
  }

  // Adds a new task to the backend
  Future<void> addTask(String title, double target) async {
    _startLoading();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$_createTaskEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': title,
          'target': target, // Send target value
          // Backend should initialize progress, isCompleted, current etc.
        }),
      ).timeout(const Duration(seconds: 15));

      // Check for successful creation status codes (e.g., 201 Created or 200 OK)
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Refetch the entire list to get the new task with its ID and update Hive
        await fetchTasks(); // This handles loading state internally and saves to Hive
      } else {
        setError('Failed to create task. Status: ${response.statusCode}, Body: ${response.body.substring(0, (response.body.length > 100 ? 100 : response.body.length))}...');
      }
    } on TimeoutException catch (e) {
      setError('Network timeout adding task: $e');
    } on SocketException catch (e) {
      setError('Network error adding task: $e');
    } catch (e) {
      setError('Error adding task: $e');
      // Rethrow if the UI needs to handle this specific error differently
      // throw Exception('Error adding task: $e');
    } finally {
      // Ensure loading stops if fetchTasks wasn't called or if an error occurred before it
      if (_isLoading) {
        _stopLoading();
      }
    }
  }

  // Updates an existing task (using optimistic update)
  Future<void> updateTask(Task task) async {
    // --- Optimistic Update ---
    final originalTasks = List<Task>.from(_tasks); // Backup current state
    final taskIndex = _tasks.indexWhere((t) => t.id == task.id);

    if (taskIndex != -1) {
      _tasks[taskIndex] = task; // Update locally immediately
      // Also update in Hive optimistically
      try {
        await _getTaskBox().put(task.id, task); // Use put with ID as key
      } catch (e) {
        debugPrint("Error saving task ${task.id} to Hive optimistically: $e");
        // Decide how to handle Hive error during optimistic update
        // For now, just log and continue with network request
      }

      _errorMessage = null; // Clear previous errors optimistically
      notifyListeners(); // Update UI right away
    } else {
      debugPrint("Task not found locally for optimistic update: ${task.id}");
      // Don't attempt backend update if task isn't found locally
      return;
    }
    // --- End Optimistic Update ---

    try {
      // Ensure progress sent is 0.0-1.0
      final updatePayload = task.toJson(); // Use toJson which should handle clamping and includes current/target

      final response = await http.patch( // Or POST if backend uses POST for updates
        Uri.parse('$baseUrl$_updateTaskEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatePayload), // Send updated task data (includes current/target)
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        // --- Revert Optimistic Update on Failure ---
        debugPrint("Update failed, reverting UI and Hive. Status: ${response.statusCode}");
        _tasks = originalTasks; // Restore original list
        // Revert in Hive as well
        final box = _getTaskBox();
        // Find the original task in the backup list and put it back in Hive
        final originalTask = originalTasks.firstWhere((t) => t.id == task.id);
        await box.put(originalTask.id, originalTask);

        setError('Failed to update task. Status: ${response.statusCode}, Body: ${response.body.substring(0, (response.body.length > 100 ? 100 : response.body.length))}...');
        // No need to call notifyListeners here, _setError already does
        // --- End Revert ---
      } else {
        // Success - Optimistic update is already reflected in UI and Hive.
        // Error message was already cleared optimistically.
        debugPrint("Task ${task.id} updated successfully on backend.");
        // Optionally, parse response if backend returns updated data
        // final updatedData = json.decode(response.body);
        // final updatedTask = Task.fromJson(updatedData);
        // _tasks[taskIndex] = updatedTask; // Update with confirmed data
        // await _getTaskBox().put(updatedTask.id, updatedTask); // Update Hive with confirmed data
        // notifyListeners(); // Notify if backend data differs
      }
    } on TimeoutException catch (e) {
      _tasks = originalTasks; // Revert UI
      // Revert in Hive
      final box = _getTaskBox();
      final originalTask = originalTasks.firstWhere((t) => t.id == task.id);
      await box.put(originalTask.id, originalTask);
      setError('Network timeout updating task: $e');
    } on SocketException catch (e) {
      _tasks = originalTasks; // Revert UI
      // Revert in Hive
      final box = _getTaskBox();
      final originalTask = originalTasks.firstWhere((t) => t.id == task.id);
      await box.put(originalTask.id, originalTask);
      setError('Network error updating task: $e');
    } catch (e) {
      // --- Revert Optimistic Update on Exception ---
      debugPrint("Update error, reverting UI and Hive: $e");
      _tasks = originalTasks; // Restore original list
      // Revert in Hive
      final box = _getTaskBox();
      final originalTask = originalTasks.firstWhere((t) => t.id == task.id);
      await box.put(originalTask.id, originalTask);
      setError('Error updating task: $e');
      // --- End Revert ---
    }
    // No _stopLoading() here as optimistic update doesn't use the main loading flag
  }

  // Deletes a task (using optimistic update)
  Future<void> deleteTask(String taskId) async {
    // --- Optimistic Update ---
    final originalTasks = List<Task>.from(_tasks);
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    Task? removedTask; // Store removed task for potential undo/revert

    if (taskIndex != -1) {
      removedTask = _tasks.removeAt(taskIndex); // Remove locally immediately
      // Also remove from Hive optimistically
      try {
        await _getTaskBox().delete(taskId); // Use delete with ID as key
      } catch (e) {
        debugPrint("Error deleting task $taskId from Hive optimistically: $e");
        // Decide how to handle Hive error during optimistic delete
        // For now, just log and continue with network request
      }

      _errorMessage = null; // Clear errors optimistically
      notifyListeners(); // Update UI
    } else {
      debugPrint("Task not found locally for optimistic delete: $taskId");
      return; // Don't proceed if task doesn't exist locally
    }
    // --- End Optimistic Update ---

    try {
      // Assume backend expects ID in the URL path for DELETE
      final response = await http.delete(
        Uri.parse('$baseUrl$_deleteTaskEndpoint/$taskId'),
        headers: {'Content-Type': 'application/json'}, // Headers might be needed for auth later
      ).timeout(const Duration(seconds: 15));

      // Check for successful deletion status codes (e.g., 200 OK or 204 No Content)
      if (response.statusCode != 204 && response.statusCode != 200) {
        // --- Revert Optimistic Update on Failure ---
        debugPrint("Delete failed, reverting UI and Hive. Status: ${response.statusCode}");
        _tasks = originalTasks; // Restore original list
        // Revert in Hive as well - add the removed task back
 // Keep this check as removedTask *could* theoretically be null if taskIndex was -1
        await _getTaskBox().put(removedTask.id, removedTask);
              setError('Failed to delete task. Status: ${response.statusCode}, Body: ${response.body.substring(0, (response.body.length > 100 ? 100 : response.body.length))}...');
        // --- End Revert ---
      } else {
        // Success - Optimistic update is already reflected in UI and Hive.
        debugPrint("Task $taskId deleted successfully on backend.");
      }
    } on TimeoutException catch (e) {
      _tasks = originalTasks; // Revert UI
 // Keep this check
      await _getTaskBox().put(removedTask.id, removedTask); // Revert Hive
          setError('Network timeout deleting task: $e');
    } on SocketException catch (e) {
      _tasks = originalTasks; // Revert UI
 // Keep this check
      await _getTaskBox().put(removedTask.id, removedTask); // Revert Hive
          setError('Network error deleting task: $e');
    } catch (e) {
      // --- Revert Optimistic Update on Exception ---
      debugPrint("Delete error, reverting UI and Hive: $e");
      _tasks = originalTasks; // Restore original list
 // Keep this check
      await _getTaskBox().put(removedTask.id, removedTask); // Revert Hive
          setError('Error deleting task: $e');
      // --- End Revert ---
    }
    // No _stopLoading() here for optimistic update
  }
}