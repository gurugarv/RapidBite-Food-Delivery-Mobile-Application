import 'package:flutter/material.dart';
import 'package:rapidbite/database/database_helper.dart';
import 'dart:async';

class OwnerNotificationsPage extends StatefulWidget {
  final String restaurantName;

  const OwnerNotificationsPage({Key? key, required this.restaurantName}) : super(key: key);

  @override
  _OwnerNotificationsPageState createState() => _OwnerNotificationsPageState();
}

class _OwnerNotificationsPageState extends State<OwnerNotificationsPage>
    with SingleTickerProviderStateMixin {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  Timer? _notificationCheckTimer;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _loadNotifications();
    _animationController.forward();

    // Check for new notifications every 5 seconds
    _notificationCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkForNewNotifications();
    });
  }

  @override
  void dispose() {
    _notificationCheckTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkForNewNotifications() async {
    final newNotifications = await dbHelper.getUnreadNotificationsForRestaurant(widget.restaurantName);

    if (newNotifications.isNotEmpty && mounted) {
      _loadNotifications();

      // Show popup for first unread notification
      final firstNotification = newNotifications.first;
      _showNewOrderPopup(firstNotification);
    }
  }

  void _showNewOrderPopup(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.red.shade500],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'New Order!',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['message'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag, color: Colors.deepOrange),
                  const SizedBox(width: 12),
                  Text(
                    'Order #${notification['order_id']}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              notification['created_at'],
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _markAsRead(notification['id']);
                    await dbHelper.updateOrderStatus(notification['order_id'], 'Cancelled');
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order rejected'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _markAsRead(notification['id']);
                    await dbHelper.updateOrderStatus(notification['order_id'], 'Accepted');
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      '/owner_orders',
                      arguments: widget.restaurantName,
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadNotifications() async {
    final data = await dbHelper.getNotificationsForRestaurant(widget.restaurantName);
    if (mounted) {
      setState(() {
        notifications = data;
        isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    await dbHelper.markNotificationAsRead(notificationId);
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    await dbHelper.markAllNotificationsAsRead(widget.restaurantName);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('All notifications marked as read'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _loadNotifications();
  }

  Future<void> _viewOrderDetails(int orderId) async {
    final order = await dbHelper.getOrder(orderId);
    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order not found')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/owner_orders',
      arguments: widget.restaurantName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => n['read'] == 0).length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade300, Colors.red.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$unreadCount unread',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (unreadCount > 0)
                      TextButton.icon(
                        onPressed: _markAllAsRead,
                        icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
                        label: const Text(
                          'Mark All',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadNotifications,
                    ),
                  ],
                ),
              ),

              // Notifications List
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : notifications.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 20),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                      : FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          final isRead = notification['read'] == 1;

                          return TweenAnimationBuilder(
                            duration: Duration(milliseconds: 300 + (index * 50)),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: !isRead
                                    ? Border.all(
                                  color: Colors.deepOrange,
                                  width: 2,
                                )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: isRead
                                        ? Colors.grey.withOpacity(0.2)
                                        : Colors.orange.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    if (!isRead) {
                                      _markAsRead(notification['id']);
                                    }
                                    _viewOrderDetails(notification['order_id']);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isRead
                                                  ? [Colors.grey.shade300, Colors.grey.shade400]
                                                  : [Colors.orange.shade400, Colors.red.shade500],
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.shopping_bag,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                notification['message'],
                                                style: TextStyle(
                                                  fontWeight: isRead
                                                      ? FontWeight.normal
                                                      : FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.receipt,
                                                    size: 14,
                                                    color: Colors.blue.shade700,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Order #${notification['order_id']}',
                                                    style: TextStyle(
                                                      color: Colors.blue.shade700,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    notification['created_at'],
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            if (!isRead)
                                              Container(
                                                width: 12,
                                                height: 12,
                                                decoration: const BoxDecoration(
                                                  color: Colors.deepOrange,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            const SizedBox(height: 12),
                                            const Icon(Icons.arrow_forward_ios, size: 16),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
      ),
    );
  }
}
