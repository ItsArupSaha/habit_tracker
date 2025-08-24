import 'package:flutter/material.dart';
import '../models/habit.dart';

class HabitCard extends StatefulWidget {
  final Habit habit;
  final Function(bool) onToggleCompletion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggleCompletion,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF1E2337) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 25,
                    offset: const Offset(0, 15),
                  ),
                ],
                border: Border.all(
                  color: isDark 
                      ? const Color(0xFF2A3149)
                      : Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Card tap animation
                    _animationController.forward(from: 0.0);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row with category and actions
                        Row(
                          children: [
                            // Category badge with modern design
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.habit.categoryColor.withOpacity(0.2),
                                    widget.habit.categoryColor.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: widget.habit.categoryColor.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.habit.categoryIcon,
                                    size: 18,
                                    color: widget.habit.categoryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.habit.category,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: widget.habit.categoryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // Frequency badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.habit.frequency.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF6B35),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // More options menu with modern design
                            Container(
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? const Color(0xFF2A3149)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: isDark 
                                      ? const Color(0xFF9CA3AF)
                                      : Colors.grey[700],
                                  size: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      widget.onEdit();
                                      break;
                                    case 'delete':
                                      widget.onDelete();
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: const Color(0xFFFF6B35),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Edit',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isDark 
                                                ? const Color(0xFFE5E7EB)
                                                : const Color(0xFF2C3E50),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.red[400],
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.red[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Habit title with modern typography
                        Text(
                          widget.habit.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark 
                                ? const Color(0xFFE5E7EB)
                                : const Color(0xFF2C3E50),
                            height: 1.3,
                          ),
                        ),
                        
                        // Notes (if any) with modern styling
                        if (widget.habit.notes != null && widget.habit.notes!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? const Color(0xFF2A3149)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark 
                                    ? const Color(0xFF3A4159)
                                    : Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              widget.habit.notes!,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark 
                                    ? const Color(0xFF9CA3AF)
                                    : Colors.grey[700],
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Bottom row with completion toggle and streak
                        Row(
                          children: [
                            // Completion toggle with modern design
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: widget.habit.isCompletedToday 
                                      ? const Color(0xFFFF6B35).withOpacity(0.1)
                                      : (isDark 
                                          ? const Color(0xFF2A3149)
                                          : Colors.grey[100]),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: widget.habit.isCompletedToday 
                                        ? const Color(0xFFFF6B35).withOpacity(0.3)
                                        : (isDark 
                                            ? const Color(0xFF3A4159)
                                            : Colors.grey[300]!),
                                    width: 1.5,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      widget.onToggleCompletion(!widget.habit.isCompletedToday);
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            widget.habit.isCompletedToday 
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color: widget.habit.isCompletedToday 
                                                ? const Color(0xFFFF6B35)
                                                : (isDark 
                                                    ? const Color(0xFF9CA3AF)
                                                    : Colors.grey[600]),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            widget.habit.isCompletedToday ? 'Completed!' : 'Mark Complete',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: widget.habit.isCompletedToday 
                                                  ? const Color(0xFFFF6B35)
                                                  : (isDark 
                                                      ? const Color(0xFF9CA3AF)
                                                      : Colors.grey[700]),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Streak count with modern design
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFF8A50),
                                    const Color(0xFFFFA726),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF8A50).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${widget.habit.currentStreak}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Streak',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
