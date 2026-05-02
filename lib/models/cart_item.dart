class CartItem {
  final String productId;
  final String name;
  final int price;
  final String? imageUrl;
  final String category;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.category,
    this.quantity = 1,
  });

  int get total => price * quantity;

  CartItem copyWith({
    String? productId,
    String? name,
    int? price,
    String? imageUrl,
    String? category,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
    );
  }
}
