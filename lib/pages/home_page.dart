import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cart_item.dart';
import '../services/auth_service.dart';
import 'cart_page.dart';
import 'form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _auth = AuthService();
  final List<CartItem> _cartItems = [];

  void _addToCart(
    String id,
    String name,
    int price,
    String category,
    String? imageUrl,
  ) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item.productId == id);
      if (index >= 0) {
        _cartItems[index].quantity += 1;
      } else {
        _cartItems.add(
          CartItem(
            productId: id,
            name: name,
            price: price,
            category: category,
            imageUrl: imageUrl,
          ),
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produk ditambahkan ke keranjang')),
    );
  }

  void _updateCart(List<CartItem> items) {
    setState(() {
      _cartItems
        ..clear()
        ..addAll(items);
    });
  }

  String _formatPrice(dynamic priceValue) {
    final price = priceValue is int
        ? priceValue
        : int.tryParse(priceValue?.toString() ?? '') ?? 0;
    return 'Rp $price';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GDG Store',
          style: GoogleFonts.orbitron(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00FFFF),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(
                    cartItems: _cartItems,
                    onCartUpdated: _updateCart,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Keranjang',
          ),
          IconButton(
            onPressed: () async {
              await _auth.logout();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Terjadi kesalahan saat memuat produk.'),
            );
          }

          final products = snapshot.data?.docs ?? [];
          if (products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada produk',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tambahkan produk baru untuk membangun toko belanja Anda.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return AnimationLimiter(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final doc = products[index];
                final data = doc.data();
                final name = data['name'] as String? ?? 'Produk tanpa nama';
                final priceValue = data['price'];
                final price = priceValue is int
                    ? priceValue
                    : int.tryParse(priceValue?.toString() ?? '') ?? 0;
                final description = data['description'] as String? ?? '';
                final category = data['category'] as String? ?? 'Lainnya';
                final imageUrl = data['imageUrl'] as String?;

                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00FFFF), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade800,
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 56,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey.shade800,
                                child: const Icon(
                                  Icons.image,
                                  size: 56,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Chip(
                            label: Text(category),
                            backgroundColor: const Color(0xFF00FFFF).withValues(alpha: 0.2),
                            labelStyle: const TextStyle(color: Color(0xFF00FFFF)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatPrice(price),
                            style: const TextStyle(
                              color: Color(0xFFFF00FF),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FormPage(
                                          id: doc.id,
                                          name: name,
                                          price: price.toString(),
                                          description: description,
                                          category: category,
                                          imageUrl: imageUrl,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00FFFF),
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(80, 38),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('products')
                                      .doc(doc.id)
                                      .delete();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Produk berhasil dihapus',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _addToCart(
                                  doc.id,
                                  name,
                                  price,
                                  category,
                                  imageUrl,
                                ),
                                icon: const Icon(
                                  Icons.add_shopping_cart,
                                  color: Color(0xFF00FF00),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormPage()),
          );
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Tambah Produk'),
      ),
    );
  }
}
