import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final String title;
  final List<String> items;

  const SearchPage({super.key, required this.title, required this.items});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search ${widget.title}'), centerTitle: true),
      body: Column(
        children: [
          SizedBox(height: 8),
          //
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _filterItems('');
                    },
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                onChanged: _filterItems,
              ),
            ),
          ),

          SizedBox(height: 8),
          //
          Expanded(
            child: Card(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on, size: 18),
                    title: Text(item),
                    onTap: () {
                      Navigator.pop(context, item);
                    },
                  );
                },
              ),
            ),
          ),

          SizedBox(height: 8),
        ],
      ),
    );
  }
}
