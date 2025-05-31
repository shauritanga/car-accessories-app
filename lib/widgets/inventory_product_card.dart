import 'package:cached_network_image/cached_network_image.dart';
import 'package:car_accessories/models/inventory_model.dart';

import 'package:flutter/material.dart';

class InventoryProductCard extends StatelessWidget {
  const InventoryProductCard({
    required this.inventory,
    required this.onPressed,
    super.key,
  });
  final InventoryModel inventory;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color.fromARGB(255, 102, 17, 17),
            ),
            child: CachedNetworkImage(
              imageUrl:
                  "https://images.unsplash.com/photo-1726867545994-94931774df68?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8ZW5naW5lfGVufDB8fDB8fHww",

              fit: BoxFit.fill,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "Product Name",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Store: ${inventory.stock}"),
                  IconButton(icon: Icon(Icons.edit), onPressed: onPressed),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
