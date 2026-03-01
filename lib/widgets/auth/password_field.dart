import 'package:bangla_hub/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong,
}

class PasswordFieldWithStrength extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Function(String)? onFieldSubmitted;
  final Function(PasswordStrength)? onStrengthChanged;
  final bool showStrengthMeter;

  const PasswordFieldWithStrength({
    Key? key,
    required this.controller,
    required this.label,
    this.hintText,
    this.validator,
    this.textInputAction,
    this.focusNode,
    this.onFieldSubmitted,
    this.onStrengthChanged,
    this.showStrengthMeter = true,
  }) : super(key: key);

  @override
  _PasswordFieldWithStrengthState createState() => _PasswordFieldWithStrengthState();
}

class _PasswordFieldWithStrengthState extends State<PasswordFieldWithStrength> {
  bool _isObscure = true;
  PasswordStrength _strength = PasswordStrength.weak;

  PasswordStrength _calculateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;
    
    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // Contains lowercase
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    
    // Contains uppercase
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    
    // Contains numbers
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    
    // Contains special characters
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.medium;
    if (score <= 5) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  Color _getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.medium:
        return AppColors.warning;
      case PasswordStrength.strong:
        return AppColors.success;
      case PasswordStrength.veryStrong:
        return AppColors.primaryGreen;
    }
  }

  String _getStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  List<String> _getStrengthRequirements(String password) {
    final requirements = <String>[];
    
    if (password.length < 8) {
      requirements.add('At least 8 characters');
    }
    
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      requirements.add('One lowercase letter');
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      requirements.add('One uppercase letter');
    }
    
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      requirements.add('One number');
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      requirements.add('One special character');
    }
    
    return requirements;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _isObscure,
          onChanged: (value) {
            final newStrength = _calculateStrength(value);
            if (_strength != newStrength) {
              setState(() {
                _strength = newStrength;
              });
              widget.onStrengthChanged?.call(newStrength);
            }
          },
          textInputAction: widget.textInputAction ?? TextInputAction.next,
          focusNode: widget.focusNode,
          onFieldSubmitted: widget.onFieldSubmitted,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText ?? 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.controller.text.isNotEmpty && widget.showStrengthMeter)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      _getStrengthText(_strength),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _getStrengthColor(_strength),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.textLight,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
          validator: widget.validator,
        ),
        
        if (widget.showStrengthMeter && widget.controller.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          
          // Strength meter
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _strength == PasswordStrength.weak
                  ? 0.25
                  : _strength == PasswordStrength.medium
                      ? 0.5
                      : _strength == PasswordStrength.strong
                          ? 0.75
                          : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: _getStrengthColor(_strength),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Requirements
          if (_strength != PasswordStrength.veryStrong)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _getStrengthRequirements(widget.controller.text)
                  .map((requirement) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              requirement,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
        ],
      ],
    );
  }
}