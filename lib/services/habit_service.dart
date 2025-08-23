import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all habits for a user
  Future<List<Habit>> getUserHabits(String userId) async {
    try {
      print('Fetching habits for user: $userId');
      print('Collection path: users/$userId/habits');
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${querySnapshot.docs.length} habits');
      
      final habits = querySnapshot.docs
          .map((doc) {
            print('Processing habit document: ${doc.id}');
            return Habit.fromFirestore(doc);
          })
          .toList();
      
      print('Successfully processed ${habits.length} habits');
      return habits;
    } catch (e) {
      print('Error fetching habits: $e');
      throw Exception('Failed to fetch habits: $e');
    }
  }

  // Create a new habit
  Future<Habit> createHabit({
    required String userId,
    required String title,
    required String category,
    required String frequency,
    DateTime? startDate,
    String? notes,
  }) async {
    try {
      print('Creating habit for user: $userId');
      print('Habit details: title=$title, category=$category, frequency=$frequency');
      
      final habitData = {
        'userId': userId,
        'title': title,
        'category': category,
        'frequency': frequency,
        'startDate': startDate != null ? Timestamp.fromDate(startDate) : null,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'currentStreak': 0,
        'completionHistory': [],
      };

      print('Collection path: users/$userId/habits');
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .add(habitData);

      print('Habit document created with ID: ${docRef.id}');

      // Get the created document to return the habit with ID
      final doc = await docRef.get();
      final habit = Habit.fromFirestore(doc);
      
      print('Habit created successfully: ${habit.title}');
      return habit;
    } catch (e) {
      print('Error creating habit: $e');
      throw Exception('Failed to create habit: $e');
    }
  }

  // Update an existing habit
  Future<void> updateHabit(String userId, String habitId, Map<String, dynamic> updates) async {
    try {
      print('Updating habit: userId=$userId, habitId=$habitId');
      print('Updates: $updates');
      print('Collection path: users/$userId/habits/$habitId');
      
      final habitDoc = await _getHabitDocument(userId, habitId);
      if (habitDoc == null) {
        throw Exception('Habit not found');
      }

      await habitDoc.reference.update(updates);
      print('Habit updated successfully');
    } catch (e) {
      print('Error updating habit: $e');
      throw Exception('Failed to update habit: $e');
    }
  }

  // Delete a habit
  Future<void> deleteHabit(String userId, String habitId) async {
    try {
      print('Deleting habit: userId=$userId, habitId=$habitId');
      print('Collection path: users/$userId/habits/$habitId');
      
      final habitDoc = await _getHabitDocument(userId, habitId);
      if (habitDoc == null) {
        throw Exception('Habit not found');
      }

      await habitDoc.reference.delete();
      print('Habit deleted successfully');
    } catch (e) {
      print('Error deleting habit: $e');
      throw Exception('Failed to delete habit: $e');
    }
  }

  // Toggle habit completion for today
  Future<void> toggleHabitCompletion(String userId, String habitId, bool completed) async {
    try {
      print('Toggling habit completion: userId=$userId, habitId=$habitId, completed=$completed');
      
      final habitDoc = await _getHabitDocument(userId, habitId);
      if (habitDoc == null) {
        throw Exception('Habit not found');
      }

      final habit = Habit.fromFirestore(habitDoc);
      print('Habit found: ${habit.title}, current streak: ${habit.currentStreak}');
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      List<DateTime> newCompletionHistory = List.from(habit.completionHistory);

      if (completed) {
        // Add today's completion if not already present
        if (!habit.isCompletedToday) {
          newCompletionHistory.add(today);
        }
      } else {
        // Remove today's completion if present
        newCompletionHistory.removeWhere((date) {
          final completionDay = DateTime(date.year, date.month, date.day);
          return completionDay.isAtSameMomentAs(today);
        });
      }

      // Calculate new streak
      final newStreak = _calculateStreak(newCompletionHistory, habit.frequency);
      print('New streak calculated: $newStreak');

      await habitDoc.reference.update({
        'completionHistory': newCompletionHistory
            .map((date) => Timestamp.fromDate(date))
            .toList(),
        'currentStreak': newStreak,
      });
      
      print('Habit completion updated successfully');
    } catch (e) {
      print('Error toggling habit completion: $e');
      throw Exception('Failed to toggle habit completion: $e');
    }
  }

  // Get habit document by ID
  Future<DocumentSnapshot?> _getHabitDocument(String userId, String habitId) async {
    try {
      print('Fetching habit document: userId=$userId, habitId=$habitId');
      print('Collection path: users/$userId/habits/$habitId');
      
      final habitDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .get();

      if (habitDoc.exists) {
        print('Habit document found successfully');
        return habitDoc;
      } else {
        print('Habit document does not exist');
        return null;
      }
    } catch (e) {
      print('Error fetching habit document: $e');
      throw Exception('Failed to find habit: $e');
    }
  }

  // Calculate current streak based on completion history
  int _calculateStreak(List<DateTime> completionHistory, String frequency) {
    if (completionHistory.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (frequency == 'daily') {
      return _calculateDailyStreak(completionHistory, today);
    } else if (frequency == 'weekly') {
      return _calculateWeeklyStreak(completionHistory, today);
    }

    return 0;
  }

  // Calculate daily streak
  int _calculateDailyStreak(List<DateTime> completionHistory, DateTime today) {
    int streak = 0;
    DateTime currentDate = today;

    // Sort completion history by date (newest first)
    final sortedHistory = List<DateTime>.from(completionHistory)
      ..sort((a, b) => b.compareTo(a));

    for (final completionDate in sortedHistory) {
      final completionDay = DateTime(
        completionDate.year,
        completionDate.month,
        completionDate.day,
      );

      if (currentDate.difference(completionDay).inDays <= 1) {
        streak++;
        currentDate = completionDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // Calculate weekly streak
  int _calculateWeeklyStreak(List<DateTime> completionHistory, DateTime today) {
    int streak = 0;
    DateTime currentWeek = _getStartOfWeek(today);

    // Sort completion history by date (newest first)
    final sortedHistory = List<DateTime>.from(completionHistory)
      ..sort((a, b) => b.compareTo(a));

    for (final completionDate in sortedHistory) {
      final completionWeek = _getStartOfWeek(completionDate);

      if (currentWeek.difference(completionWeek).inDays <= 7) {
        streak++;
        currentWeek = completionWeek.subtract(const Duration(days: 7));
      } else {
        break;
      }
    }

    return streak;
  }

  // Get start of week (Monday)
  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
}
