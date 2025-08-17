import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get all habits for a user
  Future<List<Habit>> getUserHabits(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Habit.fromFirestore(doc))
          .toList();
    } catch (e) {
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
      final habitData = {
        'userId': userId,
        'title': title,
        'category': category,
        'frequency': frequency,
        'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'currentStreak': 0,
        'completionHistory': [],
      };
      
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .add(habitData);
      
      // Get the created document to return the habit with ID
      final doc = await docRef.get();
      return Habit.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create habit: $e');
    }
  }
  
  // Update an existing habit
  Future<void> updateHabit(String habitId, Map<String, dynamic> updates) async {
    try {
      // Find the habit first to get the userId
      final habitDoc = await _findHabitDocument(habitId);
      if (habitDoc == null) {
        throw Exception('Habit not found');
      }
      
      await habitDoc.reference.update(updates);
    } catch (e) {
      throw Exception('Failed to update habit: $e');
    }
  }
  
  // Delete a habit
  Future<void> deleteHabit(String habitId) async {
    try {
      final habitDoc = await _findHabitDocument(habitId);
      if (habitDoc == null) {
        throw Exception('Habit not found');
      }
      
      await habitDoc.reference.delete();
    } catch (e) {
      throw Exception('Failed to delete habit: $e');
    }
  }
  
  // Toggle habit completion for today
  Future<void> toggleHabitCompletion(String habitId, bool completed) async {
    try {
      final habitDoc = await _findHabitDocument(habitId);
      if (habitDoc == null) {
        throw Exception('Habit not found');
      }
      
      final habit = Habit.fromFirestore(habitDoc);
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
      
      await habitDoc.reference.update({
        'completionHistory': newCompletionHistory
            .map((date) => Timestamp.fromDate(date))
            .toList(),
        'currentStreak': newStreak,
      });
    } catch (e) {
      throw Exception('Failed to toggle habit completion: $e');
    }
  }
  
  // Find habit document by ID
  Future<DocumentSnapshot?> _findHabitDocument(String habitId) async {
    try {
      // Search across all users (since we don't have userId)
      // This is not ideal for production, but works for demo
      final querySnapshot = await _firestore
          .collectionGroup('habits')
          .where(FieldPath.documentId, isEqualTo: habitId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
      return null;
    } catch (e) {
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
