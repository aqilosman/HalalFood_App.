import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../restaurant/home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }
    setState(() => _isLoading = true);
    
    try {
      // 1. SEMAK FIRESTORE DAHULU (Jadikan Firestore sebagai Master Password)
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        final masterPass = userData['customPassword'];

        // Jika password yang ditaip TAK SAMA dengan dalam Firestore, terus REJECT.
        // Ini memastikan password lama yang mungkin masih ada dalam Firebase Auth terbatal.
        if (masterPass != null && masterPass != password) {
          _showError('Incorrect email or password');
          setState(() => _isLoading = false);
          return;
        }
      }

      // 2. Jika password Firestore betul (atau record tak jumpa), cuba login biasa
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
      } on FirebaseAuthException {
        // 3. Fallback: Jika Firebase Auth gagal (kes akaun manual/demo), tetapi Firestore OK
        if (userQuery.docs.isNotEmpty) {
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => HomePage(manualUid: userQuery.docs.first.id)
          ));
          return;
        }
        _showError('Incorrect email or password');
      }
    } catch (e) {
      _showError('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), 
      backgroundColor: Colors.redAccent, 
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showResetPasswordSheet(BuildContext context) {
    final primaryColor = const Color(0xFF1B4332);
    final emailCtrl = TextEditingController(text: _emailController.text);
    final keywordCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    
    bool isVerifying = true; 
    bool isResetting = false; 
    bool isSuccess = false;   
    bool isLoading = false;
    bool modalPasswordVisible = false;
    String? keywordError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 40,
              top: 20, left: 32, right: 32
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 32),
                
                if (isVerifying) ...[
                  Align(alignment: Alignment.centerLeft, child: Text('Account Recovery', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor))),
                  const SizedBox(height: 8),
                  const Align(alignment: Alignment.centerLeft, child: Text('Verify your identity with your keyword.', style: TextStyle(color: Colors.grey, fontSize: 14))),
                  const SizedBox(height: 32),
                  _buildInput(controller: emailCtrl, hint: 'Your Email', icon: Icons.email_outlined),
                  const SizedBox(height: 16),
                  TextField(
                    controller: keywordCtrl,
                    onChanged: (_) => setModalState(() => keywordError = null),
                    decoration: InputDecoration(
                      hintText: 'Recovery Keyword',
                      prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF1B4332)),
                      errorText: keywordError,
                      filled: true, fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 58,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        setModalState(() => isLoading = true);
                        try {
                          final query = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: emailCtrl.text.trim()).limit(1).get();
                          if (query.docs.isEmpty) throw 'Account not found';
                          if (query.docs.first.data()['recoveryKeyword']?.toString().toLowerCase() != keywordCtrl.text.trim().toLowerCase()) {
                            setModalState(() { keywordError = 'Incorrect keyword'; isLoading = false; });
                            return;
                          }
                          setModalState(() { isVerifying = false; isResetting = true; isLoading = false; });
                        } catch (e) { setModalState(() => isLoading = false); _showError(e.toString()); }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                      child: isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('Verify Identity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ] else if (isResetting) ...[
                  Align(alignment: Alignment.centerLeft, child: Text('New Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor))),
                  const SizedBox(height: 8),
                  const Align(alignment: Alignment.centerLeft, child: Text('Enter your new secure password.', style: TextStyle(color: Colors.grey, fontSize: 14))),
                  const SizedBox(height: 32),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: !modalPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Enter New Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF1B4332)),
                      suffixIcon: IconButton(
                        icon: Icon(modalPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                        onPressed: () => setModalState(() => modalPasswordVisible = !modalPasswordVisible),
                      ),
                      filled: true, fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 58,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        if (newPassCtrl.text.isEmpty) { _showError('Please enter password'); return; }
                        setModalState(() => isLoading = true);
                        try {
                          final query = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: emailCtrl.text.trim()).limit(1).get();
                          // MENGGUNAKAN .update() UNTUK KEKALKAN DATA LAMA
                          await query.docs.first.reference.update({'customPassword': newPassCtrl.text.trim()});
                          setModalState(() { isResetting = false; isSuccess = true; isLoading = false; });
                        } catch (e) { setModalState(() => isLoading = false); _showError(e.toString()); }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                      child: isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ] else if (isSuccess) ...[
                  Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.check_circle_rounded, size: 60, color: primaryColor)),
                  const SizedBox(height: 24),
                  const Text('Password Updated!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Your password has been changed successfully. Your profile data is safe.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),
                  SizedBox(width: double.infinity, height: 58, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Back to Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                ],
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1B4332);
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE8F1ED), Color(0xFFDEEBE6), Color(0xFFD4E5DF)]))),
          Positioned(top: 100, right: -50, child: Icon(Icons.eco_rounded, size: 250, color: primaryColor.withOpacity(0.05))),
          Positioned(bottom: 50, left: -30, child: Icon(Icons.restaurant_rounded, size: 200, color: primaryColor.withOpacity(0.05))),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]), child: Icon(Icons.mosque, size: 50, color: primaryColor)).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
                  const SizedBox(height: 16),
                  Text('HalalEats', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1)).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 25, offset: const Offset(0, 10))]),
                    child: Column(
                      children: [
                        const Text('Welcome Back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2D3436))),
                        const SizedBox(height: 8),
                        Text('Sign in to continue', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                        const SizedBox(height: 32),
                        _buildInput(controller: _emailController, hint: 'Email Address', icon: Icons.email_outlined),
                        const SizedBox(height: 16),
                        _buildInput(controller: _passwordController, hint: 'Password', icon: Icons.lock_outline, isPassword: true),
                        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _showResetPasswordSheet(context), child: Text('Forgot Password?', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)))),
                        const SizedBox(height: 24),
                        SizedBox(width: double.infinity, height: 58, child: ElevatedButton(onPressed: _isLoading ? null : _handleLogin, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ).animate().slideY(begin: 0.2, duration: 600.ms).fadeIn(),
                  const SizedBox(height: 32),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade600)), GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())), child: Text("Register Now", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)))]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return TextField(
      controller: controller, obscureText: isPassword && !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        prefixIcon: Icon(icon, color: const Color(0xFF1B4332).withOpacity(0.5)),
        suffixIcon: isPassword ? IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible)) : null,
        filled: true, fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1B4332), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
