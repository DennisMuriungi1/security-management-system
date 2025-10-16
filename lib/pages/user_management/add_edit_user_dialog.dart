import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEditUserDialog extends StatefulWidget {
  final String? userId;
  final Map<String, dynamic>? userData;

  const AddEditUserDialog({super.key, this.userId, this.userData});

  @override
  State<AddEditUserDialog> createState() => _AddEditUserDialogState();
}

class _AddEditUserDialogState extends State<AddEditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _role = "student";
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      _emailController.text = widget.userData!['email'] ?? "";
      _nameController.text = widget.userData!['name'] ?? "";
      _phoneController.text = widget.userData!['phone'] ?? "";
      _role = widget.userData!['role'] ?? "student";
      _isActive = widget.userData!['isActive'] ?? true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.userId != null;
    return AlertDialog(
      title: Text(isEdit ? "Edit User" : "Add User"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEdit)
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                  validator: (val) => val!.contains('@') ? null : "Enter valid email",
                ),
              const SizedBox(height: 12),
              if (!isEdit)
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (val) => val!.length >= 6 ? null : "Min 6 chars",
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: "Role", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "admin", child: Text("Admin")),
                  DropdownMenuItem(value: "staff", child: Text("Staff")),
                  DropdownMenuItem(value: "security", child: Text("Security")),
                  DropdownMenuItem(value: "student", child: Text("Student")),
                ],
                onChanged: (val) => setState(() => _role = val!),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text("Active User"),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
              : Text(isEdit ? "Update" : "Create"),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (widget.userId != null) {
        // Update user
        await firestore.collection('users').doc(widget.userId).update({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'role': _role,
          'isActive': _isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create user
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        await firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': _emailController.text,
          'name': _nameController.text,
          'phone': _phoneController.text,
          'role': _role,
          'isActive': _isActive,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
