import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rapidbite/database/database_helper.dart';

class OrderUpdatePage extends StatefulWidget {
  final int userId;
  final int orderId;
  final LatLng restaurantPosition;

  const OrderUpdatePage({
    Key? key,
    required this.userId,
    required this.orderId,
    required this.restaurantPosition,
  }) : super(key: key);

  @override
  _OrderUpdatePageState createState() => _OrderUpdatePageState();
}

class _OrderUpdatePageState extends State<OrderUpdatePage>
    with SingleTickerProviderStateMixin {
  late GoogleMapController _mapController;
  LatLng? _currentPosition;
  final dbHelper = DatabaseHelper();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  String currentStatus = 'Pending';
  Timer? _statusTimer;
  Timer? _autoProgressTimer; // New timer for auto-progression
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _statusList = [
    {
      'status': 'Pending',
      'icon': Icons.pending_actions,
      'label': 'Order Placed',
      'description': 'Your order has been received',
    },
    {
      'status': 'Accepted',
      'icon': Icons.check_circle_outline,
      'label': 'Order Accepted',
      'description': 'Restaurant confirmed your order',
    },
    {
      'status': 'Preparing',
      'icon': Icons.restaurant,
      'label': 'Being Prepared',
      'description': 'Chef is cooking your food',
    },
    {
      'status': 'Ready',
      'icon': Icons.done_all,
      'label': 'Ready for Pickup',
      'description': 'Your order is ready',
    },
    {
      'status': 'Out for Delivery',
      'icon': Icons.delivery_dining,
      'label': 'Out for Delivery',
      'description': 'Driver is on the way',
    },
    {
      'status': 'Delivered',
      'icon': Icons.check_circle,
      'label': 'Delivered',
      'description': 'Enjoy your meal!',
    },
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadOrderStatus();
    _setCurrentLocation();

    // Poll for status updates every 5 seconds (for manual updates from owner)
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadOrderStatus();
    });

    // Auto-progress through statuses every 4 seconds
    _startAutoProgress();
  }

  void _startAutoProgress() {
    _autoProgressTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      int currentIndex = _getCurrentStatusIndex();

      // Stop if we've reached the last status or if cancelled
      if (currentIndex >= _statusList.length - 1 || currentStatus == 'Cancelled') {
        _autoProgressTimer?.cancel();
        _statusTimer?.cancel();
        _pulseController.stop();
        return;
      }

      // Move to next status
      String nextStatus = _statusList[currentIndex + 1]['status'];

      // Update in database
      await dbHelper.updateOrderStatus(widget.orderId, nextStatus);

      // Update UI
      if (mounted) {
        setState(() {
          currentStatus = nextStatus;
        });
      }

      // Stop progression when delivered
      if (nextStatus == 'Delivered') {
        _autoProgressTimer?.cancel();
        _statusTimer?.cancel();
        _pulseController.stop();
      }
    });
  }

  Future<void> _loadOrderStatus() async {
    final order = await dbHelper.getOrder(widget.orderId);
    if (order != null && mounted) {
      setState(() {
        currentStatus = order['status'];
      });

      // Stop polling if delivered or cancelled
      if (currentStatus == 'Delivered' || currentStatus == 'Cancelled') {
        _statusTimer?.cancel();
        _autoProgressTimer?.cancel();
        _pulseController.stop();
      }
    }
  }

  Future<void> _setCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      _updateMarkersAndRoute();
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _updateMarkersAndRoute() {
    if (_currentPosition == null) return;

    final restaurantMarker = Marker(
      markerId: const MarkerId('restaurant'),
      position: widget.restaurantPosition,
      infoWindow: const InfoWindow(title: 'Restaurant Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    final userMarker = Marker(
      markerId: const MarkerId('user'),
      position: _currentPosition!,
      infoWindow: const InfoWindow(title: 'Your Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: [_currentPosition!, widget.restaurantPosition],
      color: Colors.deepOrange,
      width: 5,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
    );

    setState(() {
      _markers = {restaurantMarker, userMarker};
      _polylines = {polyline};
    });

    _moveCameraToBounds();
  }

  void _moveCameraToBounds() {
    if (_currentPosition == null) return;

    LatLng southwest = LatLng(
      _currentPosition!.latitude < widget.restaurantPosition.latitude
          ? _currentPosition!.latitude
          : widget.restaurantPosition.latitude,
      _currentPosition!.longitude < widget.restaurantPosition.longitude
          ? _currentPosition!.longitude
          : widget.restaurantPosition.longitude,
    );
    LatLng northeast = LatLng(
      _currentPosition!.latitude > widget.restaurantPosition.latitude
          ? _currentPosition!.latitude
          : widget.restaurantPosition.latitude,
      _currentPosition!.longitude > widget.restaurantPosition.longitude
          ? _currentPosition!.longitude
          : widget.restaurantPosition.longitude,
    );

    LatLngBounds bounds = LatLngBounds(southwest: southwest, northeast: northeast);

    _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _autoProgressTimer?.cancel(); // Cancel auto-progress timer
    _pulseController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMarkersAndRoute();
  }

  int _getCurrentStatusIndex() {
    return _statusList.indexWhere((s) => s['status'] == currentStatus);
  }

  Color _getStatusColor() {
    if (currentStatus == 'Cancelled') return Colors.red;
    if (currentStatus == 'Delivered') return Colors.green;
    return Colors.orange;
  }

  Widget _buildStatusIndicator() {
    int currentIndex = _getCurrentStatusIndex();
    bool isCompleted = currentStatus == 'Delivered';
    bool isCancelled = currentStatus == 'Cancelled';

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Auto-refresh indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor().withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Icon(
                    Icons.fiber_manual_record,
                    size: 12,
                    color: _getStatusColor(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isCompleted
                      ? 'Order Completed'
                      : isCancelled
                      ? 'Order Cancelled'
                      : 'Live Tracking',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Status Timeline
          ...List.generate(_statusList.length, (index) {
            final statusItem = _statusList[index];
            bool isActive = index == currentIndex;
            bool isCompleted = index < currentIndex;
            bool isCancelledStatus = isCancelled && index >= currentIndex;

            Color iconColor;
            Color lineColor;
            Color textColor;

            if (isCancelledStatus) {
              iconColor = Colors.red;
              lineColor = Colors.red.shade200;
              textColor = Colors.red;
            } else if (isCompleted) {
              iconColor = Colors.green;
              lineColor = Colors.green.shade200;
              textColor = Colors.black87;
            } else if (isActive) {
              iconColor = Colors.orange;
              lineColor = Colors.orange.shade200;
              textColor = Colors.black87;
            } else {
              iconColor = Colors.grey.shade300;
              lineColor = Colors.grey.shade200;
              textColor = Colors.grey;
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline indicator
                    Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: iconColor.withOpacity(0.2),
                            border: Border.all(
                              color: iconColor,
                              width: isActive ? 3 : 2,
                            ),
                          ),
                          child: isActive
                              ? ScaleTransition(
                            scale: _pulseAnimation,
                            child: Icon(
                              statusItem['icon'],
                              color: iconColor,
                              size: 24,
                            ),
                          )
                              : Icon(
                            isCompleted ? Icons.check : statusItem['icon'],
                            color: iconColor,
                            size: 24,
                          ),
                        ),
                        if (index < _statusList.length - 1)
                          Container(
                            width: 3,
                            height: 50,
                            color: lineColor,
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Status details
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusItem['label'],
                              style: TextStyle(
                                fontSize: isActive ? 18 : 16,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              statusItem['description'],
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                            if (isActive && !isCompleted && !isCancelled)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _getStatusColor(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'In Progress...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: _getStatusColor(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (index < _statusList.length - 1) const SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isCompleted = currentStatus == 'Delivered';
    bool isCancelled = currentStatus == 'Cancelled';

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
              Container(
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
                                'Track Your Order',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Order #${widget.orderId}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _loadOrderStatus,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      child: Row(
                        children: [
                          Icon(
                            isCancelled
                                ? Icons.cancel
                                : isCompleted
                                ? Icons.check_circle
                                : Icons.local_shipping,
                            size: 32,
                            color: _getStatusColor(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentStatus,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(),
                                  ),
                                ),
                                Text(
                                  isCancelled
                                      ? 'Order was cancelled'
                                      : isCompleted
                                      ? 'Your order has been delivered'
                                      : 'Auto-updating every 4 seconds',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Map Section
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
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
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: widget.restaurantPosition,
                            zoom: 14,
                          ),
                          markers: _markers,
                          polylines: _polylines,
                          myLocationEnabled: false,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                        ),

                        // Legend
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.restaurant, color: Colors.orange, size: 16),
                                    SizedBox(width: 8),
                                    Text('Restaurant', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: const [
                                    Icon(Icons.location_on, color: Colors.green, size: 16),
                                    SizedBox(width: 8),
                                    Text('Your Location', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Status Timeline
              Expanded(
                flex: 3,
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
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildStatusIndicator(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Button
              if (isCompleted || isCancelled)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.deepOrange,
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.home, size: 24),
                    label: const Text(
                      'Back to Dashboard',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/dashboard',
                        arguments: widget.userId,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
