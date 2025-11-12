import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rapidbite/database/database_helper.dart';

class MenuPage extends StatefulWidget {
  final int userId;
  final String restaurantName;
  final LatLng? restaurantPosition;

  const MenuPage({
    Key? key,
    required this.userId,
    required this.restaurantName,
    this.restaurantPosition,
  }) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with SingleTickerProviderStateMixin {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> menuItems = [];
  Map<String, int> cart = {};
  bool isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    print('📋 Loading menu for: ${widget.restaurantName}');

    // Check if menu exists first
    final hasMenu = await dbHelper.hasMenuItems(widget.restaurantName);
    print('🔍 Menu exists: $hasMenu');

    if (!hasMenu) {
      print('⚠️ No menu found! Seeding menu for ${widget.restaurantName}...');
      await dbHelper.seedMenuForRestaurant(widget.restaurantName);
    }

    // Load menu items from database
    final items = await dbHelper.getAvailableMenuItems(widget.restaurantName);
    print('📊 Loaded ${items.length} menu items');

    if (items.isNotEmpty) {
      for (var item in items.take(3)) {
        print('  - ${item['item_name']}: ₹${item['price']}');
      }
    }

    setState(() {
      menuItems = items;
      isLoading = false;
    });

    if (items.isNotEmpty) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void addToCart(String itemName) {
    setState(() {
      cart[itemName] = (cart[itemName] ?? 0) + 1;
    });
  }

  void removeFromCart(String itemName) {
    if (cart.containsKey(itemName)) {
      setState(() {
        if (cart[itemName]! > 1) {
          cart[itemName] = cart[itemName]! - 1;
        } else {
          cart.remove(itemName);
        }
      });
    }
  }

  double getCartTotal() {
    double total = 0;
    for (var item in menuItems) {
      if (cart.containsKey(item['item_name'])) {
        total += item['price'] * cart[item['item_name']]!;
      }
    }
    return total;
  }

  int getCartItemCount() {
    return cart.values.fold(0, (sum, quantity) => sum + quantity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.red.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar with Restaurant Info
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
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
                              Text(
                                widget.restaurantName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${menuItems.length} items available',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (cart.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shopping_cart, color: Colors.deepOrange, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '${getCartItemCount()}',
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.yellow.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Try our Chef\'s Special dishes!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Items List
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
                      : menuItems.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 20),
                        const Text(
                          'No menu items available',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Restaurant: ${widget.restaurantName}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () async {
                            setState(() {
                              isLoading = true;
                            });
                            await dbHelper.seedMenuForRestaurant(widget.restaurantName);
                            await _loadMenuItems();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Load Menu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                      : ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ListView.builder(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 20,
                            bottom: cart.isNotEmpty ? 100 : 20,
                          ),
                          itemCount: menuItems.length,
                          itemBuilder: (context, index) {
                            var item = menuItems[index];
                            int quantity = cart[item['item_name']] ?? 0;
                            bool isChefSpecial = item['chef_special'] == 1;

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
                                  border: isChefSpecial
                                      ? Border.all(
                                    color: Colors.orange.shade300,
                                    width: 2,
                                  )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: isChefSpecial
                                          ? Colors.orange.withOpacity(0.3)
                                          : Colors.grey.withOpacity(0.2),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Item Image
                                      Stack(
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(15),
                                              gradient: isChefSpecial
                                                  ? LinearGradient(
                                                colors: [
                                                  Colors.orange.shade200,
                                                  Colors.red.shade200
                                                ],
                                              )
                                                  : null,
                                              color: Colors.grey[200],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(15),
                                              child: item['photo_url'] != null &&
                                                  item['photo_url'].toString().startsWith('http')
                                                  ? Image.network(
                                                item['photo_url'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.fastfood,
                                                    size: 50,
                                                    color: Colors.grey,
                                                  );
                                                },
                                              )
                                                  : (item['photo_url'] != null
                                                  ? Image.asset(
                                                item['photo_url'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.fastfood,
                                                    size: 50,
                                                    color: Colors.grey,
                                                  );
                                                },
                                              )
                                                  : const Icon(
                                                Icons.fastfood,
                                                size: 50,
                                                color: Colors.grey,
                                              )),
                                            ),
                                          ),
                                          if (isChefSpecial)
                                            Positioned(
                                              top: 0,
                                              left: 0,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.orange.shade700,
                                                      Colors.red.shade600
                                                    ],
                                                  ),
                                                  borderRadius: const BorderRadius.only(
                                                    topLeft: Radius.circular(15),
                                                    bottomRight: Radius.circular(15),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(
                                                      Icons.star,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Chef\'s',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),

                                      // Item Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['item_name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            if (item['category'] != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  item['category'],
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.currency_rupee,
                                                  size: 18,
                                                  color: Colors.green,
                                                ),
                                                Text(
                                                  '${item['price'].toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Add/Remove Controls
                                      Column(
                                        children: [
                                          if (quantity == 0)
                                            ElevatedButton(
                                              onPressed: () => addToCart(item['item_name']),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.deepOrange,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 10,
                                                ),
                                              ),
                                              child: const Text(
                                                'ADD',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            )
                                          else
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.deepOrange,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      quantity == 1
                                                          ? Icons.delete
                                                          : Icons.remove,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    onPressed: () => removeFromCart(item['item_name']),
                                                    padding: const EdgeInsets.all(8),
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '$quantity',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.deepOrange,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.add,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    onPressed: () => addToCart(item['item_name']),
                                                    padding: const EdgeInsets.all(8),
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
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
              ),
            ],
          ),
        ),
      ),

      // Floating Cart Button
      floatingActionButton: cart.isNotEmpty
          ? Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/cart', arguments: {
              'userId': widget.userId,
              'cart': cart,
              'menuItems': menuItems,
              'restaurantPosition': widget.restaurantPosition,
              'restaurantName': widget.restaurantName,
            });
          },
          backgroundColor: Colors.deepOrange,
          elevation: 8,
          icon: Stack(
            children: [
              const Icon(Icons.shopping_cart, size: 28),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${getCartItemCount()}',
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          label: Row(
            children: [
              Text(
                '${getCartItemCount()} ${getCartItemCount() == 1 ? 'item' : 'items'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 2,
                height: 20,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(width: 12),
              Text(
                '₹${getCartTotal().toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
