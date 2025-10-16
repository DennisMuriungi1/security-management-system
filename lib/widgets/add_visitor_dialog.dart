// add_visitor_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddVisitorDialog extends StatefulWidget {
  final String addedBy; // pass user role (admin/security/etc)

  const AddVisitorDialog({Key? key, required this.addedBy}) : super(key: key);

  @override
  State<AddVisitorDialog> createState() => _AddVisitorDialogState();
}

class _AddVisitorDialogState extends State<AddVisitorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _personToVisitController = TextEditingController();
  String _selectedPurpose = 'Business Meeting';

  final List<String> _purposeOptions = [
    'Business Meeting',
    'Interview',
    'Delivery',
    'Maintenance',
    'Personal Visit',
    'Other'
  ];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _personToVisitController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Create doc ref so we get the auto-generated ID
      final docRef = FirebaseFirestore.instance.collection('visitors').doc();

      await docRef.set({
        'id': docRef.id, // store the generated document ID inside the record
        'name': _nameController.text.trim(),
        'company': _companyController.text.trim(),
        'personToVisit': _personToVisitController.text.trim(),
        'purpose': _selectedPurpose,
        'checkIn': Timestamp.fromDate(DateTime.now()),
        'checkOut': null,
        'status': 'Checked In',
        'photoUrl': null,
        'addedBy': widget.addedBy,
        'createdAt': FieldValue.serverTimestamp(), // server-side timestamp
      });

      Navigator.of(context).pop(true); // success
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add visitor: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add New Visitor',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter visitor name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(
                        labelText: 'Company',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _personToVisitController,
                      decoration: const InputDecoration(
                        labelText: 'Person to Visit *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please specify who they are visiting'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedPurpose,
                      decoration: const InputDecoration(
                        labelText: 'Purpose of Visit *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      items: _purposeOptions
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedPurpose = v ?? _selectedPurpose),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel')),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Add Visitor'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
