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
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
                    _animationController.forward(from: 0.0);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Category badge and actions
                        Row(
                          children: [
                            // Category badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.habit.categoryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: widget.habit.categoryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.habit.categoryIcon,
                                    size: 16,
                                    color: widget.habit.categoryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.habit.category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: widget.habit.categoryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // More options menu
                            Container(
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? const Color(0xFF2A3149)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: isDark 
                                      ? const Color(0xFF9CA3AF)
                                      : Colors.grey[700],
                                  size: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                                          size: 16,
                                          color: const Color(0xFFFF6B35),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Edit',
                                          style: TextStyle(
                                            fontSize: 13,
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
                                          size: 16,
                                          color: Colors.red[400],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            fontSize: 13,
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
                        
                        const SizedBox(height: 16),
                        
                        // Habit title
                        Text(
                          widget.habit.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark 
                                ? const Color(0xFFE5E7EB)
                                : const Color(0xFF2C3E50),
                            height: 1.2,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Frequency and streak info
                        Row(
                          children: [
                            // Frequency badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.habit.frequency.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF6B35),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Streak info
                            Row(
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  size: 16,
                                  color: const Color(0xFFFF6B35),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.habit.currentStreak} day streak',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark 
                                        ? const Color(0xFF9CA3AF)
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Notes section
                        if (widget.habit.notes != null && widget.habit.notes!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? const Color(0xFF2A3149)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
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
                                fontSize: 13,
                                color: isDark 
                                    ? const Color(0xFF9CA3AF)
                                    : Colors.grey[700],
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Completion toggle button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: widget.habit.isCompletedToday 
                                ? const Color(0xFFFF6B35).withOpacity(0.15)
                                : (isDark 
                                    ? const Color(0xFF2A3149)
                                    : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.habit.isCompletedToday 
                                  ? const Color(0xFFFF6B35).withOpacity(0.4)
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
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
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
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.habit.isCompletedToday ? 'Completed Today!' : 'Mark as Complete',
                                      style: TextStyle(
                                        fontSize: 13,
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
