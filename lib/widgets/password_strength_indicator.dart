import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final Map<String, bool> requirements;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    required this.requirements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strength = _calculateStrength();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        
        // Strength bar
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength / 5,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor(strength)),
                minHeight: 4,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getStrengthText(strength),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getStrengthColor(strength),
              ),
            ),
          ],
        ),
        
        if (password.isNotEmpty) ...[
          const SizedBox(height: 8),
          
          // Requirements list
          ...requirements.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Icon(
                  entry.value ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: entry.value ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _getRequirementText(entry.key),
                  style: TextStyle(
                    fontSize: 12,
                    color: entry.value ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }

  int _calculateStrength() {
    return requirements.values.where((met) => met).length;
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
      case 3:
        return Colors.orange;
      case 4:
        return Colors.yellow[700]!;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStrengthText(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Strong';
      default:
        return '';
    }
  }

  String _getRequirementText(String requirement) {
    switch (requirement) {
      case 'minLength':
        return 'At least 8 characters';
      case 'hasUppercase':
        return 'Contains uppercase letter';
      case 'hasLowercase':
        return 'Contains lowercase letter';
      case 'hasDigits':
        return 'Contains number';
      case 'hasSpecialChar':
        return 'Contains special character';
      default:
        return requirement;
    }
  }
}
