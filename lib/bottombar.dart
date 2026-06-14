import 'package:flutter/material.dart';
import 'main.dart';
import 'listitem.dart';
import 'history.dart';
import 'profile_page.dart';

class PantryBottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PantryBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<PantryBottomBar> createState() => _PantryBottomBarState();
}

class _PantryBottomBarState extends State<PantryBottomBar> {
  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF386641);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: (index) {
          // 1. Call the original parent function to update the active UI highlight state
          widget.onTap(index);

          // 2. If the user clicks the tab they are already viewing, do nothing
          if (index == widget.currentIndex) return;

          // 3. Jump to the selected page based on the icon position index clicked
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardPage()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ItemListPage()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
              break;
          }
        },
        type: BottomNavigationBarType.fixed, 
        backgroundColor: Colors.white,
        selectedItemColor: themeColor,
        unselectedItemColor: themeColor.withValues(alpha: 0.5), 
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined), 
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_toggle_off_rounded), 
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}