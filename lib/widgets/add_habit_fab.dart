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
    return FloatingActionButton(
      onPressed: () => _showAddHabitDialog(context),
      child: const Icon(Icons.add),
    );
  }
  
  void _showAddHabitDialog(BuildContext context) {
    showDialog(
      context: context,
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
          const SnackBar(content: Text('Habit created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create habit: $e'),
            backgroundColor: Colors.red,
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
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'Create New Habit',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
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
              
              const SizedBox(height: 20),
              
              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 20),
              
              // Frequency dropdown
              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                items: _frequencies.map((frequency) {
                  return DropdownMenuItem<String>(
                    value: frequency,
                    child: Text(frequency.capitalize()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedFrequency = newValue;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 20),
              
              // Start date
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Start Date (Optional)',
                        border: const OutlineInputBorder(),
                        filled: true,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _selectDate,
                        ),
                      ),
                      controller: TextEditingController(
                        text: _startDate != null 
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Not set',
                      ),
                    ),
                  ),
                  if (_startDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Notes
              CustomTextField(
                controller: _notesController,
                labelText: 'Notes (Optional)',
                hintText: 'Add any additional details...',
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      onPressed: _isLoading ? null : _createHabit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Habit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
