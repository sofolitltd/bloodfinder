import 'package:bloodfinder/data/models/user_model.dart';
import 'package:bloodfinder/features/widgets/start_chat_btn.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FindDonorPage extends StatefulWidget {
  final String bloodGroup;
  final String? district; // ✅ now optional
  final String? subdistrict;

  const FindDonorPage({
    super.key,
    required this.bloodGroup,
    this.district,
    this.subdistrict,
  });

  @override
  State<FindDonorPage> createState() => _FindDonorPageState();
}

class _FindDonorPageState extends State<FindDonorPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _donors = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchDonors();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchDonors();
      }
    });
  }

  Future<void> _fetchDonors() async {
    if (!_hasMore) return;

    setState(() => _isLoading = true);

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('users')
          .where('isDonor', isEqualTo: true)
          .where('bloodGroup', isEqualTo: widget.bloodGroup)
          .orderBy('firstName')
          .limit(_pageSize);

      // ✅ District optional
      if (widget.district?.isNotEmpty ?? false) {
        query = query.where('district', isEqualTo: widget.district);
      }

      // ✅ Subdistrict optional
      if (widget.subdistrict?.isNotEmpty ?? false) {
        query = query.where('subdistrict', isEqualTo: widget.subdistrict);
      }

      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
        _donors.addAll(snapshot.docs.map((e) => e.data()).toList());
      }

      if (snapshot.docs.length < _pageSize) {
        _hasMore = false;
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error fetching donors: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Donors'), centerTitle: true),
      body: _donors.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _donors.isEmpty
          ? const Center(child: Text('No donors found'))
          : ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _donors.length + (_hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index == _donors.length) {
                  return const Center(child: CircularProgressIndicator());
                }

                UserModel donor = UserModel.fromJson(_donors[index]);

                //
                return _buildDonorListItem(donor: donor);
              },
            ),
    );
  }

  Widget _buildDonorListItem({required UserModel donor}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              CircleAvatar(
                child: donor.image.isEmpty
                    ? Text(
                        donor.firstName[0].toUpperCase(),
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: CachedNetworkImage(
                          imageUrl: donor.image,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              CupertinoActivityIndicator(),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error, color: Colors.red),
                        ),
                      ),
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${donor.firstName} ${donor.lastName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${donor.currentAddress}, ${donor.subdistrict}, ${donor.district}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: StartChatButton(otherUserId: donor.uid),
                        ),
                        Expanded(flex: 2, child: SizedBox()),
                      ],
                    ),
                  ],
                ),
              ),

              //
            ],
          ),
        ),

        //
        Positioned(
          right: 12,
          top: 12,
          child: Container(
            padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),

            child: Center(
              child: Text(
                donor.bloodGroup,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  // height: 1,
                  // fontSize: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
