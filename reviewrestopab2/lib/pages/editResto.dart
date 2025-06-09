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

  