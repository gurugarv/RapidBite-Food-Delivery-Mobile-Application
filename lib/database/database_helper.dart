import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:rapidbite/database/menu_seed_data.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'userdb.db');

    return openDatabase(
      path,
      version: 8, // Incremented version for owner features
      onCreate: (db, version) async {
        // Users table with role support
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            contact TEXT,
            username TEXT,
            password TEXT,
            role TEXT DEFAULT 'customer',
            restaurant_name TEXT,
            restaurant_address TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Addresses table
        await db.execute('''
          CREATE TABLE addresses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            label TEXT,
            address TEXT,
            latitude REAL,
            longitude REAL,
            FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');

        // Orders table with enhanced fields
        await db.execute('''
          CREATE TABLE orders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            restaurant TEXT,
            orderDate TEXT,
            total REAL,
            status TEXT DEFAULT 'Pending',
            details TEXT,
            payment_id TEXT,
            restaurant_lat REAL,
            restaurant_lng REAL,
            FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');

        // Menu items table for restaurant owners
        await db.execute('''
          CREATE TABLE menu_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            restaurant_name TEXT NOT NULL,
            item_name TEXT NOT NULL,
            price REAL NOT NULL,
            photo_url TEXT,
            chef_special INTEGER DEFAULT 0,
            category TEXT,
            available INTEGER DEFAULT 1,
            description TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Notifications table for restaurant owners
        await db.execute('''
          CREATE TABLE notifications(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            restaurant_name TEXT NOT NULL,
            order_id INTEGER NOT NULL,
            message TEXT NOT NULL,
            read INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print('Upgrading database from version $oldVersion to $newVersion');

        // Version 2: Add addresses table
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS addresses(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              userId INTEGER,
              label TEXT,
              address TEXT,
              latitude REAL,
              longitude REAL,
              FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');
        }

        // Version 3: Add orders table
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS orders(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              userId INTEGER,
              restaurant TEXT,
              orderDate TEXT,
              total REAL,
              status TEXT,
              details TEXT,
              FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');
        }

        // Version 4: Add user profile fields
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE users ADD COLUMN name TEXT');
          } catch (e) {
            print('Column name already exists: $e');
          }
          try {
            await db.execute('ALTER TABLE users ADD COLUMN contact TEXT');
          } catch (e) {
            print('Column contact already exists: $e');
          }
          try {
            await db.execute('ALTER TABLE users ADD COLUMN username TEXT');
          } catch (e) {
            print('Column username already exists: $e');
          }
        }

        // Version 6: Add role-based authentication fields
        if (oldVersion < 6) {
          try {
            await db.execute('ALTER TABLE users ADD COLUMN role TEXT DEFAULT "customer"');
          } catch (e) {
            print('Column role already exists: $e');
          }
          try {
            await db.execute('ALTER TABLE users ADD COLUMN restaurant_name TEXT');
          } catch (e) {
            print('Column restaurant_name already exists: $e');
          }
          try {
            await db.execute('ALTER TABLE users ADD COLUMN restaurant_address TEXT');
          } catch (e) {
            print('Column restaurant_address already exists: $e');
          }
          try {
            await db.execute('ALTER TABLE users ADD COLUMN created_at TEXT DEFAULT CURRENT_TIMESTAMP');
          } catch (e) {
            print('Column created_at already exists: $e');
          }
        }

        // Version 7: Add payment and location fields to orders
        if (oldVersion < 7) {
          try {
            await db.execute('ALTER TABLE orders ADD COLUMN payment_id TEXT');
          } catch (e) {
            print('Column payment_id already exists: $e');
          }
          try {
            await db.execute('ALTER TABLE orders ADD COLUMN restaurant_lat REAL');
          } catch (e) {
            print('Column restaurant_lat already exists: $e');
          }
          try {
            await db.execute('ALTER TABLE orders ADD COLUMN restaurant_lng REAL');
          } catch (e) {
            print('Column restaurant_lng already exists: $e');
          }

          // Update existing orders to have 'Pending' status if null
          await db.execute('UPDATE orders SET status = "Pending" WHERE status IS NULL');
        }

        // Version 8: Add menu items and notifications tables
        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS menu_items(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              restaurant_name TEXT NOT NULL,
              item_name TEXT NOT NULL,
              price REAL NOT NULL,
              photo_url TEXT,
              chef_special INTEGER DEFAULT 0,
              category TEXT,
              available INTEGER DEFAULT 1,
              description TEXT,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS notifications(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              restaurant_name TEXT NOT NULL,
              order_id INTEGER NOT NULL,
              message TEXT NOT NULL,
              read INTEGER DEFAULT 0,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
            )
          ''');
        }
      },
    );
  }
  Future<void> _populateInitialData(Database db) async {
    // Check if data already exists
    final restaurantCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM restaurants'),
    );

    if (restaurantCount == 0) {
      print('📝 Populating initial data...');

      // ========== INSERT TEST USERS ==========

      // Test User 1 (Customer) - ID: G, Password: G
      await db.insert('users', {
        'name': 'Guest User',
        'email': 'G',
        'contact': '9999999999',
        'password': 'G',
        'user_type': 'customer',
      });
      print('✅ Created test customer: G / G');

      // Test User 2 (Owner) - ID: M, Password: M
      await db.insert('users', {
        'name': 'Manager Owner',
        'email': 'M',
        'contact': '8888888888',
        'password': 'M',
        'user_type': 'owner',
      });
      print('✅ Created test owner: M / M');

      // Additional test users for variety
      await db.insert('users', {
        'name': 'John Doe',
        'email': 'john@test.com',
        'contact': '1234567890',
        'password': '123456',
        'user_type': 'customer',
      });

      await db.insert('users', {
        'name': 'Restaurant Owner',
        'email': 'owner@spicevilla.com',
        'contact': '9876543210',
        'password': 'owner123',
        'user_type': 'owner',
      });

      // ========== INSERT RESTAURANTS ==========

      await db.insert('restaurants', {
        'name': 'Spice Villa',
        'latitude': 19.0760,
        'longitude': 72.8777,
        'rating': 4.5,
        'cuisine': 'Indian',
        'delivery_time': '25-35 min',
      });

      await db.insert('restaurants', {
        'name': 'Pizza Palace',
        'latitude': 19.0820,
        'longitude': 72.8850,
        'rating': 4.3,
        'cuisine': 'Italian',
        'delivery_time': '30-40 min',
      });

      await db.insert('restaurants', {
        'name': 'Burger Bistro',
        'latitude': 19.0700,
        'longitude': 72.8700,
        'rating': 4.2,
        'cuisine': 'Fast Food',
        'delivery_time': '20-30 min',
      });

      await db.insert('restaurants', {
        'name': 'Sushi Station',
        'latitude': 19.0850,
        'longitude': 72.8900,
        'rating': 4.6,
        'cuisine': 'Japanese',
        'delivery_time': '35-45 min',
      });


      // Insert sample restaurants
      await db.insert('restaurants', {
        'name': 'Spice Villa',
        'latitude': 19.0760,
        'longitude': 72.8777,
        'rating': 4.5,
        'cuisine': 'Indian',
        'delivery_time': '25-35 min',
      });

      await db.insert('restaurants', {
        'name': 'Pizza Palace',
        'latitude': 19.0820,
        'longitude': 72.8850,
        'rating': 4.3,
        'cuisine': 'Italian',
        'delivery_time': '30-40 min',
      });

      await db.insert('restaurants', {
        'name': 'Burger Bistro',
        'latitude': 19.0700,
        'longitude': 72.8700,
        'rating': 4.2,
        'cuisine': 'Fast Food',
        'delivery_time': '20-30 min',
      });

      // Insert sample menu items for Spice Villa
      await db.insert('menu_items', {
        'restaurant_name': 'Spice Villa',
        'item_name': 'Butter Naan',
        'price': 45.0,
        'category': 'Breads',
        'is_veg': 1,
        'description': 'Soft and buttery naan bread',
      });

      await db.insert('menu_items', {
        'restaurant_name': 'Spice Villa',
        'item_name': 'Paneer Butter Masala',
        'price': 160.0,
        'category': 'Main Course',
        'is_veg': 1,
        'description': 'Creamy paneer curry',
      });

      await db.insert('menu_items', {
        'restaurant_name': 'Spice Villa',
        'item_name': 'Jeera Rice',
        'price': 85.0,
        'category': 'Rice',
        'is_veg': 1,
        'description': 'Fragrant cumin rice',
      });

      // Insert sample menu items for Pizza Palace
      await db.insert('menu_items', {
        'restaurant_name': 'Pizza Palace',
        'item_name': 'Margherita Pizza',
        'price': 250.0,
        'category': 'Pizza',
        'is_veg': 1,
        'description': 'Classic tomato and mozzarella',
      });

      await db.insert('menu_items', {
        'restaurant_name': 'Pizza Palace',
        'item_name': 'Pepperoni Pizza',
        'price': 320.0,
        'category': 'Pizza',
        'is_veg': 0,
        'description': 'Loaded with pepperoni',
      });

      // Insert sample menu items for Burger Bistro
      await db.insert('menu_items', {
        'restaurant_name': 'Burger Bistro',
        'item_name': 'Classic Burger',
        'price': 120.0,
        'category': 'Burgers',
        'is_veg': 0,
        'description': 'Juicy beef burger',
      });

      await db.insert('menu_items', {
        'restaurant_name': 'Burger Bistro',
        'item_name': 'Veggie Burger',
        'price': 100.0,
        'category': 'Burgers',
        'is_veg': 1,
        'description': 'Delicious veggie patty',
      });

      print('✅ Initial data populated successfully');
    } else {
      print('✅ Database already contains data');
    }
  }


  // ==================== USER METHODS ====================

  Future<int> createUser({
    required String name,
    required String email,
    required String contact,
    required String username,
    required String password,
    String role = 'customer',
    String? restaurantName,
    String? restaurantAddress,
  }) async {
    final db = await database;

    final userId = await db.insert('users', {
      'name': name,
      'email': email,
      'contact': contact,
      'username': username,
      'password': password,
      'role': role,
      'restaurant_name': restaurantName,
      'restaurant_address': restaurantAddress,
    });

    // Auto-seed menu if user is a restaurant owner
    if (role == 'owner' && restaurantName != null) {
      await seedMenuForRestaurant(restaurantName);
    }

    return userId;
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    final db = await database;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final res = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<int> updateUser(int id, {
    required String name,
    required String email,
    required String contact,
    required String username,
    required String password,
  }) async {
    final db = await database;
    return await db.update(
      'users',
      {
        'name': name,
        'email': email,
        'contact': contact,
        'username': username,
        'password': password
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== ADDRESS METHODS ====================

  Future<int> addAddress({
    required int userId,
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final db = await database;
    return await db.insert('addresses', {
      'userId': userId,
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<List<Map<String, dynamic>>> getAddressesForUser(int userId) async {
    final db = await database;
    return await db.query('addresses', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<int> updateAddress({
    required int id,
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final db = await database;
    return await db.update(
      'addresses',
      {'label': label, 'address': address, 'latitude': latitude, 'longitude': longitude},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAddress(int id) async {
    final db = await database;
    return await db.delete('addresses', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== ORDER METHODS ====================

  Future<int> addOrder({
    required int userId,
    required String restaurant,
    required String orderDate,
    required double total,
    required String details,
    String status = 'Pending',
    String? paymentId,
    double? restaurantLat,
    double? restaurantLng,
  }) async {
    final db = await database;
    final orderId = await db.insert('orders', {
      'userId': userId,
      'restaurant': restaurant,
      'orderDate': orderDate,
      'total': total,
      'status': status,
      'details': details,
      'payment_id': paymentId,
      'restaurant_lat': restaurantLat,
      'restaurant_lng': restaurantLng,
    });

    // Create notification for restaurant owner
    await addNotification(
      restaurantName: restaurant,
      orderId: orderId,
      message: 'New order received - ₹${total.toStringAsFixed(2)}',
    );

    return orderId;
  }

  Future<List<Map<String, dynamic>>> getOrdersForUser(int userId) async {
    final db = await database;
    return await db.query('orders', where: 'userId = ?', whereArgs: [userId], orderBy: 'orderDate DESC');
  }

  Future<List<Map<String, dynamic>>> getOrdersForRestaurant(String restaurantName) async {
    final db = await database;
    return await db.query(
      'orders',
      where: 'restaurant = ?',
      whereArgs: [restaurantName],
      orderBy: 'orderDate DESC',
    );
  }

  Future<int> updateOrderStatus(int orderId, String status) async {
    final db = await database;
    return await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<Map<String, dynamic>?> getOrder(int orderId) async {
    final db = await database;
    final res = await db.query('orders', where: 'id = ?', whereArgs: [orderId]);
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  // ==================== MENU ITEM METHODS ====================

  Future<int> addMenuItem({
    required String restaurantName,
    required String itemName,
    required double price,
    String? photoUrl,
    bool chefSpecial = false,
    String? category,
    String? description,
  }) async {
    final db = await database;
    return await db.insert('menu_items', {
      'restaurant_name': restaurantName,
      'item_name': itemName,
      'price': price,
      'photo_url': photoUrl,
      'chef_special': chefSpecial ? 1 : 0,
      'category': category,
      'description': description,
    });
  }

  Future<int> updateMenuItem({
    required int itemId,
    required String itemName,
    required double price,
    String? photoUrl,
    bool chefSpecial = false,
    String? category,
    String? description,
  }) async {
    final db = await database;
    return await db.update(
      'menu_items',
      {
        'item_name': itemName,
        'price': price,
        'photo_url': photoUrl,
        'chef_special': chefSpecial ? 1 : 0,
        'category': category,
        'description': description,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<int> deleteMenuItem(int itemId) async {
    final db = await database;
    return await db.delete('menu_items', where: 'id = ?', whereArgs: [itemId]);
  }

  Future<int> toggleMenuItemAvailability(int itemId, bool available) async {
    final db = await database;
    return await db.update(
      'menu_items',
      {'available': available ? 1 : 0},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<List<Map<String, dynamic>>> getMenuItemsForRestaurant(String restaurantName) async {
    final db = await database;
    return await db.query(
      'menu_items',
      where: 'restaurant_name = ?',
      whereArgs: [restaurantName],
      orderBy: 'category ASC, item_name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAvailableMenuItems(String restaurantName) async {
    final db = await database;
    return await db.query(
      'menu_items',
      where: 'restaurant_name = ? AND available = 1',
      whereArgs: [restaurantName],
      orderBy: 'category ASC, item_name ASC',
    );
  }

  // ==================== NOTIFICATION METHODS ====================

  Future<int> addNotification({
    required String restaurantName,
    required int orderId,
    required String message,
  }) async {
    final db = await database;
    return await db.insert('notifications', {
      'restaurant_name': restaurantName,
      'order_id': orderId,
      'message': message,
    });
  }

// Get unread notifications for restaurant
  Future<List<Map<String, dynamic>>> getUnreadNotificationsForRestaurant(String restaurantName) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'restaurant_name = ? AND read = 0',
      whereArgs: [restaurantName],
      orderBy: 'created_at DESC',
    );
  }

// Get all notifications for restaurant
  Future<List<Map<String, dynamic>>> getNotificationsForRestaurant(String restaurantName) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'restaurant_name = ?',
      whereArgs: [restaurantName],
      orderBy: 'created_at DESC',
    );
  }
  // Mark notification as read
  Future<int> markNotificationAsRead(int notificationId) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

// Mark all notifications as read for restaurant
  Future<int> markAllNotificationsAsRead(String restaurantName) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'read': 1},
      where: 'restaurant_name = ? AND read = 0',
      whereArgs: [restaurantName],
    );
  }



  Future<int> getUnreadNotificationCount(String restaurantName) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE restaurant_name = ? AND read = 0',
      [restaurantName],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteNotification(int notificationId) async {
    final db = await database;
    return await db.delete('notifications', where: 'id = ?', whereArgs: [notificationId]);
  }

  // ==================== ANALYTICS METHODS ====================

  Future<Map<String, dynamic>> getRestaurantAnalytics(String restaurantName) async {
    final db = await database;

    // Total orders
    final totalOrdersResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE restaurant = ?',
      [restaurantName],
    );
    int totalOrders = Sqflite.firstIntValue(totalOrdersResult) ?? 0;

    // Total revenue
    final totalRevenueResult = await db.rawQuery(
      'SELECT SUM(total) as revenue FROM orders WHERE restaurant = ?',
      [restaurantName],
    );
    double totalRevenue = (totalRevenueResult.first['revenue'] as num?)?.toDouble() ?? 0.0;

    // Pending orders
    final pendingOrdersResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE restaurant = ? AND status = "Pending"',
      [restaurantName],
    );
    int pendingOrders = Sqflite.firstIntValue(pendingOrdersResult) ?? 0;

    // Today's orders
    final todayOrdersResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE restaurant = ? AND DATE(orderDate) = DATE("now")',
      [restaurantName],
    );
    int todayOrders = Sqflite.firstIntValue(todayOrdersResult) ?? 0;

    // Today's revenue
    final todayRevenueResult = await db.rawQuery(
      'SELECT SUM(total) as revenue FROM orders WHERE restaurant = ? AND DATE(orderDate) = DATE("now")',
      [restaurantName],
    );
    double todayRevenue = (todayRevenueResult.first['revenue'] as num?)?.toDouble() ?? 0.0;

    // Completed orders
    final completedOrdersResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE restaurant = ? AND status = "Delivered"',
      [restaurantName],
    );
    int completedOrders = Sqflite.firstIntValue(completedOrdersResult) ?? 0;

    return {
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'pendingOrders': pendingOrders,
      'todayOrders': todayOrders,
      'todayRevenue': todayRevenue,
      'completedOrders': completedOrders,
    };
  }

  Future<List<Map<String, dynamic>>> getOrdersByDateRange(
      String restaurantName,
      String startDate,
      String endDate,
      ) async {
    final db = await database;
    return await db.query(
      'orders',
      where: 'restaurant = ? AND DATE(orderDate) BETWEEN DATE(?) AND DATE(?)',
      whereArgs: [restaurantName, startDate, endDate],
      orderBy: 'orderDate DESC',
    );
  }

  // ==================== SEEDING METHODS ====================

  // Check if menu items exist for a restaurant
  Future<bool> hasMenuItems(String restaurantName) async {
    final db = await database;
    final result = await db.query(
      'menu_items',
      where: 'restaurant_name = ?',
      whereArgs: [restaurantName],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Seed menu items for a specific restaurant
  Future<void> seedMenuForRestaurant(String restaurantName) async {
    final db = await database;

    // Check if menu already exists
    final hasMenu = await hasMenuItems(restaurantName);
    if (hasMenu) {
      print('Menu already exists for $restaurantName');
      return;
    }

    // Get menu data from seed file
    final menuData = MenuSeedData.restaurantMenus[restaurantName];
    if (menuData == null) {
      print('No seed data found for $restaurantName');
      return;
    }

    // Insert all menu items using batch operation for efficiency
    final batch = db.batch();
    for (var item in menuData) {
      batch.insert('menu_items', {
        'restaurant_name': restaurantName,
        'item_name': item['item_name'],
        'price': item['price'],
        'photo_url': item['photo_url'],
        'chef_special': item['chef_special'],
        'category': item['category'],
        'description': item['description'],
        'available': 1,
      });
    }

    await batch.commit(noResult: true);
    print('Successfully seeded menu for $restaurantName');
  }

  // Seed all restaurant menus
  Future<void> seedAllRestaurantMenus() async {
    for (var restaurantName in MenuSeedData.restaurantMenus.keys) {
      await seedMenuForRestaurant(restaurantName);
    }
    print('All restaurant menus seeded successfully');
  }

  // Check if database has been seeded
  Future<bool> isDatabaseSeeded() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM menu_items');
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  // ==================== UTILITY METHODS ====================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('addresses');
    await db.delete('orders');
    await db.delete('menu_items');
    await db.delete('notifications');
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'userdb.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
