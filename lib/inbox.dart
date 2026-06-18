import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'topbar.dart';
import 'bottombar.dart';
import 'dart:math';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {

  String _formatTimestamp(DateTime date, {bool isExactMidnight = true}) {
    final List<String> months = [
      "January", "February", "March", "April", "May", "June", 
      "July", "August", "September", "October", "November", "December"
    ];
    String monthWord = months[date.month - 1];
    String timeStr = isExactMidnight ? "00:01" : "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    return "${date.day} $monthWord, $timeStr";
  }

  String _formatLogTime(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    DateTime date = timestamp.toDate();
    return "${date.day} ${_getMonthWord(date.month)} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _getMonthWord(int monthIndex) {
    final List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "June", "July", "Aug", "Sept", "Oct", "Nov", "Dec"];
    return months[monthIndex - 1];
  }

  List<Map<String, dynamic>> _generateLiveRemindersFromDocs(List<QueryDocumentSnapshot> docs) {
    List<Map<String, dynamic>> liveReminders = [];
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    for (var doc in docs) {
      final item = doc.data() as Map<String, dynamic>;
      if (item['expiryDate'] == null || item['expiryDate'].toString().isEmpty) continue;

      try {
        DateTime expiryDate = DateTime.parse(item['expiryDate']);
        DateTime expiryNormalized = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
        int daysDifference = expiryNormalized.difference(today).inDays;
        
        String titleText = "";

        if (daysDifference < 0) {
          titleText = "${item['name'] ?? 'Item'} is past its expiry date.";
        } else if (daysDifference == 0) {
          titleText = "${item['name'] ?? 'Item'} expired today — please check.";
        } else if (daysDifference == 1) {
          titleText = "${item['name'] ?? 'Item'} expires tomorrow.";
        } else if (daysDifference == 3) {
          titleText = "${item['name'] ?? 'Item'} expire in 3 days.";
        } else if (daysDifference == 5) {
          titleText = "${item['name'] ?? 'Item'} expire in 5 days.";
        } else if (daysDifference == 7) {
          titleText = "${item['name'] ?? 'Item'} expire in 1 week.";
        } else {
          // If it doesn't match any reminder threshold, clear any old stored reminder timestamps if they exist
          if (item['reminderGeneratedAt'] != null) {
            FirebaseFirestore.instance.collection('pantry_items').doc(doc.id).update({
              'reminderGeneratedAt': FieldValue.delete(),
              'reminderRead': false, // Reset read state for when a new alert threshold hits later
            });
          }
          continue; 
        }

        // Look for an existing timestamp in Firestore
        String badgeTimestamp;
        if (item['reminderGeneratedAt'] != null) {
          // If Firestore already has the time saved, pull and format it directly
          DateTime storedTime = (item['reminderGeneratedAt'] as Timestamp).toDate();
          badgeTimestamp = _formatTimestamp(storedTime, isExactMidnight: false);
        } else {
          // If this is the exact moment the reminder came out, save it to Firestore
          badgeTimestamp = _formatTimestamp(now, isExactMidnight: false);
          
          FirebaseFirestore.instance.collection('pantry_items').doc(doc.id).update({
            'reminderGeneratedAt': FieldValue.serverTimestamp(),
          });
        }

        liveReminders.add({
          'id': doc.id,
          'title': titleText,
          'quantity': item['quantity'] ?? 1,
          'expiryDate': "${expiryNormalized.day}/${expiryNormalized.month}/${expiryNormalized.year}",
          'timestamp': badgeTimestamp, // Displays the exact recorded generation hour and minute
          'rawDays': daysDifference,
          'isRead': item['reminderRead'] ?? false,
        });
      } catch (e) {
        print("Error parsing date/updating reminder time: $e");
      }
    }
    liveReminders.sort((a, b) => a['rawDays'].compareTo(b['rawDays']));
    return liveReminders;
  }

  // RANDOM FRIENDLY NUDGES GENERATOR
  String _getRandomNudge(List<QueryDocumentSnapshot> pantryDocs) {
    if (pantryDocs.isEmpty) {
      return "Your pantry is looking empty! Time to add some groceries. 🛒";
    }

    List<String> itemNames = pantryDocs.map((d) => (d.data() as Map<String, dynamic>)['name']?.toString().toLowerCase() ?? '').toList();

    List<String> nudges = [
      "Our pantry is looking beautifully organized — nice work! ✨",
      "Keep up the clean kitchen streak! You're managing inventory like a pro. 🍏",
      "Waste less, enjoy more! Don't forget to check your upcoming reminders.",
    ];

    if (itemNames.any((name) => name.contains('bread') || name.contains('roti'))) {
      nudges.add("Hungry? You’ve got some breads ready in the pantry line! 🍞");
    }
    if (itemNames.any((name) => name.contains('milk') || name.contains('susu') || name.contains('cheese'))) {
      nudges.add("How about a cool glass of milk or a quick dairy snack? 🥛");
    }
    if (itemNames.any((name) => name.contains('snack') || name.contains('candy') || name.contains('chocolate'))) {
      nudges.add("Snack attack! Don't forget about those treats you saved. 🍫");
    }

    final random = Random(DateTime.now().minute);
    return nudges[random.nextInt(nudges.length)];
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF386641);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFDCEDC8),
        appBar: const PantryTopBar(), 
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: primaryGreen),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Text(
                    "Inbox",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen),
                  ),
                ],
              ),
            ),

            Container(
              color: Colors.white,
              child: const TabBar(
                indicatorColor: primaryGreen,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 3,
                labelColor: primaryGreen,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                unselectedLabelColor: Colors.grey,
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                tabs: [
                  Tab(text: "Reminders"),
                  Tab(text: "Notifications"),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                    .collection('pantry_items')
                    .where(
                      'userId',
                      isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                    )
                    .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      final computedReminders = _generateLiveRemindersFromDocs(docs);

                      if (computedReminders.isEmpty) {
                        return const Center(
                          child: Text("No current item expiry alerts.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: primaryGreen)),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: computedReminders.length,
                        itemBuilder: (context, index) {
                          final reminder = computedReminders[index];
                          bool isRead = reminder['isRead'];

                          return GestureDetector(
                            onTap: () async {
                              await FirebaseFirestore.instance
                                  .collection('pantry_items')
                                  .doc(reminder['id'])
                                  .update({'reminderRead': true});
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : const Color(0xFFFFFDE7), 
                                borderRadius: BorderRadius.circular(20),
                                border: isRead ? null : Border.all(color: Colors.amber.shade200, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(reminder['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 8),
                                  Text("Quantity: ${reminder['quantity']} item${reminder['quantity'] > 1 ? 's' : ''}", style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                                  const SizedBox(height: 4),
                                  Text("Expiry Date ${reminder['expiryDate']}", style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                                  const SizedBox(height: 4),
                                  Align(alignment: Alignment.bottomRight, child: Text(reminder['timestamp'], style: TextStyle(fontSize: 12, color: Colors.grey.shade500)))
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                    .collection('pantry_items')
                    .where(
                      'userId',
                      isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                    )
                    .snapshots(),
                    builder: (context, pantrySnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                        .collection('activity_logs')
                        .where(
                          'userId',
                          isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                        )
                        .orderBy('timestamp', descending: true)
                        .limit(20)
                        .snapshots(),
                        builder: (context, logSnapshot) {
                          if (logSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final pantryDocs = pantrySnapshot.data?.docs ?? [];
                          final logDocs = logSnapshot.data?.docs ?? [];
                          String dynamicNudge = _getRandomNudge(pantryDocs);

                          return ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: logDocs.length + 1, 
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14.0),
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9), 
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.green.shade200, width: 1)
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.wb_sunny_outlined, color: Colors.orange, size: 28),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          dynamicNudge,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final logDoc = logDocs[index - 1];
                              final logData = logDoc.data() as Map<String, dynamic>;
                              final String name = logData['name'] ?? 'Item';
                              final String action = logData['action'] ?? 'modified';
                              final String? details = logData['details'];
                              final Timestamp? logTime = logData['timestamp'] as Timestamp?;
                              
                              bool isRead = logData['isRead'] ?? false;

                              String notificationBody = "";
                              IconData notificationIcon = Icons.info_outline;
                              Color iconColor = Colors.blue;

                              if (action.contains('Added')) {
                                notificationBody = "Success! \"$name\" has been safely added to your digital pantry list shelf.";
                                notificationIcon = Icons.add_circle_outline;
                                iconColor = Colors.green.shade600;
                              } else if (action.contains('Deleted')) {
                                notificationBody = "Action Confirmation: \"$name\" was fully removed from your current inventory stock tracking sheet.";
                                notificationIcon = Icons.remove_circle_outline;
                                iconColor = Colors.red.shade600;
                              } else {
                                notificationBody = "Inventory Update: \"$name\" data changes were saved. ${details ?? ''}";
                                notificationIcon = Icons.edit_calendar_outlined;
                                iconColor = Colors.amber.shade800;
                              }

                              return GestureDetector(
                                onTap: () async {
                                  await FirebaseFirestore.instance
                                      .collection('activity_logs')
                                      .doc(logDoc.id)
                                      .update({'isRead': true});
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: isRead ? Colors.white : const Color(0xFFFFFDE7), 
                                    borderRadius: BorderRadius.circular(20),
                                    border: isRead ? null : Border.all(color: Colors.amber.shade200, width: 1),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(notificationIcon, color: iconColor, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              notificationBody,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                                            ),
                                            const SizedBox(height: 6),
                                            Align(
                                              alignment: Alignment.bottomRight,
                                              child: Text(
                                                _formatLogTime(logTime),
                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: PantryBottomBar(
          currentIndex: 0,
          onTap: (_) {},
        ),
      ),
    );
  }
}
