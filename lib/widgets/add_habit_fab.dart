import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/habit_service.dart';
import '../models/habit.dart';
import 'custom_text_field.dart';
import 'custom_button.dart';

class AddHabitFAB extends StatelessWidget {
  final Function(Habit) onHabitAdded;
  
  const AddHabitFAB({
    super.key,
    required this.onHabitAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF6B35),
            Color(0xFFFF8A50),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
  
  void _showAddHabitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddHabitDialog(),
    ).then((habit) {
      if (habit != null) {
        onHabitAdded(habit);
      }
    });
  }
}

class AddHabitDialog extends StatefulWidget {
  const AddHabitDialog({super.key});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedCategory = 'Health';
  String _selectedFrequency = 'daily';
  DateTime? _startDate;
  bool _isLoading = false;
  
  final List<String> _categories = [
    'Health',
    'Study',
    'Fitness',
    'Productivity',
    'Mental Health',
    'Others',
  ];
  
  final List<String> _frequencies = ['daily', 'weekly'];
  
  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _createHabit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final habitService = HabitService();
      final habit = await habitService.createHabit(
        userId: authService.currentUser!.uid,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        frequency: _selectedFrequency,
        startDate: _startDate,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).pop(habit);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Habit created successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFFFF6B35),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Text('Failed to create habit: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6B35),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark 
              ? const Color(0xFF1E2337) 
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.4)
                  : Colors.black.withOpacity(0.2),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Simple header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B35),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_task,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Create New Habit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Form content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Habit title
                    CustomTextField(
                      controller: _titleController,
                      labelText: 'Habit Title',
                      hintText: 'e.g., Drink 8 glasses of water',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Habit title is required';
                        }
                        if (value.length < 3) {
                          return 'Title must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category and frequency
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: isDark 
                                  ? const Color(0xFF2A3149)
                                  : Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                              labelStyle: TextStyle(
                                color: isDark 
                                    ? const Color(0xFF9CA3AF)
                                    : Colors.grey[600],
                              ),
                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(
                                  category,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark 
                                        ? const Color(0xFFE5E7EB)
                                        : const Color(0xFF2C3E50),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedCategory = newValue;
                                });
                              }
                            },
                            isExpanded: true,
                            dropdownColor: isDark 
                                ? const Color(0xFF2A3149)
                                : Colors.white,
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedFrequency,
                            decoration: InputDecoration(
                              labelText: 'Frequency',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: isDark 
                                  ? const Color(0xFF2A3149)
                                  : Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                              labelStyle: TextStyle(
                                color: isDark 
                                    ? const Color(0xFF9CA3AF)
                                    : Colors.grey[600],
                              ),
                            ),
                            items: _frequencies.map((frequency) {
                              return DropdownMenuItem<String>(
                                value: frequency,
                                child: Text(
                                  frequency.capitalize(),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark 
                                        ? const Color(0xFFE5E7EB)
                                        : const Color(0xFF2C3E50),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedFrequency = newValue;
                                });
                              }
                            },
                            isExpanded: true,
                            dropdownColor: isDark 
                                ? const Color(0xFF2A3149)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Start date
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFF2A3149)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark 
                                ? const Color(0xFF3A4159)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: const Color(0xFFFF6B35),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _startDate != null 
                                  ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                  : 'Start Date (Optional)',
                              style: TextStyle(
                                color: _startDate != null 
                                    ? (isDark 
                                        ? const Color(0xFFE5E7EB)
                                        : const Color(0xFF2C3E50))
                                    : (isDark 
                                        ? const Color(0xFF9CA3AF)
                                        : Colors.grey[600]),
                              ),
                            ),
                            const Spacer(),
                            if (_startDate != null)
                              IconButton(
                                icon: Icon(
                                  Icons.clear, 
                                  size: 18,
                                  color: isDark 
                                      ? const Color(0xFF9CA3AF)
                                      : Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _startDate = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Notes
                    CustomTextField(
                      controller: _notesController,
                      labelText: 'Notes (Optional)',
                      hintText: 'Add any additional details...',
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? const Color(0xFF2A3149)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark 
                                    ? const Color(0xFF3A4159)
                                    : Colors.grey[300]!,
                                width: 1.5,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isLoading ? null : () {
                                  Navigator.of(context).pop();
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Center(
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark 
                                            ? const Color(0xFF9CA3AF)
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            onPressed: _isLoading ? null : _createHabit,
                            height: 48,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Create Habit',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
