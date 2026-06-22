import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/personal_info_page.dart';

class NotificationsListPage extends StatefulWidget {
  final String? manualUid;
  const NotificationsListPage({super.key, this.manualUid});

  @override
  State<NotificationsListPage> createState() => _NotificationsListPageState();
}

class _NotificationsListPageState extends State<NotificationsListPage> {
  Future<void> _handleClearAll(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isWelcomeCleared': true,
        'isAlertCleared': true, // To hide the incomplete profile dot as well
      });
    } catch (e) {
      debugPrint("Error clearing notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = widget.manualUid ?? user?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        bool isWelcomeCleared = false;
        bool isAlertCleared = false;
        bool isProfileIncomplete = false;

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          isWelcomeCleared = data['isWelcomeCleared'] ?? false;
          isAlertCleared = data['isAlertCleared'] ?? false;
          if (data['address'] == null || data['address'].toString().isEmpty) {
            isProfileIncomplete = true;
          }
        }

        List<Map<String, String>> currentNotifications = [];

        if (isProfileIncomplete && !isAlertCleared) {
          currentNotifications.add({
            'title': 'Incomplete Profile',
            'desc': 'Please update your address to facilitate restaurant discovery and delivery.',
            'time': 'Just now',
            'type': 'alert'
          });
        }

        if (!isWelcomeCleared) {
          currentNotifications.add({
            'title': 'Welcome',
            'desc': 'Thank you for joining HalalEats! Start exploring halal gems around you.',
            'time': '1 day ago',
            'type': 'info'
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            title: const Text('Notifications', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            actions: [
              if (currentNotifications.isNotEmpty)
                TextButton(
                  onPressed: () => _handleClearAll(currentUserId!),
                  child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                ),
            ],
          ),
          body: snapshot.connectionState == ConnectionState.waiting 
            ? const Center(child: CircularProgressIndicator())
            : currentNotifications.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: currentNotifications.length,
                  itemBuilder: (context, index) {
                    final item = currentNotifications[index];
                    return _buildNotificationItem(item, onTap: item['type'] == 'alert' 
                        ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalInfoPage(manualUid: currentUserId)))
                        : null);
                  },
                ),
        );
      }
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No notifications at the moment', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, String> item, {VoidCallback? onTap}) {
    IconData icon = item['type'] == 'alert' ? Icons.error_outline_rounded : Icons.info_outline_rounded;
    Color color = item['type'] == 'alert' ? Colors.redAccent : Colors.blue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(item['time']!, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
              const SizedBox(height: 4),
              Text(item['desc']!, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4)),
            ])),
          ],
        ),
      ),
    );
  }
}
