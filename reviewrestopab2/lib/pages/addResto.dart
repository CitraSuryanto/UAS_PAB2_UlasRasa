import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddRestoPage extends StatefulWidget {
  const AddRestoPage({super.key});

  @override
  State<AddRestoPage> createState() => _AddRestoPageState();
}

class _AddRestoPageState extends State<AddRestoPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imagelinkController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mapsController = TextEditingController();

  late String userRole;
  late String userId;
  late String userName;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _addResto(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('resto').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image': _imagelinkController.text.trim(),
        'address': _addressController.text.trim(),
        'maps': _mapsController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resto berhasil ditambahkan!')),
      );

      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: {
          'userRole': userRole,
          'userId': userId,
          'userName': userName,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan resto: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {
        'userRole': userRole,
        'userId': userId,
        'userName': userName,
      },
    );
    return false; // jangan pop otomatis, karena sudah manual navigate
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text('Tambah Resto')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTextField(_nameController, 'Nama Resto'),
                    _buildTextField(_descriptionController, 'Deskripsi'),
                    _buildTextField(_mapsController, 'Link Google Maps'),
                    _buildTextField(_imagelinkController, 'Link Gambar'),
                    _buildTextField(_addressController, 'Alamat'),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _addResto(context),
                        icon: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Icon(Icons.add_location_alt_outlined, color: Colors.white),
                        label: Text(
                          _isLoading ? 'Menyimpan...' : 'Tambah Resto',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.deepPurple),
          ),
        ),
        validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
      ),
    );
  }
}
