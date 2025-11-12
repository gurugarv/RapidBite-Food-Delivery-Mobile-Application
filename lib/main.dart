import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rapidbite/database/database_helper.dart';
import 'package:rapidbite/screens/order_history_page.dart';
import 'package:rapidbite/screens/profile_page.dart';
import 'package:rapidbite/screens/settings_page.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/location_page.dart';
import 'screens/restaurant_search_page.dart';
import 'screens/menu_page.dart';
import 'screens/cart_page.dart';
import 'screens/payment_page.dart';
import 'screens/order_update_page.dart';
import 'screens/dashboard_page.dart';

// Import new owner screens
import 'screens/owner/owner_dashboard_page.dart';
import 'screens/owner/owner_orders_page.dart';
import 'screens/owner/owner_menu_page.dart';
import 'screens/owner/owner_notifications_page.dart';
import 'screens/owner/owner_analytics_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database and seed menus
  try {
    print('🚀 Initializing database...');
    final dbHelper = DatabaseHelper();

    // Force seed all restaurant menus
    await dbHelper.seedAllRestaurantMenus();

    print('✅ Database initialization complete');
  } catch (e) {
    print('❌ Error initializing database: $e');
  }

  runApp(RapidBiteApp());
}

class RapidBiteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RapidBite',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/settings': (context) => SettingsPage(),
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments;

        switch (settings.name) {
        // ==================== CUSTOMER ROUTES ====================

          case '/location':
            if (args is int) {
              return MaterialPageRoute(builder: (context) => LocationPage(userId: args));
            }
            return _errorRoute("userId not provided for location");

          case '/dashboard':
            if (args is Map && args['userId'] is int) {
              return MaterialPageRoute(
                builder: (context) => DashboardPage(
                  userId: args['userId'],
                  location: args['location'],
                ),
              );
            } else if (args is int) {
              return MaterialPageRoute(builder: (context) => DashboardPage(userId: args));
            }
            return _errorRoute("Required params not provided for dashboard");

          case '/profile':
            if (args is int) {
              return MaterialPageRoute(builder: (context) => ProfilePage(userId: args));
            }
            return _errorRoute("userId not provided for profile");

          case '/restaurant_search':
            if (args is Map && args['userId'] is int) {
              return MaterialPageRoute(
                  builder: (context) => RestaurantSearchPage(userId: args['userId']));
            }
            return _errorRoute("Required params not provided for restaurant_search");

          case '/menu':
            if (args is Map && args['userId'] is int && args['name'] != null) {
              return MaterialPageRoute(
                builder: (context) => MenuPage(
                  userId: args['userId'],
                  restaurantName: args['name'],
                  restaurantPosition: args['position'],
                ),
              );
            }
            return _errorRoute("Required params not provided for menu");

          case '/cart':
            if (args is Map &&
                args['userId'] is int &&
                args['cart'] is Map<String, int> &&
                args['menuItems'] is List &&
                args['restaurantName'] is String) {
              return MaterialPageRoute(
                builder: (context) => CartPage(
                  userId: args['userId'],
                  cart: args['cart'],
                  menuItems: args['menuItems'],
                  restaurantPosition: args['restaurantPosition'],
                  restaurantName: args['restaurantName'],
                ),
              );
            }
            return _errorRoute("Required params not provided for cart");

          case '/payment':
            if (args is Map &&
                args['userId'] is int &&
                args['total'] is double &&
                args['restaurantName'] is String) {
              return MaterialPageRoute(
                builder: (context) => PaymentPage(
                  userId: args['userId'],
                  totalAmount: args['total'],
                  cart: args['cart'],
                  menuItems: args['menuItems'],
                  restaurantPosition: args['restaurantPosition'],
                  restaurantName: args['restaurantName'],
                ),
              );
            }
            return _errorRoute("Required params not provided for payment");

          case '/order_update':
            if (args is Map &&
                args['userId'] is int &&
                args['orderId'] is int &&
                args['restaurantPosition'] is LatLng) {
              return MaterialPageRoute(
                builder: (context) => OrderUpdatePage(
                  userId: args['userId'],
                  orderId: args['orderId'],
                  restaurantPosition: args['restaurantPosition'],
                ),
              );
            }
            return _errorRoute("Required params not provided for order_update");

          case '/order_history':
            if (args is int) {
              return MaterialPageRoute(builder: (context) => OrderHistoryPage(userId: args));
            }
            return _errorRoute("userId not provided for order_history");

        // ==================== OWNER ROUTES ====================

          case '/owner_dashboard':
            if (args is int) {
              return MaterialPageRoute(
                builder: (context) => OwnerDashboardPage(userId: args),
              );
            }
            return _errorRoute("userId not provided for owner_dashboard");

          case '/owner_orders':
            if (args is String) {
              return MaterialPageRoute(
                builder: (context) => OwnerOrdersPage(restaurantName: args),
              );
            }
            return _errorRoute("restaurantName not provided for owner_orders");

          case '/owner_menu':
            if (args is String) {
              return MaterialPageRoute(
                builder: (context) => OwnerMenuPage(restaurantName: args),
              );
            }
            return _errorRoute("restaurantName not provided for owner_menu");

          case '/owner_notifications':
            if (args is String) {
              return MaterialPageRoute(
                builder: (context) => OwnerNotificationsPage(restaurantName: args),
              );
            }
            return _errorRoute("restaurantName not provided for owner_notifications");

          case '/owner_analytics':
            if (args is String) {
              return MaterialPageRoute(
                builder: (context) => OwnerAnalyticsPage(restaurantName: args),
              );
            }
            return _errorRoute("restaurantName not provided for owner_analytics");

          default:
            return null;
        }
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 20),
                  Text(
                    'Route "${settings.name}" not found',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  MaterialPageRoute _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Error: $message',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
