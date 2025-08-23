import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../models/habit.dart';
import '../../../services/habit_service.dart';
import '../../../widgets/habit_card.dart';
import '../../../widgets/add_habit_fab.dart';

class HabitsTab extends StatefulWidget {
  const HabitsTab({super.key});

  @override
  State<HabitsTab> createState() => _HabitsTabState();
}

class _HabitsTabState extends State<HabitsTab> {
  final HabitService _habitService = HabitService();
  List<Habit> _habits = [];
  bool _isLoading = true;
  String? _selectedCategory;
  
  final List<String> _categories = [
    'All',
    'Health',
    'Study',
    'Fitness',
    'Productivity',
    'Mental Health',
    'Others',
  ];
  
  @override
  void initState() {
    super.initState();
    _loadHabits();
  }
  
  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        final habits = await _habitService.getUserHabits(authService.currentUser!.uid);
        setState(() {
          _habits = habits;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load habits: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  List<Habit> get _filteredHabits {
    if (_selectedCategory == null || _selectedCategory == 'All') {
      return _habits;
    }
    return _habits.where((habit) => habit.category == _selectedCategory).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Category filter
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category || 
                      (_selectedCategory == null && category == 'All');
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Habits list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHabits.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadHabits,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredHabits.length,
                          itemBuilder: (context, index) {
                            final habit = _filteredHabits[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: HabitCard(
                                habit: habit,
                                onToggleCompletion: (completed) async {
                                  await _toggleHabitCompletion(habit, completed);
                                },
                                onEdit: () => _editHabit(habit),
                                onDelete: () => _deleteHabit(habit),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: AddHabitFAB(
        onHabitAdded: (habit) {
          setState(() {
            _habits.add(habit);
          });
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No habits yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first habit',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Future<void> _toggleHabitCompletion(Habit habit, bool completed) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        await _habitService.toggleHabitCompletion(
          authService.currentUser!.uid,
          habit.id,
          completed,
        );
        
        // Update local state
        setState(() {
          final index = _habits.indexWhere((h) => h.id == habit.id);
          if (index != -1) {
            _habits[index] = habit.copyWith(
              isCompletedToday: completed,
              currentStreak: completed ? habit.currentStreak + 1 : 0,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update habit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _editHabit(Habit habit) {
    // TODO: Navigate to edit habit screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature coming soon!')),
    );
  }
  
  Future<void> _deleteHabit(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        if (authService.currentUser != null) {
          await _habitService.deleteHabit(authService.currentUser!.uid, habit.id);
          setState(() {
            _habits.removeWhere((h) => h.id == habit.id);
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Habit deleted successfully')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete habit: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
