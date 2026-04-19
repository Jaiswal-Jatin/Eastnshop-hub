
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../Constants/GlobalVariables.dart';
import '../../../Utils/ApiService.dart';
import '../../DrawerScreen.dart';
import '../../Userpanel/Customappbar.dart';
import '../AdminDashboard/HomePage.dart';

class ShopkeeperNotificationScreen extends StatefulWidget {
  const ShopkeeperNotificationScreen({super.key});

  @override
  State<ShopkeeperNotificationScreen> createState() =>
      _ShopkeeperNotificationScreenState();
}

class _ShopkeeperNotificationScreenState
    extends State<ShopkeeperNotificationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get(
        '/api/notifications/my',
        includeAuth: true,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          final mapped = decoded
              .whereType<Map>()
              .map((item) => _mapNotification(item.cast<String, dynamic>()))
              .toList();

          setState(() {
            _notifications = mapped;
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _errorMessage = 'Invalid notifications response format';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _errorMessage = 'Failed to load notifications (${response.statusCode})';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load notifications: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _mapNotification(Map<String, dynamic> item) {
    final type = (item['type'] ?? '').toString().toLowerCase();
    final isRead = (item['is_read'] ?? 0).toString() == '1';

    return {
      'id': item['id'],
      'title': (item['title'] ?? '').toString(),
      'subtitle': (item['message'] ?? '').toString(),
      'time': _formatRelativeTime((item['created_at'] ?? '').toString()),
      'icon': _iconNameFromType(type),
      'color': _colorFromType(type),
      'isRead': isRead,
    };
  }

  String _iconNameFromType(String type) {
    switch (type) {
      case 'offer':
        return 'local_offer';
      case 'order':
        return 'shopping_cart';
      case 'support':
      case 'ticket':
        return 'support_agent';
      case 'account':
        return 'verified_user';
      default:
        return 'notifications';
    }
  }

  Color _colorFromType(String type) {
    switch (type) {
      case 'offer':
        return Colors.red;
      case 'order':
        return Colors.blue;
      case 'support':
      case 'ticket':
        return Colors.orange;
      case 'account':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  String _formatRelativeTime(String createdAt) {
    if (createdAt.isEmpty) return '';

    try {
      final created = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(created);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays} days ago';
    } catch (_) {
      return createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => globalUser.value == true ? HomePage() : HomePage(),
          ),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: const CustomAppBarWithDrawer(),
        drawer: const DrawerScreen(),
        body: Column(
          children: [
            // Modern Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => globalUser.value == true ? HomePage() : HomePage(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${_notifications.where((n) => n['isRead'] == false).length}",
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Notifications List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _fetchNotifications,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _notifications.isEmpty
                  ? const Center(
                      child: Text(
                        'No notifications found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        return _buildNotificationCard(notif, context);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif, BuildContext context) {
    final isRead = notif['isRead'] as bool;
    final color = notif['color'] as Color;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Handle notification tap
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(notif['icon'] ?? ''),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif['title'] ?? '',
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif['subtitle'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notif['time'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow Icon
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'local_offer':
        return Icons.local_offer_outlined;
      case 'support_agent':
        return Icons.support_agent_outlined;
      case 'verified_user':
        return Icons.verified_user_outlined;
      case 'notifications':
        return Icons.notifications_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
