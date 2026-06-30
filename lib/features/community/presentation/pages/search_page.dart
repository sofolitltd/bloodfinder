import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

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
          SizedBox(height: 8.h),
          //
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(PhosphorIcons.magnifyingGlass),
                  suffixIcon: IconButton(
                    icon: Icon(PhosphorIcons.x),
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

          SizedBox(height: 8.h),
          //
          Expanded(
            child: Card(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return ListTile(
                    leading: Icon(PhosphorIcons.mapPin, size: 18.w),
                    title: Text(item),
                    onTap: () {
                      Navigator.pop(context, item);
                    },
                  );
                },
              ),
            ),
          ),

          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}
