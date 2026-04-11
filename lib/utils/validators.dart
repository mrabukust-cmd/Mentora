// utils/validators.dart
import 'package:flutter/material.dart';

class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    // Optional: Restrict to campus email domains
    // if (!value.toLowerCase().endsWith('@youruniversity.edu')) {
    //   return 'Please use your university email';
    // }
    
    return null;
  }

  // Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    // Check for complexity
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    if (!hasUppercase || !hasLowercase || !hasDigit) {
      return 'Password must contain uppercase, lowercase, and numbers';
    }
    
    return null;
  }

  // Name validation
  static String? name(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return '$fieldName must be less than 50 characters';
    }
    
    // Only allow letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  // Message validation
  static String? message(String? value, {int minLength = 10, int maxLength = 500}) {
    if (value == null || value.trim().isEmpty) {
      return 'Message is required';
    }
    
    if (value.trim().length < minLength) {
      return 'Message must be at least $minLength characters';
    }
    
    if (value.trim().length > maxLength) {
      return 'Message must be less than $maxLength characters';
    }
    
    return null;
  }

  // Skill name validation
  static String? skillName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Skill name is required';
    }
    
    if (value.trim().length < 3) {
      return 'Skill name must be at least 3 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Skill name must be less than 50 characters';
    }
    
    return null;
  }

  // Meeting location validation
  static String? meetingLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Meeting location is required';
    }
    
    if (value.trim().length < 5) {
      return 'Please provide more details about the location';
    }
    
    if (value.trim().length > 200) {
      return 'Location description is too long';
    }
    
    return null;
  }

  // Date validation (must be in future)
  static String? futureDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(value.year, value.month, value.day);
    
    if (selectedDate.isBefore(today)) {
      return 'Please select a future date';
    }
    
    // Optional: Limit to next 30 days
    final maxDate = today.add(const Duration(days: 30));
    if (selectedDate.isAfter(maxDate)) {
      return 'Date must be within the next 30 days';
    }
    
    return null;
  }

  // Rating validation
  static String? rating(double? value) {
    if (value == null || value == 0.0) {
      return 'Please select a rating';
    }
    
    if (value < 1.0 || value > 5.0) {
      return 'Rating must be between 1 and 5';
    }
    
    return null;
  }

  // Generic required field
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Dropdown selection validation
  static String? selection<T>(T? value, {String fieldName = 'Selection'}) {
    if (value == null) {
      return 'Please select a $fieldName';
    }
    return null;
  }

  // Combined validation
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}

// Example usage in forms:
/*
TextFormField(
  validator: Validators.email,
  // or combine multiple validators
  validator: Validators.combine([
    Validators.required,
    Validators.email,
  ]),
)
*/

// Custom form field with built-in validation
class ValidatedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;

  const ValidatedTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}