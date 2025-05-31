import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final Function(String?) onCategoryChanged;
  final Function(String?) onModelChanged;
  final TextEditingController searchController;

  const FilterBar({
    super.key,
    required this.onCategoryChanged,
    required this.onModelChanged,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Search Accessories',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(
                      value: 'Seat Covers',
                      child: Text('Seat Covers'),
                    ),
                    DropdownMenuItem(
                      value: 'Lighting',
                      child: Text('Lighting'),
                    ),
                    DropdownMenuItem(value: 'Tools', child: Text('Tools')),
                  ],
                  onChanged: onCategoryChanged,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Car Model',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'Toyota', child: Text('Toyota')),
                    DropdownMenuItem(value: 'Honda', child: Text('Honda')),
                    DropdownMenuItem(value: 'Nissan', child: Text('Nissan')),
                  ],
                  onChanged: onModelChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
