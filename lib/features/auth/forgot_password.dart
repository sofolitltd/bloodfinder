import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _auth = FirebaseAuth.instance;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '✅ Password reset link sent! Please check your email inbox (and spam folder).',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Something went wrong. Please try again.';

      if (e.code == 'user-not-found') {
        message = '❌ No account found with that email address.';
      } else if (e.code == 'invalid-email') {
        message = '⚠️ Please enter a valid email address.';
      } else if (e.code == 'too-many-requests') {
        message =
            '🚫 Too many requests. Please wait a moment and try again later.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Forgot Password'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Divider(height: .8, color: Colors.black12),

            //
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reset your password',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Enter the email address associated with your account. We’ll send you a link to reset your password.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Don\'t forgot to check your spam folder.',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email address.';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Reset Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Send Reset Link',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Back to login
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('← Back to Login'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
