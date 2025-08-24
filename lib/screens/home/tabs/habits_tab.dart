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

class _HabitsTabState extends State<HabitsTab> with TickerProviderStateMixin {
  final HabitService _habitService = HabitService();
  List<Habit> _habits = [];
  bool _isLoading = true;
  String? _selectedCategory;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
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
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadHabits();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
        _fadeController.forward();
        _slideController.forward();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF0A0E21) 
          : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Category filter with modern design
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF1E2337) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: isDark 
                      ? const Color(0xFF2A3149)
                      : Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark 
                          ? const Color(0xFFE5E7EB)
                          : const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category || 
                            (_selectedCategory == null && category == 'All');
                        
                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = _selectedCategory == category ? null : category;
                                });
                              },
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? LinearGradient(
                                    colors: [
                                      const Color(0xFFFF6B35),
                                      const Color(0xFFFF8A50),
                                    ],
                                  ) : null,
                                  color: isSelected ? null : (isDark 
                                      ? const Color(0xFF2A3149)
                                      : Colors.grey[100]),
                                  borderRadius: BorderRadius.circular(25),
                                  border: isSelected ? null : Border.all(
                                    color: isDark 
                                        ? const Color(0xFF3A4159)
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : (isDark 
                                        ? const Color(0xFF9CA3AF)
                                        : Colors.grey[700]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Habits list with modern cards
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                )
              : _filteredHabits.isEmpty
                  ? SliverFillRemaining(
                      child: FadeTransition(
                        opacity: _fadeController,
                        child: _buildEmptyState(),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final habit = _filteredHabits[index];
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _slideController,
                                curve: Interval(
                                  index * 0.1,
                                  1.0,
                                  curve: Curves.easeOutCubic,
                                ),
                              )),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: HabitCard(
                                  habit: habit,
                                  onToggleCompletion: (completed) => _toggleHabitCompletion(habit, completed),
                                  onEdit: () => _editHabit(habit),
                                  onDelete: () => _deleteHabit(habit),
                                ),
                              ),
                            );
                          },
                          childCount: _filteredHabits.length,
                        ),
                      ),
                    ),
        ],
      ),
      floatingActionButton: AddHabitFAB(onHabitAdded: (habit) {
        setState(() {
          _habits.insert(0, habit);
        });
      }),
    );
  }
  
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_task,
              size: 60,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No habits yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDark 
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFF2C3E50),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap the + button to create your first habit',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark 
                  ? const Color(0xFF9CA3AF)
                  : Colors.grey[600],
              fontSize: 16,
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
