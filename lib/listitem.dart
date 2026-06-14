import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_item_page.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'topBar.dart';
import 'bottomBar.dart';

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  int _currentTabIndex = 1;
  String? editingDocId;
  int tempQuantity = 0;

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, String itemName) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirm Deletion',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C5E3B)),
          ),
          content: Text('Are you sure you want to remove "$itemName" from your pantry inventory?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _deleteItemFromCloud(String docId, String itemName) async {
    try {
      await FirebaseFirestore.instance.collection('activity_logs').add({
        'name': itemName,
        'action': 'Deleted from Pantry',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'details': null,
      });

      await FirebaseFirestore.instance.collection('pantry_items').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$itemName removed from inventory.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  Future<bool?> _showEditConfirmationDialog(
    BuildContext context,
    String itemName,
    int oldQty,
    int newQty,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Confirm Quantity Change',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C5E3B),
            ),
          ),
          content: Text(
            'Update quantity for "$itemName" from $oldQty to $newQty?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF386641),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Update',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
  
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDCEDC8),
      appBar: const PantryTopBar(),
      body: Column(
        children: [
          const Padding(
                padding: EdgeInsets.only(top:10.0),
                child: Center(
                  child: 
                    Text(
                    "Pantry Items",
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF386641),
                    ),
                  ),
                ),
              ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pantry_items')
                  .orderBy('expiryDate', descending: false)
                  .where(
                    'userId',
                    isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: 
                    Text('Something went wrong: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: 
                    CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No items saved yet.",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    final doc = docs[index];

                    final item =
                        docs[index].data() as Map<String, dynamic>;
                    final originalQty = item['quantity'] ?? 0;
                    final isEditing = editingDocId == doc.id;
                    
                    final hasImage =
                        item['imageUrl'] != null &&
                        item['imageUrl'].toString().isNotEmpty;

                    Uint8List? imageBytes;

                    if (hasImage) {
                      imageBytes = base64Decode(item['imageUrl']);
                    }
                    bool isExpired = false;

                    try {
                      final expiryDate = DateTime.parse(
                        item['expiryDate'] ?? '',
                      );

                      final today = DateTime.now();

                      isExpired = expiryDate.isBefore(
                        DateTime(today.year, today.month, today.day),
                      );
                    } catch (_) {}

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,

                      confirmDismiss: (direction) async {
                        return await _showDeleteConfirmationDialog(
                          context,
                          item['name'] ?? 'Unnamed',
                        );
                      },

                      onDismissed: (direction) {
                        _deleteItemFromCloud(
                          doc.id,
                          item['name'] ?? 'Unnamed',
                        );
                      },

                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      child: Card(   
                        color: Colors.white,
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(11),
                                  child: hasImage
                                      ? Image.memory(
                                          imageBytes!,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(
                                          Icons.restaurant,
                                        ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [

                                        Expanded(
                                          child: Text(
                                            (item['name'] ?? 'Unnamed')
                                                .toString()
                                                .substring(0, 1)
                                                .toUpperCase() +
                                            (item['name'] ?? 'Unnamed')
                                                .toString()
                                                .substring(1),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2C5E3B),
                                            ),
                                          ),
                                        ),

                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 22,
                                          ),
                                          onPressed: () async {
                                            bool? confirm =
                                                await _showDeleteConfirmationDialog(
                                              context,
                                              item['name'] ?? 'Unnamed',
                                            );

                                            if (confirm == true) {
                                              _deleteItemFromCloud(
                                                doc.id,
                                                item['name'] ?? 'Unnamed',
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    const SizedBox(height: 6),

                                    Table(
                                      columnWidths: const {
                                        0: IntrinsicColumnWidth(),
                                        1: FlexColumnWidth(),
                                      },
                                      defaultVerticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      children: [

                                        TableRow(
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(bottom: 4),
                                              child: Text(
                                                "Type: ",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              item['type'] ?? '-',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),

                                        TableRow(
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(bottom: 4),
                                              child: Text(
                                                "Category: ",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              item['category'] ?? '-',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),

                                        TableRow(
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(bottom: 4),
                                              child: Text(
                                                "Quantity: ",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),

                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [

                                                if (isEditing && !isExpired) ...[

                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.remove_circle_outline,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    onPressed: () {
                                                      if (tempQuantity > 0) {
                                                        setState(() {
                                                          tempQuantity--;
                                                        });
                                                      }
                                                    },
                                                  ),

                                                  Text(
                                                    "$tempQuantity",
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),

                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.add_circle_outline,
                                                      color: Colors.green,
                                                      size: 20,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    onPressed: () {
                                                      setState(() {
                                                        tempQuantity++;
                                                      });
                                                    },
                                                  ),

                                                  GestureDetector(
                                                    onTap: () async {

                                                      bool? confirm =
                                                          await _showEditConfirmationDialog(
                                                        context,
                                                        item['name'],
                                                        originalQty,
                                                        tempQuantity,
                                                      );

                                                      if (confirm == true) {

                                                        await FirebaseFirestore.instance
                                                            .collection('pantry_items')
                                                            .doc(doc.id)
                                                            .update({
                                                          'quantity': tempQuantity,
                                                        });

                                                        await FirebaseFirestore.instance
                                                          .collection('activity_logs')
                                                          .add({
                                                        'name': item['name'],
                                                        'action': 'Updated',
                                                        'timestamp': FieldValue.serverTimestamp(),
                                                        'userId': FirebaseAuth.instance.currentUser!.uid,
                                                        'details':
                                                            'Quantity changed from $originalQty to $tempQuantity',
                                                      });

                                                        setState(() {
                                                          editingDocId = null;
                                                        });
                                                      }
                                                    },

                                                    child: const Text(
                                                      "Done",
                                                      style: TextStyle(
                                                        color: Colors.blue,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),

                                                ] else ...[

                                                  Text(
                                                    "$originalQty",
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),

                                                  if (!isExpired) ...[
                                                    const SizedBox(width: 12),

                                                    GestureDetector(
                                                      onTap: () async {

                                                        int tempQty = item['quantity'] ?? 0;

                                                        await showDialog(
                                                          context: context,
                                                          builder: (context) {
                                                            return StatefulBuilder(
                                                              builder: (context, setDialogState) {

                                                                return AlertDialog(
                                                                  title: const Text("Edit Quantity"),

                                                                  content: Row(
                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                    children: [

                                                                      IconButton(
                                                                        icon: const Icon(
                                                                          Icons.remove_circle_outline,
                                                                          color: Colors.red,
                                                                        ),
                                                                        onPressed: () {
                                                                          if (tempQty > 0) {
                                                                            setDialogState(() {
                                                                              tempQty--;
                                                                            });
                                                                          }
                                                                        },
                                                                      ),

                                                                      Text(
                                                                        "$tempQty",
                                                                        style: const TextStyle(
                                                                          fontSize: 20,
                                                                          fontWeight: FontWeight.bold,
                                                                        ),
                                                                      ),

                                                                      IconButton(
                                                                        icon: const Icon(
                                                                          Icons.add_circle_outline,
                                                                          color: Colors.green,
                                                                        ),
                                                                        onPressed: () {
                                                                          setDialogState(() {
                                                                            tempQty++;
                                                                          });
                                                                        },
                                                                      ),
                                                                    ],
                                                                  ),

                                                                  actions: [

                                                                    TextButton(
                                                                      onPressed: () {
                                                                        Navigator.pop(context);
                                                                      },
                                                                      child: const Text("Cancel"),
                                                                    ),

                                                                    ElevatedButton(
                                                                      onPressed: () async {

                                                                        await FirebaseFirestore.instance
                                                                            .collection('pantry_items')
                                                                            .doc(doc.id)
                                                                            .update({
                                                                          'quantity': tempQty,
                                                                        });

                                                                        await FirebaseFirestore.instance
                                                                            .collection('activity_logs')
                                                                            .add({
                                                                          'name': item['name'],
                                                                          'action': 'Updated',
                                                                          'timestamp': FieldValue.serverTimestamp(),
                                                                          'details':
                                                                              'Quantity changed from ${item['quantity']} to $tempQty',
                                                                        });

                                                                        Navigator.pop(context);

                                                                        ScaffoldMessenger.of(context)
                                                                            .showSnackBar(
                                                                          SnackBar(
                                                                            content: Text(
                                                                              '${item['name']} quantity updated.',
                                                                            ),
                                                                          ),
                                                                        );
                                                                      },
                                                                      child: const Text("Save"),
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            );
                                                          },
                                                        );
                                                      },

                                                      child: const Text(
                                                        "Edit",
                                                        style: TextStyle(
                                                          color: Color(0xFF2C5E3B),
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          decoration: TextDecoration.underline,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),

                                        TableRow(
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(bottom: 4),
                                              child: Text(
                                                "Expiry: ",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              item['expiryDate'] ?? '-',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isExpired
                                                    ? Colors.red.shade700
                                                    : Colors.black87,
                                                fontWeight: isExpired
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
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
                  },
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AddItemPage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
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