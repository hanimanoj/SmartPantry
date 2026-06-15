import 'package:flutter/material.dart';
import 'inbox.dart';

class PantryTopBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showNotificationIcon;
  
  const PantryTopBar({
    super.key,
    this.showNotificationIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,

      title: Row(
        children: [
          Image.asset(
            'assets/images/applogo.png',
            height: 40,
            width: 40,
          ),

          const SizedBox(width: 10),

          const Text(
            "SmartPantry Tracker",
            style: TextStyle(
              color: Color(0xFF2F6B4F),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),

      actions: showNotificationIcon
    ? [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InboxPage(),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black,
            ),
          ),
        ),
      ]
    : [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}