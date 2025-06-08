import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'task.dart';

class TaskService extends ChangeNotifier {
  // --- Configuration ---
  // REVERTED: This now points back to your live server URL as you originally had.
  static final String _emulatorBaseUrl = 'https://us-central1-chronos-connect007.cloudfunctions.net/';
  static const String _projectId = 'chronos-connect007';
  static const String _region = 'us-central1';
  static const String _deployedBaseUrl = 'https://$_region-$_projectId.cloudfunctions.net';

  // The logic now correctly points to the live URL in both debug and release mode.
  static String get baseUrl {
    return kDebugMode ? _emulatorBaseUrl : _deployedBaseUrl;
  }

  static const String _getTasksEndpoint = '/getTasks';
  static const String _createTaskEndpoint = '/createTask';
  static const String _updateTaskEndpoint = '/updateTask';
  static const String _deleteTaskEndpoint = '/deleteTask';

  // --- State ---
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  late Box<Task> _taskBox;

  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _startLoading() {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
    if (message != null) {
      debugPrint("TaskService Error: $message");
    }
  }

  Future<void> openTaskBox() async {
    if (!Hive.isBoxOpen('tasks')) {
      _taskBox = await Hive.openBox<Task>('tasks');
    } else {
      _taskBox = Hive.box<Task>('tasks');
    }
    _tasks = _taskBox.values.toList();
    notifyListeners();
  }

  Box<Task> _getTaskBox() {
    if (!Hive.isBoxOpen('tasks')) {
      throw Exception("Task box is not open. Call openTaskBox() first.");
    }
    return Hive.box<Task>('tasks');
  }

  Future<void> _saveTasksToHive() async {
    final box = _getTaskBox();
    await box.clear();
    // Create a map from ID to Task to add to the box
    final Map<String, Task> taskMap = {for (var task in _tasks) task.id: task};
    await box.putAll(taskMap);
  }

  Future<void> fetchTasks() async {
    try {
      await openTaskBox();
      _tasks = _getTaskBox().values.toList();
      if (_tasks.isNotEmpty) {
        debugPrint("Loaded ${_tasks.length} tasks from Hive.");
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading tasks from Hive: $e");
    }

    _startLoading();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$_getTasksEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({}),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final fetchedTasks = data.map((item) {
          try {
            return Task.fromJson(item as Map<String, dynamic>);
          } catch (e) {
            debugPrint("Error parsing task JSON: $item, Error: $e");
            return null;
          }
        }).whereType<Task>().toList();

        _tasks = fetchedTasks;
        await _saveTasksToHive();
        debugPrint("Fetched ${_tasks.length} tasks from network and saved to Hive.");
        setError(null);
      } else {
        setError('Failed to load tasks. Status: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      setError('Network timeout fetching tasks: $e');
    } on SocketException catch (e) {
      setError('Network error fetching tasks: $e');
    } catch (e) {
      setError('An unexpected error occurred fetching tasks: $e');
    } finally {
      if (_isLoading) {
        _stopLoading();
      }
    }
  }

  Future<void> addTask(String title, double target) async {
    _startLoading();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$_createTaskEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'title': title, 'target': target}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchTasks();
      } else {
        setError('Failed to create task. Status: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      setError('Network timeout adding task: $e');
    } on SocketException catch (e) {
      setError('Network error adding task: $e');
    } catch (e) {
      setError('Error adding task: $e');
    } finally {
      if (_isLoading) {
        _stopLoading();
      }
    }
  }

  Future<void> updateTask(Task task) async {
    final originalTasks = List<Task>.from(_tasks);
    final taskIndex = _tasks.indexWhere((t) => t.id == task.id);

    if (taskIndex != -1) {
      _tasks[taskIndex] = task;
      await _getTaskBox().put(task.id, task);
      _errorMessage = null;
      notifyListeners();
    } else {
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$_updateTaskEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(task.toJson()),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        _tasks = originalTasks;
        await _saveTasksToHive(); // Revert hive to original state
        setError('Failed to update task. Status: ${response.statusCode}');
      }
    } catch (e) {
      _tasks = originalTasks;
      await _saveTasksToHive(); // Revert hive to original state
      setError('Error updating task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    final originalTasks = List<Task>.from(_tasks);
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    Task? removedTask;

    if (taskIndex != -1) {
      removedTask = _tasks.removeAt(taskIndex);
      await _getTaskBox().delete(taskId);
      _errorMessage = null;
      notifyListeners();
    } else {
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$_deleteTaskEndpoint/$taskId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 204 && response.statusCode != 200) {
        _tasks = originalTasks;
        await _saveTasksToHive(); // Revert
        setError('Failed to delete task. Status: ${response.statusCode}');
      }
    } catch (e) {
      _tasks = originalTasks;
      await _saveTasksToHive(); // Revert
      setError('Error deleting task: $e');
    }
  }
}