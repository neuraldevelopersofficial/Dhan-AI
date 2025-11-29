import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_spacing.dart';
import '../../data/services/database_service.dart';
import '../../data/models/user_profile_model.dart';
import '../providers/user_profile_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedLanguage;
  String? _selectedOccupation;
  String? _selectedIncomeRange;
  final Map<String, bool> _obligations = {
    'Rent': false,
    'Electricity': false,
    'Phone recharge': false,
    'Loan EMI': false,
    'Fuel': false,
    'School fees': false,
  };

  bool _isLoading = false;

  final List<String> _languages = [
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Marathi',
    'Gujarati',
    'Bengali',
    'Other',
  ];

  final List<String> _occupations = [
    'Gig Worker (delivery, cab, field job)',
    'Freelancer / Part-time',
    'Fixed-salary employee',
    'Student',
    'Home-based worker',
    'Other',
  ];

  final List<String> _incomeRanges = [
    '< ₹10,000',
    '₹10,000–₹20,000',
    '₹20,000–₹35,000',
    '₹35,000–₹50,000',
    '₹50,000–₹75,000',
    '₹75,000+',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill phone number from query parameter if available
    final uri = GoRouterState.of(context).uri;
    final phone = uri.queryParameters['phone'];
    if (phone != null && phone.isNotEmpty && _phoneController.text.isEmpty) {
      _phoneController.text = phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your preferred language')),
      );
      return;
    }
    if (_selectedOccupation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your occupation category')),
      );
      return;
    }
    if (_selectedIncomeRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your income range')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final databaseService = DatabaseService();
      final phoneNumber = _phoneController.text.trim();

      // Check if user already exists
      final exists = await databaseService.userExists(phoneNumber);
      if (exists) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User already exists. Please login instead.'),
              backgroundColor: Colors.orange,
            ),
          );
          context.pop(); // Go back to login
        }
        return;
      }

      // Create user profile
      final userProfile = UserProfile(
        name: _nameController.text.trim(),
        phoneNumber: phoneNumber,
        preferredLanguage: _selectedLanguage!,
        occupationCategory: _selectedOccupation!,
        incomeRange: _selectedIncomeRange!,
        monthlyObligations: _obligations,
        createdAt: DateTime.now(),
      );

      // Save to database
      await databaseService.insertUser(userProfile);

      // Save current user phone
      await saveCurrentUserPhone(phoneNumber);
      // Update provider
      ref.read(currentUserPhoneProvider.notifier).state = phoneNumber;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to home after successful signup
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Phone Number Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '9876543210',
                    prefixIcon: Icon(Icons.phone),
                    prefixText: '+91 ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length != 10) {
                      return 'Please enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Preferred Language Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Language',
                    prefixIcon: Icon(Icons.language),
                  ),
                  items: _languages.map((language) {
                    return DropdownMenuItem(
                      value: language,
                      child: Text(language),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Occupation Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedOccupation,
                  decoration: const InputDecoration(
                    labelText: 'Occupation Category',
                    prefixIcon: Icon(Icons.work),
                  ),
                  items: _occupations.map((occupation) {
                    return DropdownMenuItem(
                      value: occupation,
                      child: Text(occupation),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedOccupation = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Income Range Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedIncomeRange,
                  decoration: const InputDecoration(
                    labelText: 'Income Range (Approximate)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  items: _incomeRanges.map((range) {
                    return DropdownMenuItem(value: range, child: Text(range));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedIncomeRange = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                // Major Monthly Obligations
                Text(
                  'Major Monthly Obligations (Choose any)',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: _obligations.entries.map((entry) {
                        return CheckboxListTile(
                          title: Text(entry.key),
                          value: entry.value,
                          onChanged: (value) {
                            setState(() {
                              _obligations[entry.key] = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign Up'),
                ),
                const SizedBox(height: AppSpacing.md),
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        context.pop();
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
