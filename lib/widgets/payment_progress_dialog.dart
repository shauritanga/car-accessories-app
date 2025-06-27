import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';

class PaymentProgressDialog extends ConsumerStatefulWidget {
  final String paymentId;
  final PaymentMethod paymentMethod;
  final double amount;
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const PaymentProgressDialog({
    super.key,
    required this.paymentId,
    required this.paymentMethod,
    required this.amount,
    required this.onSuccess,
    required this.onError,
  });

  @override
  ConsumerState<PaymentProgressDialog> createState() => _PaymentProgressDialogState();
}

class _PaymentProgressDialogState extends ConsumerState<PaymentProgressDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  List<PaymentStep> _steps = [];
  int _currentStep = 0;
  bool _isCompleted = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _initializeSteps();
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeSteps() {
    switch (widget.paymentMethod) {
      case PaymentMethod.mobileMoney:
        _steps = [
          PaymentStep(
            title: 'Initiating Payment',
            description: 'Sending payment request to mobile money provider',
            icon: Icons.phone_android,
          ),
          PaymentStep(
            title: 'User Confirmation',
            description: 'Please confirm the payment on your mobile device',
            icon: Icons.security,
          ),
          PaymentStep(
            title: 'Processing Payment',
            description: 'Processing your payment...',
            icon: Icons.payment,
          ),
          PaymentStep(
            title: 'Payment Completed',
            description: 'Your payment has been processed successfully',
            icon: Icons.check_circle,
          ),
        ];
        break;
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        _steps = [
          PaymentStep(
            title: 'Validating Card',
            description: 'Validating your card details',
            icon: Icons.credit_card,
          ),
          PaymentStep(
            title: 'Bank Processing',
            description: 'Processing payment with your bank',
            icon: Icons.account_balance,
          ),
          PaymentStep(
            title: 'Payment Completed',
            description: 'Your payment has been processed successfully',
            icon: Icons.check_circle,
          ),
        ];
        break;
      default:
        _steps = [
          PaymentStep(
            title: 'Processing Payment',
            description: 'Processing your payment...',
            icon: Icons.payment,
          ),
          PaymentStep(
            title: 'Payment Completed',
            description: 'Your payment has been processed successfully',
            icon: Icons.check_circle,
          ),
        ];
    }
    
    _simulatePaymentProgress();
  }

  void _simulatePaymentProgress() async {
    for (int i = 0; i < _steps.length - 1; i++) {
      await Future.delayed(Duration(
        milliseconds: widget.paymentMethod == PaymentMethod.mobileMoney ? 1500 : 1200
      ));
      
      if (mounted) {
        setState(() {
          _currentStep = i + 1;
        });
      }
    }
    
    // Complete the payment
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isCompleted = true;
        _currentStep = _steps.length - 1;
      });
      _animationController.stop();
      
      // Auto close after showing success
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getPaymentMethodIcon(),
                  color: colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Processing Payment',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'TZS ${widget.amount.toStringAsFixed(0)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Progress Steps
            ...List.generate(_steps.length, (index) {
              final step = _steps[index];
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep || _isCompleted;
              final isCurrent = index == _currentStep && !_isCompleted;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    // Step Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? colorScheme.primary
                            : isActive
                                ? colorScheme.primary.withValues(alpha: 0.2)
                                : colorScheme.surfaceContainerHighest,
                      ),
                      child: isCurrent && !_isCompleted
                          ? RotationTransition(
                              turns: _animation,
                              child: Icon(
                                Icons.sync,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            )
                          : Icon(
                              isCompleted ? Icons.check : step.icon,
                              color: isCompleted
                                  ? Colors.white
                                  : isActive
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Step Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                              color: isActive
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (isCurrent || isCompleted) ...[
                            const SizedBox(height: 4),
                            Text(
                              step.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            if (_isCompleted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Payment completed successfully!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon() {
    switch (widget.paymentMethod) {
      case PaymentMethod.mobileMoney:
        return Icons.phone_android;
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.cashOnDelivery:
        return Icons.money;
    }
  }
}

class PaymentStep {
  final String title;
  final String description;
  final IconData icon;

  PaymentStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}
