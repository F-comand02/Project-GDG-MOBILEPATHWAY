import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verifikasi Email'),
        content: const Text('Email verifikasi telah dikirim. Silakan cek inbox atau spam folder dan klik link untuk memverifikasi akun.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              setState(() => _isLoading = true);
              try {
                await _auth.sendVerificationEmail();
                _showMessage('Email verifikasi dikirim ulang.');
              } catch (e) {
                _showMessage('Gagal mengirim ulang: $e');
              }
              setState(() => _isLoading = false);
            },
            child: const Text('Kirim Ulang'),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      await _auth.register(
        _emailController.text.trim(),
        _passController.text,
      );
      setState(() => _isLoading = false);

      // Show verification dialog
      _showVerificationDialog();
    } catch (e) {
      setState(() => _isLoading = false);
      String errorMsg = 'Registrasi gagal. Coba lagi.';
      if (e.toString().contains('weak-password')) {
        errorMsg = 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      } else if (e.toString().contains('email-already-in-use')) {
        errorMsg = 'Email sudah digunakan. Gunakan email lain atau login.';
      } else if (e.toString().contains('invalid-email')) {
        errorMsg = 'Format email tidak valid.';
      } else {
        errorMsg = 'Error: $e';
      }
      _showMessage(errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun GDG')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Daftar Akun Baru',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Daftar', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
