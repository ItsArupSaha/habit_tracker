import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _otherDetailsController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  String? _selectedGender;
  
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  
  @override
  void initState() {
    super.initState();
    // Listen to profile changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.addListener(_onProfileChanged);
    });
  }
  
  @override
  void dispose() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.removeListener(_onProfileChanged);
    _displayNameController.dispose();
    _otherDetailsController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }
  
  void _onProfileChanged() {
    if (mounted && !_isEditing) {
      _loadProfileData();
    }
  }
  
  void _loadProfileData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profile = authService.userProfile;
    
    if (profile != null) {
      _displayNameController.text = profile['displayName'] ?? '';
      _selectedGender = profile['gender'];
      
      final otherDetails = profile['otherDetails'] as Map<String, dynamic>?;
      if (otherDetails != null) {
        _otherDetailsController.text = otherDetails['notes'] ?? '';
        _ageController.text = otherDetails['age']?.toString() ?? '';
        _weightController.text = otherDetails['weight']?.toString() ?? '';
        _heightController.text = otherDetails['height']?.toString() ?? '';
      }
    }
  }
  
  void _startEditing() {
    _loadProfileData();
    setState(() {
      _isEditing = true;
    });
  }
  
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
    _loadProfileData();
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final otherDetails = {
        'notes': _otherDetailsController.text.trim(),
        'age': _ageController.text.trim().isNotEmpty ? int.tryParse(_ageController.text.trim()) : null,
        'weight': _weightController.text.trim().isNotEmpty ? double.tryParse(_weightController.text.trim()) : null,
        'height': _heightController.text.trim().isNotEmpty ? double.tryParse(_heightController.text.trim()) : null,
      };
      
      final result = await authService.updateProfile(
        displayName: _displayNameController.text.trim(),
        gender: _selectedGender,
        otherDetails: otherDetails,
      );
      
      if (result['success']) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final profile = authService.userProfile;
        
        if (profile == null) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Ensure controllers have current profile data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isEditing) {
            _loadProfileData();
          }
        });
        
        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile header
                  Center(
                    child: Column(
                      children: [
                        // Profile avatar
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Display name
                        if (_isEditing)
                          CustomTextField(
                            controller: _displayNameController,
                            labelText: 'Display Name',
                            hintText: 'Enter your display name',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Display name is required';
                              }
                              if (value.length < 2) {
                                return 'Display name must be at least 2 characters';
                              }
                              return null;
                            },
                          )
                        else
                          Text(
                            profile['displayName'] ?? 'No name set',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Profile details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Information',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Email (read-only)
                          _buildInfoRow(
                            'Email',
                            profile['email'] ?? 'No email set',
                            Icons.email_outlined,
                            isEditable: false,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Gender
                          if (_isEditing)
                            _buildGenderDropdown()
                          else
                            _buildInfoRow(
                              'Gender',
                              profile['gender'] ?? 'Not specified',
                              Icons.person_outline,
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Age
                          if (_isEditing)
                            _buildEditableField(
                              'Age',
                              _ageController,
                              Icons.cake_outlined,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final int age = int.tryParse(value) ?? 0;
                                  if (age < 0 || age > 120) {
                                    return 'Age must be between 0 and 120';
                                  }
                                }
                                return null;
                              },
                            )
                          else
                            _buildInfoRow(
                              'Age',
                              _getAgeFromProfile(profile),
                              Icons.cake_outlined,
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Weight
                          if (_isEditing)
                            _buildEditableField(
                              'Weight',
                              _weightController,
                              Icons.fitness_center_outlined,
                              keyboardType: TextInputType.number,
                              hintText: 'Enter weight in kg',
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final double weight = double.tryParse(value) ?? 0.0;
                                  if (weight < 0.0) {
                                    return 'Weight must be positive';
                                  }
                                }
                                return null;
                              },
                            )
                          else
                            _buildInfoRow(
                              'Weight',
                              _getWeightFromProfile(profile),
                              Icons.fitness_center_outlined,
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Height
                          if (_isEditing)
                            _buildEditableField(
                              'Height',
                              _heightController,
                              Icons.height_outlined,
                              keyboardType: TextInputType.number,
                              hintText: 'Enter height in cm',
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final double height = double.tryParse(value) ?? 0.0;
                                  if (height < 0.0) {
                                    return 'Height must be positive';
                                  }
                                }
                                return null;
                              },
                            )
                          else
                            _buildInfoRow(
                              'Height',
                              _getHeightFromProfile(profile),
                              Icons.height_outlined,
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Other details
                          if (_isEditing)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notes',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CustomTextField(
                                  controller: _otherDetailsController,
                                  labelText: 'Notes',
                                  hintText: 'Add any additional details...',
                                  maxLines: 3,
                                  validator: (value) {
                                    // Notes are optional, so no validation needed
                                    return null;
                                  },
                                ),
                              ],
                            )
                          else
                            _buildInfoRow(
                              'Notes',
                              (profile['otherDetails'] as Map<String, dynamic>?)?.values.firstOrNull?.toString() ?? 'No notes',
                              Icons.note_outlined,
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Member since
                          _buildInfoRow(
                            'Member Since',
                            _formatDate(profile['createdAt']),
                            Icons.calendar_today_outlined,
                            isEditable: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  if (_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _isLoading ? null : () {
                              _cancelEditing();
                            },
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    CustomButton(
                      onPressed: () => _startEditing(),
                      child: const Text('Edit Profile'),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Logout button
                  CustomButton(
                    onPressed: _logout,
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon, {bool isEditable = true}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? 'Not specified' : value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (isEditable)
          Icon(
            Icons.edit_outlined,
            size: 16,
            color: Colors.grey[400],
          ),
      ],
    );
  }
  
  Widget _buildEditableField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text, String hintText = '', String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: controller,
          labelText: label,
          hintText: hintText,
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _genderOptions.map((gender) {
            return DropdownMenuItem<String>(
              value: gender,
              child: Text(gender),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
          validator: (value) {
            // Gender is optional, so no validation needed
            return null;
          },
        ),
      ],
    );
  }
  
  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    
    try {
      if (date is Timestamp) {
        final timestamp = date as Timestamp;
        return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';
      } else if (date is DateTime) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (date is String) {
        final parsed = DateTime.parse(date);
        return '${parsed.day}/${parsed.month}/${parsed.year}';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getAgeFromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return 'Not specified';
    final otherDetails = profile['otherDetails'] as Map<String, dynamic>?;
    if (otherDetails == null) return 'Not specified';
    final age = otherDetails['age'] as int?;
    if (age == null) return 'Not specified';
    return '$age years';
  }

  String _getWeightFromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return 'Not specified';
    final otherDetails = profile['otherDetails'] as Map<String, dynamic>?;
    if (otherDetails == null) return 'Not specified';
    final weight = otherDetails['weight'] as double?;
    if (weight == null) return 'Not specified';
    return '${weight.toStringAsFixed(1)} kg';
  }

  String _getHeightFromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return 'Not specified';
    final otherDetails = profile['otherDetails'] as Map<String, dynamic>?;
    if (otherDetails == null) return 'Not specified';
    final height = otherDetails['height'] as double?;
    if (height == null) return 'Not specified';
    return '${height.toStringAsFixed(1)} cm';
  }
}
