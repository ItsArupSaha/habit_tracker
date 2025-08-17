import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  
  // User profile data
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? get userProfile => _userProfile;
  
  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }
  
  // Load user profile from Firestore
  Future<void> _loadUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _userProfile = doc.data();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }
  
  // User registration
  Future<Map<String, dynamic>> registerUser({
    required String displayName,
    required String email,
    required String password,
    String? gender,
    Map<String, dynamic>? otherDetails,
  }) async {
    try {
      // Create user with Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        // Save user profile to Firestore
        final userData = {
          'displayName': displayName,
          'email': email,
          'gender': gender,
          'otherDetails': otherDetails ?? {},
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        };
        
        await _firestore.collection('users').doc(user.uid).set(userData);
        
        // Save user profile to Firestore (but don't sign in automatically)
        _userProfile = userData;
        
        // Sign out the user so they need to explicitly log in
        await _auth.signOut();
        
        // Clear local session data
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('userId');
        await prefs.remove('userEmail');
        
        notifyListeners();
        
        return {'success': true, 'message': 'Registration successful! Please log in to continue.'};
      }
      
      return {'success': false, 'message': 'Failed to create user'};
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      switch (e.code) {
        case 'weak-password':
          message = 'Password is too weak';
          break;
        case 'email-already-in-use':
          message = 'Email is already registered';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }
  
  // User login
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Save session locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userCredential.user!.uid);
        await prefs.setString('userEmail', email);
        
        // Load user profile and notify listeners
        await _loadUserProfile(userCredential.user!.uid);
        notifyListeners();
        
        return {'success': true, 'message': 'Login successful!'};
      }
      
      return {'success': false, 'message': 'Login failed'};
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      switch (e.code) {
        case 'user-not-found':
          message = 'User not found';
          break;
        case 'wrong-password':
          message = 'Wrong password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }
  
  // User logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      
      // Clear local session
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('userEmail');
      
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }
  
  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? gender,
    Map<String, dynamic>? otherDetails,
  }) async {
    try {
      if (currentUser == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }
      
      final updates = <String, dynamic>{
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      if (displayName != null) updates['displayName'] = displayName;
      if (gender != null) updates['gender'] = gender;
      if (otherDetails != null) updates['otherDetails'] = otherDetails;
      
      await _firestore.collection('users').doc(currentUser!.uid).update(updates);
      
      // Update local profile
      _userProfile?.addAll(updates);
      notifyListeners();
      
      return {'success': true, 'message': 'Profile updated successfully!'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update profile: $e'};
    }
  }
  
  // Check if user is remembered
  Future<bool> isUserRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') != null;
  }
}
