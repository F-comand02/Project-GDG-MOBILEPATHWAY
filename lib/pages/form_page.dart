import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FormPage extends StatefulWidget {
  final String? id;
  final String? name;
  final String? price;
  final String? description;
  final String? category;
  final String? imageUrl;
  const FormPage({
    super.key,
    this.id,
    this.name,
    this.price,
    this.description,
    this.category,
    this.imageUrl,
  });

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  String _selectedCategory = 'Elektronik';
  bool _isSaving = false;

  final List<String> categories = [
    'Elektronik',
    'Fashion',
    'Makanan',
    'Buku',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _nameController.text = widget.name ?? '';
      _priceController.text = widget.price ?? '';
      _descriptionController.text = widget.description ?? '';
      _imageUrlController.text = widget.imageUrl ?? '';
      _selectedCategory = widget.category ?? 'Elektronik';
    }
    _imageUrlController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final description = _descriptionController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    if (name.isEmpty || priceText.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama dan harga produk wajib diisi.')),
        );
      }
      return;
    }

    final price = int.tryParse(
      priceText.replaceAll(',', '').replaceAll('.', ''),
    );
    if (price == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masukkan harga yang valid.')),
        );
      }
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    final collection = FirebaseFirestore.instance.collection('products');
    try {
      final saveAction = widget.id == null
          ? collection.add({
              'name': name,
              'price': price,
              'description': description,
              'category': _selectedCategory,
              'imageUrl': imageUrl.isEmpty ? null : imageUrl,
              'createdAt': FieldValue.serverTimestamp(),
            })
          : collection.doc(widget.id).update({
              'name': name,
              'price': price,
              'description': description,
              'category': _selectedCategory,
              'imageUrl': imageUrl.isEmpty ? null : imageUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            });

      await saveAction.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          throw Exception(
            'Permintaan simpan terlalu lama. Periksa jaringan Anda dan coba lagi.',
          );
        },
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan produk: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.id != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Produk' : 'Tambah Produk')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                prefixIcon: Icon(Icons.storefront),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga (Rp)',
                prefixIcon: Icon(Icons.price_change),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category),
              ),
              items: categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Produk',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL Gambar Produk',
                prefixIcon: Icon(Icons.image),
                hintText: 'https://example.com/image.jpg',
              ),
            ),
            if (_imageUrlController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 180,
                  color: Colors.grey.shade100,
                  child: Image.network(
                    _imageUrlController.text,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isEditing ? 'Simpan Perubahan' : 'Simpan Produk',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
