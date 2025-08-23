import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _otherDetailsController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  String? _selectedGender;
  File? _profileImage;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Listen to profile changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.addListener(_onProfileChanged);
      _animationController.forward();
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
    _animationController.dispose();
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
      _profileImage = null;
    });
    _loadProfileData();
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
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
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(result['message']),
              ],
            ),
            backgroundColor: const Color(0xFFFF6B35),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Text(result['message']),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Text('Failed to update profile: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF6B35),
            ),
          );
        }
        
        // Ensure controllers have current profile data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isEditing) {
            _loadProfileData();
          }
        });
        
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: CustomScrollView(
            slivers: [
              // Modern header with gradient
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFF6B35),
                          const Color(0xFFFF8A50),
                          const Color(0xFFFFA726),
                        ],
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            if (!_isEditing) ...[
                              // Profile avatar with upload option
                              GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 3,
                                        ),
                                      ),
                                      child: _profileImage != null
                                          ? ClipOval(
                                              child: Image.file(
                                                _profileImage!,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.person,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF6B35),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Display name
                              Text(
                                profile['displayName'] ?? 'No name set',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                            
                            if (_isEditing) ...[
                              const SizedBox(height: 20),
                              // Display name field when editing
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 32),
                                child: CustomTextField(
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
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Profile content
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 25,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section title
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: Color(0xFFFF6B35),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'Profile Information',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Profile details grid
                              _buildProfileGrid(profile),
                              
                              const SizedBox(height: 32),
                              
                                                          // Action buttons
                            if (_isEditing) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      onPressed: _isLoading ? null : () {
                                        _cancelEditing();
                                      },
                                      isOutlined: true,
                                      textColor: Colors.grey[700],
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
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Save Changes'),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      onPressed: () => _startEditing(),
                                      child: const Text('Edit Profile'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomButton(
                                      onPressed: _logout,
                                      backgroundColor: Colors.red[400],
                                      child: const Text('Logout'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildProfileGrid(Map<String, dynamic> profile) {
    return Column(
      children: [
        // Email (read-only)
        _buildInfoCard(
          'Email',
          profile['email'] ?? 'No email set',
          Icons.email_outlined,
          Colors.blue,
          isEditable: false,
        ),
        
        const SizedBox(height: 16),
        
        // Gender
        if (_isEditing)
          _buildEditableCard(
            'Gender',
            _buildGenderDropdown(),
            Icons.person_outline,
            Colors.purple,
          )
        else
          _buildInfoCard(
            'Gender',
            profile['gender'] ?? 'Not specified',
            Icons.person_outline,
            Colors.purple,
          ),
        
        const SizedBox(height: 16),
        
        // Age
        if (_isEditing)
          _buildEditableCard(
            'Age',
            CustomTextField(
              controller: _ageController,
              labelText: 'Age',
              hintText: 'Enter age in years',
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
            ),
            Icons.cake_outlined,
            Colors.orange,
          )
        else
          _buildInfoCard(
            'Age',
            _getAgeFromProfile(profile),
            Icons.cake_outlined,
            Colors.orange,
          ),
        
        const SizedBox(height: 16),
        
        // Weight
        if (_isEditing)
          _buildEditableCard(
            'Weight',
            CustomTextField(
              controller: _weightController,
              labelText: 'Weight',
              hintText: 'Enter weight in kg',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final double weight = double.tryParse(value) ?? 0.0;
                  if (weight < 0.0) {
                    return 'Weight must be positive';
                  }
                }
                return null;
              },
            ),
            Icons.fitness_center_outlined,
            Colors.green,
          )
        else
          _buildInfoCard(
            'Weight',
            _getWeightFromProfile(profile),
            Icons.fitness_center_outlined,
            Colors.green,
          ),
        
        const SizedBox(height: 16),
        
        // Height
        if (_isEditing)
          _buildEditableCard(
            'Height',
            CustomTextField(
              controller: _heightController,
              labelText: 'Height',
              hintText: 'Enter height in cm',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final double height = double.tryParse(value) ?? 0.0;
                  if (height < 0.0) {
                    return 'Height must be positive';
                  }
                }
                return null;
              },
            ),
            Icons.height_outlined,
            Colors.teal,
          )
        else
          _buildInfoCard(
            'Height',
            _getHeightFromProfile(profile),
            Icons.height_outlined,
            Colors.teal,
          ),
        
        const SizedBox(height: 16),
        
        // Notes
        if (_isEditing)
          _buildEditableCard(
            'Notes',
            CustomTextField(
              controller: _otherDetailsController,
              labelText: 'Notes',
              hintText: 'Add any additional details...',
              maxLines: 3,
            ),
            Icons.note_outlined,
            Colors.indigo,
          )
        else
          _buildInfoCard(
            'Notes',
            (profile['otherDetails'] as Map<String, dynamic>?)?.values.firstOrNull?.toString() ?? 'No notes',
            Icons.note_outlined,
            Colors.indigo,
          ),
        
        const SizedBox(height: 16),
        
        // Member since
        _buildInfoCard(
          'Member Since',
          _formatDate(profile['createdAt']),
          Icons.calendar_today_outlined,
          Colors.red,
          isEditable: false,
        ),
      ],
    );
  }
  
  Widget _buildInfoCard(String label, String value, IconData icon, Color color, {bool isEditable = true}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not specified' : value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          if (isEditable)
            Icon(
              Icons.edit_outlined,
              size: 18,
              color: Colors.grey[400],
            ),
        ],
      ),
    );
  }
  
  Widget _buildEditableCard(String label, Widget child, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: false,
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
          return null;
        },
      ),
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
