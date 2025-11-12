import 'package:flutter/material.dart';
import 'package:rapidbite/database/database_helper.dart';
import 'dart:async';

class OwnerDashboardPage extends StatefulWidget {
  final int userId;

  const OwnerDashboardPage({Key? key, required this.userId}) : super(key: key);

  @override
  _OwnerDashboardPageState createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  final dbHelper = DatabaseHelper();
  Map<String, dynamic>? userData;
  Map<String, dynamic> analytics = {};
  int unreadNotifications = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAnalytics();
    _loadNotifications();

    // Poll for new notifications every 10 seconds
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadNotifications();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await dbHelper.getUserById(widget.userId);
    setState(() {
      userData = user;
    });
  }

  Future<void> _loadAnalytics() async {
    if (userData != null && userData!['restaurant_name'] != null) {
      final data = await dbHelper.getRestaurantAnalytics(userData!['restaurant_name']);
      setState(() {
        analytics = data;
      });
    }
  }

  Future<void> _loadNotifications() async {
    if (userData != null && userData!['restaurant_name'] != null) {
      final count = await dbHelper.getUnreadNotificationCount(userData!['restaurant_name']);
      setState(() {
        unreadNotifications = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(userData!['restaurant_name'] ?? 'Restaurant Dashboard'),
        backgroundColor: Colors.orange.shade400,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/owner_notifications',
                    arguments: userData!['restaurant_name'],
                  ).then((_) => _loadNotifications());
                },
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadNotifications > 9 ? '9+' : '$unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade300, Colors.red.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadAnalytics();
            await _loadNotifications();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${userData!['name']}!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userData!['restaurant_address'] ?? 'Your restaurant dashboard',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Analytics cards
                Text(
                  'Analytics',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Total Orders',
                        '${analytics['totalOrders'] ?? 0}',
                        Icons.shopping_cart,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Today\'s Orders',
                        '${analytics['todayOrders'] ?? 0}',
                        Icons.today,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Total Revenue',
                        '₹${analytics['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}',
                        Icons.currency_rupee,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Pending Orders',
                        '${analytics['pendingOrders'] ?? 0}',
                        Icons.pending_actions,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action buttons
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  'Manage Orders',
                  Icons.list_alt,
                      () {
                    Navigator.pushNamed(
                      context,
                      '/owner_orders',
                      arguments: userData!['restaurant_name'],
                    ).then((_) => _loadAnalytics());
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  'Manage Menu',
                  Icons.restaurant_menu,
                      () {
                    Navigator.pushNamed(
                      context,
                      '/owner_menu',
                      arguments: userData!['restaurant_name'],
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  'View Analytics',
                  Icons.analytics,
                      () {
                    Navigator.pushNamed(
                      context,
                      '/owner_analytics',
                      arguments: userData!['restaurant_name'],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepOrange, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
