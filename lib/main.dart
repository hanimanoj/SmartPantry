import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'topbar.dart';
import 'bottombar.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'add_item_page.dart';
import 'login_page.dart';

void main() async {
  // Ensure Flutter bindings are initialized before Firebase setup
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase connection
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Launch application
  runApp(const SmartPantryApp());
}

class SmartPantryApp extends StatelessWidget {
  const SmartPantryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Main application configuration
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Pantry',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),

      // First screen displayed when app starts
      home: const LoginPage(), 
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get currently logged-in Firebase user
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF4E1),

      appBar: PantryTopBar(),
      
      // Real-time Firestore listener for user's pantry items
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
              .collection('pantry_items')
              // Filter items based on logged-in user ID
              .where(
                'userId',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final items = snapshot.data!.docs;
          final sortedItems = [...items];
          
          // Sort pantry items by expiry date (nearest expiry first)
          sortedItems.sort((a, b) {
            try {
              final expiryA = DateTime.parse(a['expiryDate']);
              final expiryB = DateTime.parse(b['expiryDate']);

              return expiryA.compareTo(expiryB);
            } catch (e) {
              return 0;
            }
          });

          final totalItems = items.length;

          final now = DateTime.now();
          int freshCount = 0;
          int expiringCount = 0;
          int expiredCount = 0;
          
          // Calculate item status based on expiry date
          for (var doc in items) {
            try {
              final expiry = DateTime.parse(doc['expiryDate']);
              final diff = expiry.difference(now).inDays;

              if (diff > 7) {
                freshCount++;
              } else if (diff >= 0) {
                expiringCount++;
              } else {
                expiredCount++;
              }
            } catch (_) {}
          }

          // Count items that will expire within 7 days
          final expiringSoon = items.where((doc) {
            try {
              final expiry = DateTime.parse(doc['expiryDate']);
              final diff = expiry.difference(now).inDays;

              return diff >= 0 && diff <= 7;
            } catch (e) {
              return false;
            }
          }).length;

          // Count items added during current month
          final addedThisMonth = items.where((doc) {
            try {
              final Timestamp ts = doc['createdAt'];
              final date = ts.toDate();

              return date.month == now.month &&
                  date.year == now.year;
            } catch (e) {
              return false;
            }
          }).length;

          // Count total items per category
          Map<String, int> categoryCounts = {};
        
          for (var doc in items) {
            final category = doc['category'] ?? 'Unknown';

            categoryCounts[category] =
                (categoryCounts[category] ?? 0) + 1;
          }

          // Retrieve items expiring within 7 days
          final expiringItems = sortedItems.where((doc) {
            try {
              final expiry = DateTime.parse(doc['expiryDate']);
              final diff = expiry.difference(now).inDays;
              return diff >= 0 && diff <= 7;
            } catch (_) {
              return false;
            }
          }).toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hi, ${user?.displayName ?? "User"} 👋",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F6B4F),
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "Welcome back to SmartPantry",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Expiring Soon Features for items nearing expiry
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "Expiring Soon",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2F6B4F),
                          ),
                        ),

                        SizedBox(height: 15),

                        SizedBox(
                          height: 160,
                          child: expiringItems.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "No items expiring soon",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Items nearing expiry will appear here.",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: expiringItems.map((doc) {

                                    final expiry = DateTime.parse(doc['expiryDate']);
                                    final diff = expiry.difference(now).inDays;

                                    return Container(
                                      width: 130,
                                      margin: const EdgeInsets.only(right: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (doc['imageUrl'] != null &&
                                              doc['imageUrl'].toString().isNotEmpty)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),

                                              // Decode Base64 image stored in Firestore
                                              child: Image.memory(
                                                base64Decode(doc['imageUrl']),
                                                width: 70,
                                                height: 70,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          else
                                            const Icon(Icons.inventory_2, size: 60),

                                          const SizedBox(height: 8),

                                          Text(
                                            doc['name'].toString().substring(0, 1).toUpperCase() +
                                                doc['name'].toString().substring(1),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          // Display remaining days before item expires
                                          Text(
                                            diff == 0
                                                ? "Today"
                                                : "$diff day${diff == 1 ? '' : 's'} left",
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // PANTRY SUMMARY
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "Pantry Summary",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2F6B4F),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // KPI Cards showing pantry statistics
                        Row(
                          children: [
                            Expanded(
                              child: KPIcard(
                                title: "Total Items",
                                value: totalItems.toString(),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: KPIcard(
                                title: "Expiring Soon",
                                value: expiringSoon.toString(),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: KPIcard(
                                title: "Added This Month",
                                value: addedThisMonth.toString(),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        SizedBox(
                          height: 320,
                          child: Row(
                            children: [

                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [

                                    // PANTRY HEALTH SCORE
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F5F5),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [

                                            const Text(
                                              "Pantry Health",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            // Calculate percentage of healthy (fresh) items
                                            Text(
                                              "${((freshCount / (totalItems == 0 ? 1 : totalItems)) * 100).round()}%",
                                              style: const TextStyle(
                                                fontSize: 30,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2F6B4F),
                                              ),
                                            ),

                                            const SizedBox(height: 5),

                                            const Text(
                                              "Healthy Items",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    // Visualize item status distribution
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F5F5),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [

                                            Expanded(
                                              child: PieChart(
                                                PieChartData(
                                                  centerSpaceRadius: 15,
                                                  sectionsSpace: 2,
                                                  sections: [
                                                    PieChartSectionData(
                                                      value: freshCount.toDouble(),
                                                      color: Colors.green,
                                                      title: freshCount.toString(),
                                                      radius: 25,
                                                    ),
                                                    PieChartSectionData(
                                                      value: expiringCount.toDouble(),
                                                      color: Colors.orange,
                                                      title: expiringCount.toString(),
                                                      radius: 25,
                                                    ),
                                                    PieChartSectionData(
                                                      value: expiredCount.toDouble(),
                                                      color: Colors.red,
                                                      title: expiredCount.toString(),
                                                      radius: 25,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 6),

                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child:Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [

                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: const [
                                                      Icon(Icons.circle, size: 6, color: Colors.green),
                                                      SizedBox(width: 3),
                                                      Text("Fresh", style: TextStyle(fontSize: 8)),
                                                    ],
                                                  ),

                                                  SizedBox(height: 2),

                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: const [
                                                      Icon(Icons.circle, size: 6, color: Colors.orange),
                                                      SizedBox(width: 3),
                                                      Text("Soon", style: TextStyle(fontSize: 8)),
                                                    ],
                                                  ),

                                                  SizedBox(height: 2),

                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: const [
                                                      Icon(Icons.circle, size: 6, color: Colors.red),
                                                      SizedBox(width: 3),
                                                      Text("Expired", style: TextStyle(fontSize: 8)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(width: 10),

                              // Display number of items in each category
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: (categoryCounts.values.isEmpty)
                                          ? 5
                                          : categoryCounts.values.reduce((a, b) => a > b ? a : b).toDouble() + 1,

                                      titlesData: FlTitlesData(
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),

                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),

                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 1,
                                            reservedSize: 25,
                                          ),
                                        ),

                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 45,
                                            getTitlesWidget: (value, meta) {
                                              final categories = categoryCounts.keys.toList();

                                              if (value.toInt() >= categories.length) {
                                                return const SizedBox();
                                              }

                                              return Padding(
                                                padding: const EdgeInsets.only(top: 6),
                                                child: SizedBox(
                                                  width: 25,
                                                  child: RotatedBox(
                                                    quarterTurns: 3,
                                                    child: Text(
                                                      categories[value.toInt()],
                                                      style: const TextStyle(fontSize: 8),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),

                                      borderData: FlBorderData(show: false),

                                      // Dynamically generate bars from category data
                                      barGroups: List.generate(
                                        categoryCounts.length,
                                        (index) {
                                          return BarChartGroupData(
                                            x: index,
                                            barRods: [
                                              BarChartRodData(
                                                toY: categoryCounts.values.elementAt(index).toDouble(),
                                                width: 14,
                                                borderRadius: BorderRadius.circular(4),
                                                color: const Color(0xFF2F6B4F),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to Add Item page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddItemPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add New Item"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F6B4F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: PantryBottomBar(
        currentIndex: 0,
        onTap: (index) {
          print("Tapped: $index");
        },
      ),
    );
  }
}

class KPIcard extends StatelessWidget {
  final String title;
  final String value;

  const KPIcard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F6B4F),
            ),
          ),
          Text(title),
        ],
      ),
    );
  }
}