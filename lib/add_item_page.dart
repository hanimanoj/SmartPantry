import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'listitem.dart';
import 'snap_media.dart';
import 'dart:convert';
import 'topBar.dart';
import 'bottomBar.dart';

List<Map<String, dynamic>> pantryItems = [];

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();

  int _currentTabIndex = 1;

  int _quantity = 0;
  String? _selectedCategory;
  String? _uploadedImageUrl; // holds img pointer once returned

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
    
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(
              child: CircularProgressIndicator(),
            ),
      );

      try {
        await FirebaseFirestore.instance
            .collection('pantry_items')
            .add({
          'name': _nameController.text,
          'type': _typeController.text,
          'category': _selectedCategory,
          'quantity': _quantity,
          'expiryDate': _expiryController.text,
          'imageUrl': _uploadedImageUrl,
          'createdAt': Timestamp.now(),
          'userId': FirebaseAuth.instance.currentUser!.uid,
        });

        await FirebaseFirestore.instance
            .collection('activity_logs')
            .add({
              'name': _nameController.text,
              'action': 'Added to Pantry',
              'timestamp': FieldValue.serverTimestamp(),
              'details': null,
              'userId': FirebaseAuth.instance.currentUser!.uid,
            });

        Navigator.pop(context);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ItemListPage(),
          ),
        );

      } catch (e) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _expiryController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _navigateToCamera() async {
    final resultUrl = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const SnapItemPhotoScreen()),
    );

    if (resultUrl != null) {
      setState(() {
        _uploadedImageUrl = resultUrl; // Assigns URL to display/save state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCEDC8),
      appBar: const PantryTopBar(),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 20.0, top: 4.0),
                child: Center(
                  child: 
                    Text(
                    "Add Inventory Item",
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF386641),
                    ),
                  ),
                ),
              ),

              _uploadedImageUrl == null
                  ? OutlinedButton.icon(
                      onPressed: _navigateToCamera,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        side: BorderSide(color: Colors.green.shade700, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(Icons.camera_alt_outlined, color: Colors.green.shade700),
                      label: const Text(
                        "Add Picture",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF386641),),
                      ),
                    )
                  : Stack(
                      children: [
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.memory(
                              base64Decode(_uploadedImageUrl!),
                              fit: BoxFit.cover,
                              key: ValueKey(_uploadedImageUrl), 
                              gaplessPlayback: true, 
                            )
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _uploadedImageUrl = null;
                                });
                              },
                            ),
                          ),
                        )
                      ],
                    ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter item name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: "Type",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Dry Food", child: Text("Dry Food")),
                  DropdownMenuItem(value: "Beverage", child: Text("Beverage")),
                  DropdownMenuItem(value: "Fresh Products", child: Text("Fresh Products")),
                  DropdownMenuItem(value: "Frozen", child: Text("Frozen")),
                  DropdownMenuItem(value: "Protein", child: Text("Protein")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) =>
                    value == null || value.isEmpty ? "Please select a category" : null,
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    "Quantity:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        if (_quantity > 0) _quantity--;
                      });
                    },
                  ),
                  Text(
                    "$_quantity",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _expiryController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Expiry Date",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _pickDate(context),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _saveItem,
                    child: const Text("Save"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PantryBottomBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index; 
          });
        },
      ),
    );
  }
}
