import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'topbar.dart';
import 'bottombar.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _currentTabIndex = 2; // History tab index tracker

  // Dropdown filter state variables
  String _selectedActionFilter = 'All';
  String _selectedYearFilter = '2026';

  // 🌟 SAFETY CHECK FLAG: Prevents the app from running an infinite re-render loop
  bool _hasCheckedExpiration = false; 

  // Helper method to convert database Timestamp format into your precise string layout
  String _formatCloudTimestamp(Timestamp? cloudTimestamp) {
    if (cloudTimestamp == null) return '-';
    DateTime dateTime = cloudTimestamp.toDate();
    
    List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'June', 
      'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'
    ];
    
    String day = dateTime.day.toString();
    String month = months[dateTime.month - 1];
    String year = dateTime.year.toString();
    
    int hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    if (hour == 0) hour = 12;
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return "$day $month $year, $hour.$minute $period";
  }

  @override
  void initState() {
    super.initState();
    // Scan and write expirations to the cloud logs exactly once when this page loads
    _checkAndLogExpiredItems();
  }

  // 🛠️ SAFE AUTO EXPIRED LOGGER ENGINE
  void _checkAndLogExpiredItems() async {
    if (_hasCheckedExpiration) return; // 👈 Safety shield: exits instantly if already processed
    _hasCheckedExpiration = true;

    DateTime today = DateTime.now();
    DateTime todayNormalized = DateTime(today.year, today.month, today.day);

    try {
      // Fetch active pantry items
      final pantrySnapshot = await FirebaseFirestore.instance
      .collection('pantry_items')
      .where(
        'userId',
        isEqualTo: FirebaseAuth.instance.currentUser!.uid,
      )
      .get();
      
      for (var doc in pantrySnapshot.docs) {
        final item = doc.data();
        if (item['expiryDate'] == null || item['expiryDate'].toString().isEmpty) continue;

        DateTime expiryDate = DateTime.parse(item['expiryDate']);
        DateTime expiryNormalized = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

        // If the item is past its expiration date, it belongs in the history log sheet
        if (expiryNormalized.isBefore(todayNormalized)) {
          String itemName = item['name'] ?? 'Unnamed Item';
          String expiryYearStr = expiryNormalized.year.toString();

          // Check if this specific item has already been marked 'Expired' in your log database
          final existingLogCheck = await FirebaseFirestore.instance
              .collection('activity_logs')
              .where('name', isEqualTo: itemName)
              .where('action', isEqualTo: 'Expired')
              .limit(1)
              .get();

          // If it hasn't been logged yet, commit it to Firestore!
          if (existingLogCheck.docs.isEmpty) {
            await FirebaseFirestore.instance.collection('activity_logs').add({
              'name': itemName,
              'action': 'Expired', 
              'timestamp': FieldValue.serverTimestamp(),
              'logYear': expiryYearStr, // 👈 Saved for streamlined, error-free filtering down below!
              'details': 'Item passed its target shelf date of ${item['expiryDate']}.',
              'userId': FirebaseAuth.instance.currentUser!.uid,
            });
          }
        }
      }
    } catch (e) {
      print("Error running expiration log validation: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF386641);

    // 🛠️ DYNAMIC FIRESTORE QUERY CONSTRUCTOR
    Query queryBase = FirebaseFirestore.instance
        .collection('activity_logs')
        .where(
          'userId',
          isEqualTo: FirebaseAuth.instance.currentUser!.uid,
        );

    // Filter A: Action filtering type mapping
    if (_selectedActionFilter != 'All') {
      queryBase = queryBase.where('action', isEqualTo: _selectedActionFilter);
    }

    // Filter B: Safe, high-performance year matching
    // For normal logs (Added/Updated/Deleted), it calculates boundaries by their true execution timestamp
    int selectedYearInt = int.parse(_selectedYearFilter);
    DateTime startOfYear = DateTime(selectedYearInt, 1, 1);
    DateTime endOfYear = DateTime(selectedYearInt, 12, 31, 23, 59, 59);
    
    queryBase = queryBase
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear));

    // Order results chronologically so newest actions stay at the top card slot
    queryBase = queryBase.orderBy('timestamp', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFFDCEDC8),
      appBar: const PantryTopBar(showNotificationIcon: true),

      body: Column(
        children: [
          // Sub-Header Title Line
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: const Center(
              child: Text(
                "History",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen),
              ),
            ),
          ),

          // Dropdown Filter Controls Row Layout Container
          Container(
            padding: const EdgeInsets.only(right: 16.0, bottom: 8.0, left: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Action Filter Dropdown Box
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedActionFilter,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedActionFilter = newValue!;
                        });
                      },
                      items: <String>['All', 'Added to Pantry', 'Updated', 'Deleted from Pantry', 'Expired']
                          .map<DropdownMenuItem<String>>((String value) {
                        String displayLabel = value;
                        if (value == 'Added to Pantry') displayLabel = 'Added';
                        if (value == 'Deleted from Pantry') displayLabel = 'Deleted';
                        
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(displayLabel),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Calendar Year Filter Dropdown Box
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedYearFilter,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedYearFilter = newValue!;
                        });
                      },
                      items: <String>['2026', '2025', '2024']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Real-time Cloud Streaming List Output View Frame
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: queryBase.snapshots(), 
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading history: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final logsDocs = snapshot.data?.docs ?? [];

                if (logsDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No historical logs found.",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  itemCount: logsDocs.length,
                  separatorBuilder: (context, index) => Divider(
                    color: primaryGreen.withValues(alpha: 0.3),
                    height: 24,
                    thickness: 1,
                  ),
                  itemBuilder: (context, index) {
                    final log = logsDocs[index].data() as Map<String, dynamic>;
                    
                    final String itemName = log['name'] ?? 'Unknown Item';
                    final String itemAction = log['action'] ?? 'Processed';
                    final String? itemDetails = log['details'];
                    final Timestamp? logTimestamp = log['timestamp'] as Timestamp?;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                            children: [
                              TextSpan(
                                text: "$itemName — ",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: itemAction,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "on ${_formatCloudTimestamp(logTimestamp)}",
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                        if (itemDetails != null && itemDetails.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            itemDetails,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
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