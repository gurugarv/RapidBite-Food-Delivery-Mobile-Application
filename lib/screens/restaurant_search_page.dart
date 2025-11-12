import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class RestaurantSearchPage extends StatefulWidget {
  final int userId;

  const RestaurantSearchPage({Key? key, required this.userId}) : super(key: key);

  @override
  _RestaurantSearchPageState createState() => _RestaurantSearchPageState();
}

class _RestaurantSearchPageState extends State<RestaurantSearchPage>
    with SingleTickerProviderStateMixin {
  GoogleMapController? mapController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final LatLng initialPosition = LatLng(19.0760, 72.8777); // Mumbai
  int? selectedRestaurantIndex;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredRestaurants = [];

  final List<Map<String, dynamic>> restaurants = [
    {
      'name': 'Spice Villa',
      'position': LatLng(19.0330, 73.0297),
      'photoUrl': 'assets/restaurant/SpiceVilla.png',
      'cuisine': 'Indian, North',
      'rating': 4.5,
      'deliveryTime': '25-30 min',
      'distance': '2.5 km',
    },
    {
      'name': 'Tasty Treat',
      'position': LatLng(19.0173, 73.0227),
      'photoUrl': 'assets/restaurant/tasty.png',
      'cuisine': 'Fast Food, Desserts',
      'rating': 4.2,
      'deliveryTime': '20-25 min',
      'distance': '1.8 km',
    },
    {
      'name': 'North Feast',
      'position': LatLng(19.0650, 73.0181),
      'photoUrl': 'assets/restaurant/north.png',
      'cuisine': 'Punjabi, Thali',
      'rating': 4.1,
      'deliveryTime': '30-35 min',
      'distance': '3.2 km',
    },
    {
      'name': 'Urban Chops',
      'position': LatLng(19.0455, 73.0229),
      'photoUrl': 'assets/restaurant/urban.png',
      'cuisine': 'Grill, Continental',
      'rating': 4.6,
      'deliveryTime': '35-40 min',
      'distance': '4.1 km',
    },
    {
      'name': 'The Bombay Plate',
      'position': LatLng(19.0214, 73.0554),
      'photoUrl': 'assets/restaurant/bombay.png',
      'cuisine': 'Fusion, Snacks',
      'rating': 4.3,
      'deliveryTime': '22-28 min',
      'distance': '2.1 km',
    },
    {
      'name': 'Coastal Curry',
      'position': LatLng(19.0705, 73.0494),
      'photoUrl': 'assets/restaurant/coastak.png',
      'cuisine': 'Seafood, South Indian',
      'rating': 4.8,
      'deliveryTime': '28-33 min',
      'distance': '2.9 km',
    },
    {
      'name': 'Pizza Powerhouse',
      'position': LatLng(19.0501, 73.0243),
      'photoUrl': 'assets/restaurant/pizza.png',
      'cuisine': 'Pizza, Italian',
      'rating': 4.4,
      'deliveryTime': '25-30 min',
      'distance': '2.3 km',
    },
  ];

  @override
  void initState() {
    super.initState();
    filteredRestaurants = restaurants;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterRestaurants(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredRestaurants = restaurants;
      } else {
        filteredRestaurants = restaurants.where((restaurant) {
          final name = restaurant['name'].toString().toLowerCase();
          final cuisine = restaurant['cuisine'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || cuisine.contains(searchLower);
        }).toList();
      }
    });
  }

  Set<Marker> _createMarkers() {
    return filteredRestaurants
        .asMap()
        .entries
        .map((entry) {
      int index = entry.key;
      var restaurant = entry.value;
      return Marker(
        markerId: MarkerId(restaurant['name']),
        position: restaurant['position'],
        icon: BitmapDescriptor.defaultMarkerWithHue(
          selectedRestaurantIndex == index
              ? BitmapDescriptor.hueOrange
              : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: restaurant['name'],
          snippet: restaurant['cuisine'],
        ),
        onTap: () {
          setState(() {
            selectedRestaurantIndex = index;
          });
          _animateToRestaurant(restaurant['position']);
        },
      );
    })
        .toSet();
  }

  void _animateToRestaurant(LatLng position) {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 15, tilt: 45),
      ),
    );
  }

  void _navigateToMenu(Map<String, dynamic> restaurant) {
    final arguments = Map<String, dynamic>.from(restaurant);
    arguments['userId'] = widget.userId;
    Navigator.pushNamed(context, '/menu', arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = _createMarkers();
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
              // Header Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                                const Text(
                                  'Find Restaurants',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${filteredRestaurants.length} restaurants nearby',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterRestaurants,
                          decoration: InputDecoration(
                            hintText: 'Search restaurants or cuisine...',
                            prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _filterRestaurants('');
                              },
                            )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Map Section
              Expanded(
                flex: 2,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: initialPosition,
                              zoom: 12,
                            ),
                            markers: markers,
                            onMapCreated: (controller) {
                              mapController = controller;
                            },
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                          ),

                          // Custom Location Button
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: FloatingActionButton(
                              mini: true,
                              backgroundColor: Colors.white,
                              onPressed: () {
                                mapController?.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(
                                      target: initialPosition,
                                      zoom: 12,
                                    ),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Restaurant List Section
              Expanded(
                flex: 2,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Available Restaurants',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    // Sort by rating
                                    setState(() {
                                      filteredRestaurants.sort((a, b) =>
                                          b['rating'].compareTo(a['rating']));
                                    });
                                  },
                                  icon: const Icon(Icons.sort, size: 18),
                                  label: const Text('Sort'),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: filteredRestaurants.isEmpty
                                ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No restaurants found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              itemCount: filteredRestaurants.length,
                              itemBuilder: (context, index) {
                                var rest = filteredRestaurants[index];
                                bool isSelected = selectedRestaurantIndex == index;

                                return TweenAnimationBuilder(
                                  duration: Duration(
                                    milliseconds: 300 + (index * 100),
                                  ),
                                  tween: Tween<double>(begin: 0, end: 1),
                                  builder: (context, double value, child) {
                                    return Transform.scale(
                                      scale: 0.8 + (0.2 * value),
                                      child: Opacity(
                                        opacity: value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: isSelected
                                          ? LinearGradient(
                                        colors: [
                                          Colors.orange.shade100,
                                          Colors.red.shade100,
                                        ],
                                      )
                                          : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? Colors.orange.withOpacity(0.3)
                                              : Colors.grey.withOpacity(0.2),
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
                                          setState(() {
                                            selectedRestaurantIndex = index;
                                          });
                                          _animateToRestaurant(rest['position']);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            border: isSelected
                                                ? Border.all(
                                              color: Colors.deepOrange,
                                              width: 2,
                                            )
                                                : null,
                                          ),
                                          child: Row(
                                            children: [
                                              // Restaurant Image
                                              Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                    const BorderRadius.only(
                                                      topLeft: Radius.circular(20),
                                                      bottomLeft: Radius.circular(20),
                                                    ),
                                                    child: Image.asset(
                                                      rest['photoUrl'],
                                                      height: 110,
                                                      width: 110,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Container(
                                                          height: 110,
                                                          width: 110,
                                                          color: Colors.grey[200],
                                                          child: const Icon(
                                                            Icons.restaurant,
                                                            size: 50,
                                                            color: Colors.grey,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  if (rest['rating'] >= 4.5)
                                                    Positioned(
                                                      top: 8,
                                                      left: 8,
                                                      child: Container(
                                                        padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              Colors.orange.shade700,
                                                              Colors.red.shade600,
                                                            ],
                                                          ),
                                                          borderRadius:
                                                          BorderRadius.circular(12),
                                                        ),
                                                        child: Row(
                                                          children: const [
                                                            Icon(
                                                              Icons.star,
                                                              color: Colors.white,
                                                              size: 14,
                                                            ),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              'Top',
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),

                                              // Restaurant Details
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        rest['name'],
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: Colors.green,
                                                              borderRadius:
                                                              BorderRadius.circular(8),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                const Icon(
                                                                  Icons.star,
                                                                  color: Colors.white,
                                                                  size: 14,
                                                                ),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  '${rest['rating']}',
                                                                  style: const TextStyle(
                                                                    color: Colors.white,
                                                                    fontWeight:
                                                                    FontWeight.bold,
                                                                    fontSize: 13,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              rest['cuisine'],
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                color: Colors.grey[600],
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.access_time,
                                                            size: 14,
                                                            color: Colors.grey[600],
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            rest['deliveryTime'],
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey[600],
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Icon(
                                                            Icons.location_on,
                                                            size: 14,
                                                            color: Colors.grey[600],
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            rest['distance'],
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
                                              ),

                                              // Action Button
                                              Container(
                                                margin: const EdgeInsets.only(right: 12),
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      _navigateToMenu(rest),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.deepOrange,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                      BorderRadius.circular(12),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Order',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
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
                        ],
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
