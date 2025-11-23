import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/app_bottom_nav.dart';
import 'location_picker_page.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  final List<String> _categories = const [
    'Broken Street Light',
    'Garbage Not Collected',
    'Road Damage',
    'Water Supply',
    'Noise Complaint',
    'Other',
  ];

  String? _selectedCategory;
  bool _isSubmitting = false;
  final List<XFile> _photos = [];
  final ImagePicker _picker = ImagePicker();
  LatLng? _selectedLatLng;

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(builder: (_) => const LocationPickerPage()),
    );
    if (result != null) {
      setState(() {
        _locationController.text = result.address;
        _selectedLatLng = result.latLng;
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (picked != null) {
      setState(() {
        if (_photos.length < 4) {
          _photos.add(picked);
        } else {
          _showSnack('You can upload up to 4 photos.');
        }
      });
    }
  }

  Future<List<String>> _uploadPhotos(String issueId) async {
    if (_photos.isEmpty) return [];
    final storage = FirebaseStorage.instance;
    final urls = <String>[];

    for (final photo in _photos) {
      final file = File(photo.path);
      final ref = storage
          .ref()
          .child('issue_photos/$issueId/${DateTime.now().millisecondsSinceEpoch}_${photo.name}');
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final issueId = 'ISS-${DateTime.now().millisecondsSinceEpoch}';
    final userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      final photoUrls = await _uploadPhotos(issueId);
      await FirebaseFirestore.instance.collection('Issues').doc(issueId).set({
        'issueId': issueId,
        'category': _selectedCategory,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'contact': _contactController.text.trim(),
        'status': 'in_progress',
        'createdAt': FieldValue.serverTimestamp(),
        if (userId != null) 'userId': userId,
    if (_selectedLatLng != null)
          'coordinates': GeoPoint(
            _selectedLatLng!.latitude,
            _selectedLatLng!.longitude,
          ),
        'photoUrls': photoUrls,
      });

      if (!mounted) return;
      _resetForm();
      _showSnack('Issue submitted successfully!');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to submit report: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _locationController.clear();
    _descriptionController.clear();
    _contactController.clear();
    _selectedCategory = null;
    _photos.clear();
    _selectedLatLng = null;
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Photo',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xFF1F1F1F),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Report Issue',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoCard(),
              const SizedBox(height: 20),
              _buildForm(),
              const SizedBox(height: 16),
              _PhotoPickerGrid(
                photos: _photos,
                onAddPhoto: _showPhotoOptions,
                onRemovePhoto: (index) {
                  setState(() => _photos.removeAt(index));
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F6FE3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 6,
                  ),
                  onPressed: _isSubmitting ? null : _submitReport,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.send_outlined, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Submit Report',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 28),
              _RecentReportsList(userId: userId),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onItemSelected: (index) {
          if (index == 0) Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  Widget _buildForm() {
    InputDecoration decoration(String hint) {
      return InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE0E6F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF1F6FE3)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      );
    }

    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Issue Details',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Issue Category',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF555E6C),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: decoration('Select issue type'),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
              validator: (value) =>
                  value == null ? 'Please select an issue category' : null,
            ),
            const SizedBox(height: 18),
            const Text(
              'Location',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF555E6C),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              readOnly: false,
              decoration: decoration('Enter specific location'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Location is required' : null,
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openLocationPicker,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Select on Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1F6FE3),
                  side: const BorderSide(color: Color(0xFFBFD7FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF555E6C),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: decoration('Describe the issue in detail...'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 18),
            const Text(
              'Contact Number',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF555E6C),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              decoration: decoration('+63 9XX XXX XXXX'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Contact number is required' : null,
            ),
            const SizedBox(height: 18),
            const Text(
              'Add Photos (Optional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF555E6C),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload up to 4 photos to help us assess the issue faster.',
              style: TextStyle(color: Color(0xFF7A8193)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.place_outlined, color: Color(0xFF1F6FE3)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Report Community Issues',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Help us improve our barangay by reporting issues that need attention.',
                  style: TextStyle(color: Color(0xFF4A5A73), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPickerGrid extends StatelessWidget {
  const _PhotoPickerGrid({
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  final List<XFile> photos;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      GestureDetector(
        onTap: onAddPhoto,
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD3DCE9)),
          ),
          child: const Center(
            child: Icon(Icons.add_a_photo_outlined, color: Color(0xFF1F6FE3)),
          ),
        ),
      ),
    ];

    children.addAll(
      List.generate(
        photos.length,
        (index) => Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 8),
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                image: DecorationImage(
                  image: FileImage(File(photos[index].path)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemovePhoto(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: children),
    );
  }
}

class _RecentReportsList extends StatelessWidget {
  const _RecentReportsList({required this.userId});

  final String? userId;

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final collection = FirebaseFirestore.instance.collection('Issues');
    if (userId == null) {
      return collection
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots();
    }
    return collection.where('userId', isEqualTo: userId).snapshots();
  }

  DateTime _createdAt(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final raw = doc.data()['createdAt'];
    if (raw is Timestamp) {
      return raw.toDate();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return const Color(0xFF4BC28A);
      case 'in_progress':
      case 'processing':
        return const Color(0xFFF4B63A);
      default:
        return const Color(0xFF7A8193);
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return 'Resolved';
      case 'in_progress':
        return 'In Progress';
      default:
        return 'Submitted';
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (diff.inDays >= 1) {
      return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
    } else if (diff.inHours >= 1) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    } else if (diff.inMinutes >= 1) {
      return diff.inMinutes == 1
          ? '1 minute ago'
          : '${diff.inMinutes} minutes ago';
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const _EmptyReportsCard(
        message: 'Sign in to see your recent reports.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _EmptyReportsCard(
              message: 'Unable to load reports right now.',
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const _EmptyReportsCard(
              message: 'No reports yet. Submit one to see it here.',
            );
          }

          final sorted = [...docs]
            ..sort(
              (a, b) => _createdAt(b).compareTo(_createdAt(a)),
            );
          final items = sorted.take(5).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Recent Reports',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 16),
              ...items.map((doc) {
                final data = doc.data();
                final status = (data['status'] ?? 'submitted').toString();
                final location = (data['location'] ?? 'No location').toString();
                final category =
                    (data['category'] ?? 'Community Issue').toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReportTile(
                    title: category,
                    subtitle: '$location • ${_timeAgo(_createdAt(doc))}',
                    status: _statusLabel(status),
                    statusColor: _statusColor(status),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.warning_amber_outlined, color: statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF7A8193)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReportsCard extends StatelessWidget {
  const _EmptyReportsCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF7A8193)),
      ),
    );
  }
}

