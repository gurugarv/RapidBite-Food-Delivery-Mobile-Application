import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rapidbite/database/database_helper.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PaymentPage extends StatefulWidget {
  final int userId;
  final double totalAmount;
  final Map<String, int> cart;
  final List<dynamic> menuItems;
  final LatLng? restaurantPosition;
  final String? restaurantName;

  const PaymentPage({
    Key? key,
    required this.userId,
    required this.totalAmount,
    required this.cart,
    required this.menuItems,
    this.restaurantPosition,
    this.restaurantName,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  late Razorpay _razorpay;
  final dbHelper = DatabaseHelper();
  bool _isProcessing = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

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
    _razorpay.clear();
    super.dispose();
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundColor == Colors.green
                  ? Icons.check_circle
                  : backgroundColor == Colors.red
                  ? Icons.error
                  : Icons.info,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isProcessing = true;
    });

    final orderDetails = widget.cart.entries.map((e) {
      final item = widget.menuItems.firstWhere((i) => i['item_name'] == e.key);
      return {
        'name': e.key,
        'quantity': e.value,
        'price': item['price'],
      };
    }).toList();

    final newOrderId = await dbHelper.addOrder(
      userId: widget.userId,
      restaurant: widget.restaurantName ?? 'Unknown Restaurant',
      orderDate: DateTime.now().toIso8601String(),
      total: widget.totalAmount,
      status: 'Pending',
      details: jsonEncode(orderDetails),
      paymentId: response.paymentId,
      restaurantLat: widget.restaurantPosition?.latitude,
      restaurantLng: widget.restaurantPosition?.longitude,
    );

    _showSnackBar('Payment successful! 🎉', Colors.green);

    await Future.delayed(const Duration(milliseconds: 800));

    Navigator.pushReplacementNamed(
      context,
      '/order_update',
      arguments: {
        'userId': widget.userId,
        'restaurantPosition': widget.restaurantPosition,
        'orderId': newOrderId,
      },
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessing = false;
    });
    _showSnackBar('Payment failed: ${response.message}', Colors.red);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showSnackBar('Processing with ${response.walletName}', Colors.blue);
  }

  void startPayment() {
    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag',
      'amount': (widget.totalAmount * 100).toInt(),
      'name': 'RapidBite',
      'description': 'Order from ${widget.restaurantName}',
      'prefill': {'contact': '9999999999', 'email': 'user@example.com'},
      'theme': {'color': '#FF5722'},
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      _showSnackBar('Error opening payment gateway', Colors.red);
      print(e);
    }
  }

  void _testPayment() async {
    setState(() {
      _isProcessing = true;
    });

    final orderDetails = widget.cart.entries.map((e) {
      final item = widget.menuItems.firstWhere((i) => i['item_name'] == e.key);
      return {
        'name': e.key,
        'quantity': e.value,
        'price': item['price'],
      };
    }).toList();

    final newOrderId = await dbHelper.addOrder(
      userId: widget.userId,
      restaurant: widget.restaurantName ?? 'Unknown Restaurant',
      orderDate: DateTime.now().toIso8601String(),
      total: widget.totalAmount,
      status: 'Pending',
      details: jsonEncode(orderDetails),
      paymentId: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
      restaurantLat: widget.restaurantPosition?.latitude,
      restaurantLng: widget.restaurantPosition?.longitude,
    );

    _showSnackBar('Test order placed successfully! 🎉', Colors.green);

    await Future.delayed(const Duration(milliseconds: 800));

    Navigator.pushReplacementNamed(
      context,
      '/order_update',
      arguments: {
        'userId': widget.userId,
        'restaurantPosition': widget.restaurantPosition,
        'orderId': newOrderId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
                    const Text(
                      'Payment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Payment Icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade100,
                                    Colors.red.shade100,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.payment,
                                size: 60,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Restaurant Info
                            Text(
                              'Order from',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.restaurantName ?? 'Restaurant',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Amount Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade50,
                                    Colors.red.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '₹',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                      Text(
                                        widget.totalAmount.toStringAsFixed(2),
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Order Items Summary
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.shopping_bag, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Order Summary',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...widget.cart.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${entry.key} x${entry.value}',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '₹${(widget.menuItems.firstWhere((i) => i['item_name'] == entry.key)['price'] * entry.value).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Payment Methods
                            const Text(
                              'Select Payment Method',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Razorpay Payment Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _isProcessing ? null : startPayment,
                                icon: _isProcessing
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Icon(Icons.payment, size: 24),
                                label: Text(
                                  _isProcessing ? 'Processing...' : 'Pay with Razorpay',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Test Payment Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _isProcessing ? null : _testPayment,
                                icon: const Icon(Icons.developer_mode, size: 24),
                                label: const Text(
                                  'Test Order (Skip Payment)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.deepOrange,
                                  side: const BorderSide(
                                    color: Colors.deepOrange,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Security Info
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.security,
                                    color: Colors.green.shade700,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Your payment is secured with 256-bit encryption',
                                      style: TextStyle(
                                        color: Colors.green.shade900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }
}
