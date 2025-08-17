import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String frequency; // 'daily' or 'weekly'
  final DateTime? startDate;
  final String? notes;
  final DateTime createdAt;
  final int currentStreak;
  final List<DateTime> completionHistory;
  final bool isCompletedToday;
  
  const Habit({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.frequency,
    this.startDate,
    this.notes,
    required this.createdAt,
    this.currentStreak = 0,
    this.completionHistory = const [],
    this.isCompletedToday = false,
  });
  
  // Create from Firestore document
  factory Habit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Habit(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      frequency: data['frequency'] ?? 'daily',
      startDate: data['startDate'] != null 
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      currentStreak: data['currentStreak'] ?? 0,
      completionHistory: (data['completionHistory'] as List<dynamic>?)
          ?.map((timestamp) => (timestamp as Timestamp).toDate())
          .toList() ?? [],
      isCompletedToday: _isCompletedToday(
        data['completionHistory'] as List<dynamic>? ?? [],
        data['frequency'] ?? 'daily',
      ),
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'frequency': frequency,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'currentStreak': currentStreak,
      'completionHistory': completionHistory
          .map((date) => Timestamp.fromDate(date))
          .toList(),
    };
  }
  
  // Check if habit is completed today
  static bool _isCompletedToday(List<dynamic> completionHistory, String frequency) {
    if (completionHistory.isEmpty) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (frequency == 'daily') {
      return completionHistory.any((timestamp) {
        final completionDate = (timestamp as Timestamp).toDate();
        final completionDay = DateTime(
          completionDate.year,
          completionDate.month,
          completionDate.day,
        );
        return completionDay.isAtSameMomentAs(today);
      });
    } else if (frequency == 'weekly') {
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      return completionHistory.any((timestamp) {
        final completionDate = (timestamp as Timestamp).toDate();
        return completionDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
               completionDate.isBefore(endOfWeek.add(const Duration(days: 1)));
      });
    }
    
    return false;
  }
  
  // Create a copy with updated values
  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    String? category,
    String? frequency,
    DateTime? startDate,
    String? notes,
    DateTime? createdAt,
    int? currentStreak,
    List<DateTime>? completionHistory,
    bool? isCompletedToday,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      currentStreak: currentStreak ?? this.currentStreak,
      completionHistory: completionHistory ?? this.completionHistory,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
    );
  }
  
  // Get category icon
  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'health':
        return Icons.health_and_safety;
      case 'study':
        return Icons.school;
      case 'fitness':
        return Icons.fitness_center;
      case 'productivity':
        return Icons.work;
      case 'mental health':
        return Icons.psychology;
      default:
        return Icons.category;
    }
  }
  
  // Get category color
  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'health':
        return Colors.green;
      case 'study':
        return Colors.blue;
      case 'fitness':
        return Colors.orange;
      case 'productivity':
        return Colors.purple;
      case 'mental health':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
  
  @override
  String toString() {
    return 'Habit(id: $id, title: $title, category: $category, frequency: $frequency)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Habit && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}
