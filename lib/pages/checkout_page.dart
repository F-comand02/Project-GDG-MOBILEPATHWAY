// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final VoidCallback onOrderPlaced;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.onOrderPlaced,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _paymentMethod = 'Cash';
  bool _isSubmitting = false;

  int get totalPrice =>
      widget.cartItems.fold(0, (previous, item) => previous + item.total);
  int get totalItems =>
      widget.cartItems.fold(0, (previous, item) => previous + item.quantity);

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _emailController.text = user?.email ?? '';
    _nameController.text = user?.displayName ?? '';
  }

  Future<void> _placeOrder() async {
    if (widget.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang kosong. Tambahkan produk terlebih dahulu.'),
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || address.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama, alamat, dan nomor telepon wajib diisi.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final orderData = {
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'userEmail': _emailController.text.trim(),
      'customerName': name,
      'phone': phone,
      'address': address,
      'notes': _notesController.text.trim(),
      'paymentMethod': _paymentMethod,
      'totalItems': totalItems,
      'totalPrice': totalPrice,
      'orderedAt': FieldValue.serverTimestamp(),
      'items': widget.cartItems
          .map(
            (item) => {
              'productId': item.productId,
              'name': item.name,
              'category': item.category,
              'price': item.price,
              'quantity': item.quantity,
              'imageUrl': item.imageUrl,
              'lineTotal': item.total,
            },
          )
          .toList(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .add(orderData)
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () {
              throw Exception(
                'Waktu tunggu checkout habis. Periksa koneksi Anda dan coba lagi.',
              );
            },
          );
      widget.onOrderPlaced();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Pesanan Berhasil'),
            content: const Text(
              'Order Anda telah dikirim. Terima kasih telah berbelanja!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat pesanan: $e')));
      }
    }
  }

  Widget _buildSummaryTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ringkasan Pesanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _buildSummaryTile('Jumlah Produk', '$totalItems'),
                  _buildSummaryTile('Total Harga', 'Rp $totalPrice'),
                  const Divider(height: 24, thickness: 1),
                  ...widget.cartItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.name} x${item.quantity}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            'Rp ${item.total}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Detail Pengiriman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Penerima',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Alamat Pengiriman',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Metode Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                RadioListTile<String>(
                  value: 'Cash',
                  groupValue: _paymentMethod,
                  title: const Text('Bayar di tempat (Cash)'),
                  onChanged: (value) {
                    if (value != null) setState(() => _paymentMethod = value);
                  },
                ),
                RadioListTile<String>(
                  value: 'Debit / Credit',
                  groupValue: _paymentMethod,
                  title: const Text('Debit / Credit Card'),
                  onChanged: (value) {
                    if (value != null) setState(() => _paymentMethod = value);
                  },
                ),
                RadioListTile<String>(
                  value: 'E-Wallet',
                  groupValue: _paymentMethod,
                  title: const Text('E-Wallet'),
                  onChanged: (value) {
                    if (value != null) setState(() => _paymentMethod = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan Tambahan (opsional)',
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Place Order', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
