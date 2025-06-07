// For @required
import 'package:hive/hive.dart';

// Add this annotation for Hive code generation
// The typeId should be unique across all your Hive Adapters
@HiveType(typeId: 0)
// Represents a single task item
class Task extends HiveObject { // Extend HiveObject for Hive integration
  // Add HiveField annotations for fields you want to store
  // Field IDs must be unique within this class
  @HiveField(0)
  final String id; // Unique identifier (e.g., NetSuite Internal ID)

  @HiveField(1)
  final String title; // Name or description of the task

  @HiveField(2)
  final double progress; // Progress towards completion (stored as 0.0 to 1.0)

  @HiveField(3)
  final bool isCompleted; // Whether the task is marked as done

  @HiveField(4)
  final double target; // The target value for the task (e.g., 100 pages, 10 km)

  @HiveField(5)
  final double current; // The current value achieved (potentially updated separately)

  Task({
    required this.id,
    required this.title,
    this.progress = 0.0, // Default progress is 0%
    this.isCompleted = false,
    this.target = 1.0, // Default target (useful if progress is the main metric)
    this.current = 0.0, // Default current value
  }) : assert(progress >= 0.0 && progress <= 1.0, 'Progress must be between 0.0 and 1.0'); // Validate progress range

  // Getter to easily access progress as a percentage (0-100)
  // This getter is for UI display and doesn't need a HiveField annotation
  double get progressPercent => (progress * 100).clamp(0.0, 100.0);

  // Factory constructor for creating a Task from JSON data (e.g., from API)
  factory Task.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse numbers (double)
    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    // Safely parse progress, ensuring it's within the 0.0-1.0 range
    double parsedProgress = parseDouble(json['progress'], defaultValue: 0.0);
    // Clamp the progress value AFTER parsing
    parsedProgress = parsedProgress.clamp(0.0, 1.0);

    // Safely parse target and current values
    double parsedTarget = parseDouble(json['target'], defaultValue: 1.0); // Default target 1
    double parsedCurrent = parseDouble(json['current'], defaultValue: 0.0);

    // Safely parse boolean
    bool parseBool(dynamic value, {bool defaultValue = false}) {
      if (value is bool) {
        return value;
      } else if (value is String) {
        return value.toLowerCase() == 'true';
      } else if (value is int) {
        return value == 1;
      }
      return defaultValue;
    }
    bool parsedIsCompleted = parseBool(json['isCompleted'], defaultValue: false);

    // Automatically mark completed if progress is 1.0, unless explicitly set otherwise
    // (This depends on desired logic - maybe backend handles completion state primarily)
    // if (parsedProgress >= 1.0) {
    //    parsedIsCompleted = true;
    // }

    return Task(
      // Use null-aware operators and provide defaults for safety
      id: json['id']?.toString() ?? json['netsuiteId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(), // Ensure ID is a string, provide fallback
      title: json['title']?.toString() ?? 'Untitled Task',
      progress: parsedProgress,
      isCompleted: parsedIsCompleted,
      target: parsedTarget,
      current: parsedCurrent,
    );
  }

  // Method to create a copy of the task with optional field overrides
  // Useful for updating state immutably
  Task copyWith({
    String? id,
    String? title,
    double? progress,
    bool? isCompleted,
    double? target,
    double? current,
  }) {
    // Ensure progress remains clamped if updated
    final clampedProgress = (progress ?? this.progress).clamp(0.0, 1.0);

    // Calculate new current based on new progress and target if either is updated
    final newTarget = target ?? this.target;
    final newCurrent = current ?? (clampedProgress * newTarget); // Calculate current based on progress and target

    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      // Use the clamped value
      progress: clampedProgress,
      // If progress is explicitly set to 1.0 or more, mark completed unless overridden
      isCompleted: isCompleted ?? (clampedProgress >= 1.0 ? true : this.isCompleted),
      target: newTarget,
      current: newCurrent, // Use the calculated or provided new current
    );
  }

  // Method to convert Task object to JSON format
  // Useful for sending data to an API (e.g., for updates)
  // Ensure keys match what the backend API expects
  Map<String, dynamic> toJson() {
    return {
      // Use 'id' or 'netsuiteId' based on backend expectation
      'id': id,
      // 'netsuiteId': id,
      'title': title,
      'progress': progress.clamp(0.0, 1.0), // Ensure progress is 0.0-1.0 when sending
      'isCompleted': isCompleted,
      'target': target,
      'current': current, // Include current value
    };
  }

  // Override equality operator and hashCode for proper comparisons,
  // especially when using Tasks in Sets or as Map keys, or with Provider updates.
  // HiveObject already provides equality based on its internal key,
  // but overriding might be useful if comparing Task objects not retrieved from a box.
  // For simplicity with Hive, you might rely on HiveObject's equality.
  // Keeping this for robustness if comparing detached Task objects.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Task &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              title == other.title &&
              progress == other.progress &&
              isCompleted == other.isCompleted &&
              target == other.target &&
              current == other.current;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      progress.hashCode ^
      isCompleted.hashCode ^
      target.hashCode ^
      current.hashCode;

  @override
  String toString() {
    return 'Task(id: $id, title: "$title", progress: $progress, completed: $isCompleted, target: $target, current: $current)';
  }
}