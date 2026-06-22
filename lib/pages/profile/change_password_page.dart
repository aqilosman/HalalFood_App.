import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangePasswordPage extends StatefulWidget {
  final String? manualUid; // NEW: Support bypass login
  const ChangePasswordPage({super.key, this.manualUid});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Change Password', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Protect your account with a strong password.', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 32),
              _buildField(_currentController, 'Current Password'),
              const SizedBox(height: 20),
              _buildField(_newController, 'New Password'),
              const SizedBox(height: 20),
              _buildField(_confirmController, 'Confirm New Password'),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      obscureText: true,
      validator: (v) {
        if (v == null || v.isEmpty) return 'This field is required';
        if (ctrl == _confirmController && v != _newController.text) return 'Passwords do not match';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B4332), width: 2),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authUser = FirebaseAuth.instance.currentUser;
      final currentUserId = widget.manualUid ?? authUser?.uid;

      if (currentUserId == null) throw 'User session error';

      // 1. Dapatkan data user dari Firestore untuk semak password lama (Master check)
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) throw 'User document not found';
      
      final userData = userDoc.data()!;
      final savedPass = userData['customPassword'] ?? "";

      // 2. Semak jika password lama betul mengikut rekod Firestore
      if (_currentController.text != savedPass) {
        throw 'Current password is incorrect';
      }

      // 3. Update Firebase Auth (Jika ada session aktif)
      if (authUser != null) {
        try {
          final cred = EmailAuthProvider.credential(email: authUser.email!, password: _currentController.text);
          await authUser.reauthenticateWithCredential(cred);
          await authUser.updatePassword(_newController.text.trim());
        } catch (authError) {
          // Jika gagal update Auth (mungkin password sedia ada berbeza), kita abaikan 
          // dan teruskan update Firestore sebagai Master.
          debugPrint("Auth sync skipped: $authError");
        }
      }
      
      // 4. Update Firestore - Ini adalah Master Password yang akan disemak semasa Login
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'customPassword': _newController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: Color(0xFF1B4332),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
