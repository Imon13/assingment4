import 'dart:convert';

import 'package:assingment4/product_model.dart';
import 'package:assingment4/update_product_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'add_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool _getProductListInProgress = false;
  List<ProductModel> productList = [];

  @override
  void initState() {
    super.initState();
    _getProductList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product list'),
      ),
      body: RefreshIndicator(
        onRefresh: _getProductList,
        child: Visibility(
          visible: _getProductListInProgress == false,
          replacement: const Center(
            child: CircularProgressIndicator(),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double itemWidth = (constraints.maxWidth / 4) - 16; // Adjust crossAxisCount here
              final double itemHeight = itemWidth * 1.5;

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // Increase to make items narrower
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.7, // Increase this value to make items shorter
                ),
                itemCount: productList.length,
                itemBuilder: (context, index) {
                  return _buildProductItem(productList[index], itemWidth, itemHeight);
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _getProductList() async {
    _getProductListInProgress = true;
    setState(() {});
    productList.clear();
    const String productListUrl = 'https://crud.teamrabbil.com/api/v1/ReadProduct';
    Uri uri = Uri.parse(productListUrl);
    Response response = await get(uri);
    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      final jsonProductList = decodedData['data'];
      for (Map<String, dynamic> json in jsonProductList) {
        ProductModel productModel = ProductModel.fromJson(json);
        productList.add(productModel);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Get product list failed! Try again.')),
      );
    }

    _getProductListInProgress = false;
    setState(() {});
  }

  Widget _buildProductItem(ProductModel product, double width, double height) {
    return Card(
      elevation: 2.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.image != null && product.image!.isNotEmpty)
            Image.network(
              product.image!,
              height: height * 0.5,
              width: width,
              fit: BoxFit.cover,
            )
          else
            Container(
              height: height * 0.5,
              width: width,
              color: Colors.grey,
              child: const Icon(Icons.image, color: Colors.white),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              product.productName ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('Unit Price: ${product.unitPrice}'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('Quantity: ${product.quantity}'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('Total Price: ${product.totalPrice}'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdateProductScreen(
                        product: product,
                      ),
                    ),
                  );
                  if (result == true) {
                    _getProductList();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_sharp),
                onPressed: () {
                  _showDeleteConfirmationDialog(product.id!);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String productId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete'),
          content: const Text('Are you sure that you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteProduct(productId);
                Navigator.pop(context);
              },
              child: const Text('Yes, delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(String productId) async {
    _getProductListInProgress = true;
    setState(() {});
    String deleteProductUrl =
        'https://crud.teamrabbil.com/api/v1/DeleteProduct/$productId';
    Uri uri = Uri.parse(deleteProductUrl);
    Response response = await get(uri);
    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 200) {
      _getProductList();
    } else {
      _getProductListInProgress = false;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete product failed! Try again.')),
      );
    }
  }
}
