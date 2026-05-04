import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

// Handles both sign-in and sign-up in one screen.
// Toggling between modes shows/hides the name field without navigating anywhere.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // sign-up only

  final _authService = AuthService();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _error;

  static const _bgColor = Color(0xFF0F1117);
  static const _cardColor = Color(0xFF1A1D2E);
  static const _accentColor = Color(0xFF4F8EF7);
  static const _textColor = Color(0xFFE8EAED);
  static const _subtextColor = Color(0xFF9AA0A6);

  // AuthService returns null on success or an error string to display.
  // On success the auth stream in main.dart fires and routes to HomeScreen automatically.
  void _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    String? error;

    if (_isSignUp) {
      error = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
    } else {
      error = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }

    setState(() {
      _isLoading = false;
      _error = error;
    });
  }

  // Shared styled text field used for all inputs.
  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscure = false, IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: _textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _subtextColor),
          prefixIcon: icon != null ? Icon(icon, color: _subtextColor) : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),

              // App icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.school_rounded, color: _accentColor, size: 32),
              ),
              const SizedBox(height: 24),

              const Text('FocusNFlow.',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      letterSpacing: -0.5)),
              const SizedBox(height: 8),

              Text(
                _isSignUp ? 'Create your student account' : 'Welcome back, let\'s get focused',
                style: const TextStyle(fontSize: 15, color: _subtextColor),
              ),
              const SizedBox(height: 48),

              // Form card — name field only appears in sign-up mode
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isSignUp) ...[
                      _buildTextField(_nameController, 'Full Name',
                          icon: Icons.person_outline_rounded),
                      const SizedBox(height: 12),
                    ],
                    _buildTextField(_emailController, 'GSU Email (@student.gsu.edu)',
                        icon: Icons.email_outlined),
                    const SizedBox(height: 12),
                    _buildTextField(_passwordController, 'Password',
                        obscure: true, icon: Icons.lock_outline_rounded),
                    const SizedBox(height: 20),

                    // Show error from AuthService if sign-in/sign-up failed
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Disabled while loading so the user can't double-tap
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(_isSignUp ? 'Create Account' : 'Sign In',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Switch between sign-in and sign-up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp ? 'Already have an account? ' : 'Don\'t have an account? ',
                    style: const TextStyle(color: _subtextColor),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _isSignUp = !_isSignUp;
                      _error = null; // clear old error when switching
                    }),
                    child: Text(
                      _isSignUp ? 'Sign In' : 'Sign Up',
                      style: const TextStyle(
                          color: _accentColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
