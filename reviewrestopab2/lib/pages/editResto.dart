import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditRestoPage extends StatefulWidget {
  final DocumentSnapshot resto; // The resto document to edit

  const EditRestoPage({super.key, required this.resto});

  @override
  _EditRestoPageState createState() => _EditRestoPageState();
}

class _EditRestoPageState extends State<EditRestoPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imagelinkController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mapsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize the controllers with the current resto data
    _nameController.text = widget.resto['name'];
    _descriptionController.text = widget.resto['description'];
    _imagelinkController.text = widget.resto['image'];
    _addressController.text = widget.resto['address'];
    _mapsController.text = widget.resto['maps'];
  }

  Future<void> _updateResto(BuildContext context) async {
    // Update resto in Firestore
    await FirebaseFirestore.instance.collection('resto').doc(widget.resto.id).update({
      'name': _nameController.text,
      'description': _descriptionController.text,
      'image': _imagelinkController.text,
      'address': _addressController.text,
      'maps': _mapsController.text,
    });
    // Navigate back to home page
    Navigator.pushNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Resto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Resto Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _mapsController,
              decoration: const InputDecoration(labelText: 'Maps link'),
            ),
            TextField(
              controller: _imagelinkController,
              decoration: const InputDecoration(labelText: 'Image link'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address link'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _updateResto(context), // Pass context here
              child: const Text('Update Resto', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }
}