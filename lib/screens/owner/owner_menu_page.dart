import 'package:flutter/material.dart';
import 'package:rapidbite/database/database_helper.dart';

class OwnerMenuPage extends StatefulWidget {
  final String restaurantName;

  const OwnerMenuPage({Key? key, required this.restaurantName}) : super(key: key);

  @override
  _OwnerMenuPageState createState() => _OwnerMenuPageState();
}

class _OwnerMenuPageState extends State<OwnerMenuPage> {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> menuItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMenu();
  }

  // Initialize and check if seeding is needed
  Future<void> _initializeMenu() async {
    // Check if menu exists
    final hasMenu = await dbHelper.hasMenuItems(widget.restaurantName);

    if (!hasMenu) {
      print('No menu found for ${widget.restaurantName}, attempting to seed...');
      // Automatically seed if no menu exists
      await dbHelper.seedMenuForRestaurant(widget.restaurantName);
    }

    await _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    final items = await dbHelper.getMenuItemsForRestaurant(widget.restaurantName);
    print('Loaded ${items.length} menu items for ${widget.restaurantName}');

    setState(() {
      menuItems = items;
      isLoading = false;
    });
  }

  void _showAddEditDialog({Map<String, dynamic>? item}) {
    final isEditing = item != null;
    final nameController = TextEditingController(text: item?['item_name']);
    final priceController = TextEditingController(text: item?['price']?.toString());
    final photoController = TextEditingController(text: item?['photo_url']);
    final categoryController = TextEditingController(text: item?['category']);
    final descriptionController = TextEditingController(text: item?['description']);
    bool chefSpecial = item?['chef_special'] == 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Menu Item' : 'Add Menu Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price *',
                    prefixText: '₹',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category (e.g., Main Course)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: photoController,
                  decoration: const InputDecoration(
                    labelText: 'Photo URL (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text("Chef's Special"),
                  value: chefSpecial,
                  onChanged: (value) {
                    setDialogState(() {
                      chefSpecial = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill required fields')),
                  );
                  return;
                }

                final price = double.tryParse(priceController.text);
                if (price == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid price')),
                  );
                  return;
                }

                if (isEditing) {
                  await dbHelper.updateMenuItem(
                    itemId: item['id'],
                    itemName: nameController.text,
                    price: price,
                    photoUrl: photoController.text.isEmpty ? null : photoController.text,
                    chefSpecial: chefSpecial,
                    category: categoryController.text.isEmpty ? null : categoryController.text,
                    description: descriptionController.text.isEmpty ? null : descriptionController.text,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Menu item updated')),
                  );
                } else {
                  await dbHelper.addMenuItem(
                    restaurantName: widget.restaurantName,
                    itemName: nameController.text,
                    price: price,
                    photoUrl: photoController.text.isEmpty ? null : photoController.text,
                    chefSpecial: chefSpecial,
                    category: categoryController.text.isEmpty ? null : categoryController.text,
                    description: descriptionController.text.isEmpty ? null : descriptionController.text,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Menu item added')),
                  );
                }

                Navigator.pop(context);
                _loadMenuItems();
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMenuItem(int itemId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await dbHelper.deleteMenuItem(itemId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu item deleted')),
              );
              _loadMenuItems();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAvailability(int itemId, bool currentAvailability) async {
    await dbHelper.toggleMenuItemAvailability(itemId, !currentAvailability);
    _loadMenuItems();
  }

  // Manual reseed option
  Future<void> _reseedMenu() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reseed Menu'),
        content: const Text(
            'This will delete all current menu items and reload the default menu. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              // Delete existing menu items
              final existingItems = await dbHelper.getMenuItemsForRestaurant(widget.restaurantName);
              for (var item in existingItems) {
                await dbHelper.deleteMenuItem(item['id']);
              }

              // Reseed
              await dbHelper.seedMenuForRestaurant(widget.restaurantName);

              // Close loading dialog
              Navigator.pop(context);

              // Reload
              await _loadMenuItems();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu reseeded successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reseed'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
        backgroundColor: Colors.orange.shade400,
        actions: [
          // Add debug/reseed button
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reseed') {
                _reseedMenu();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reseed',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Reseed Default Menu'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : menuItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No menu items yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              'Restaurant: ${widget.restaurantName}',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add First Item'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _reseedMenu,
              icon: const Icon(Icons.refresh),
              label: const Text('Load Default Menu'),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          final isAvailable = item['available'] == 1;

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: item['photo_url'] != null && item['photo_url'].toString().isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: item['photo_url'].toString().startsWith('http')
                      ? Image.network(
                    item['photo_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.fastfood, size: 40);
                    },
                  )
                      : Image.asset(
                    item['photo_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.fastfood, size: 40);
                    },
                  ),
                )
                    : const Icon(Icons.fastfood, size: 40),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item['item_name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isAvailable ? null : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                  if (item['chef_special'] == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '⭐ Chef',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '₹${item['price'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  if (item['category'] != null)
                    Text(
                      item['category'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  if (item['description'] != null)
                    Text(
                      item['description'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showAddEditDialog(item: item);
                      break;
                    case 'toggle':
                      _toggleAvailability(item['id'], isAvailable);
                      break;
                    case 'delete':
                      _deleteMenuItem(item['id'], item['item_name']);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          isAvailable ? Icons.visibility_off : Icons.visibility,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(isAvailable ? 'Mark Unavailable' : 'Mark Available'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }
}
