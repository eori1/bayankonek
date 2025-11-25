import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();
  bool _uploadingPhoto = false;

  CollectionReference<Map<String, dynamic>> get _userCollection =>
      _firestore.collection('Users');

  Future<void> _ensureProfileExists(User user) async {
    final doc = await _userCollection.doc(user.uid).get();
    if (!doc.exists) {
      await _userCollection.doc(user.uid).set({
        'fullName': user.displayName ?? 'Citizen',
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'residentId': '#RES-${user.uid.substring(0, 6).toUpperCase()}',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _updateProfileFields(
    User user, {
    Map<String, dynamic> data = const {},
  }) async {
    await _ensureProfileExists(user);
    await _userCollection.doc(user.uid).set(
          {
            ...data,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
  }

  Future<void> _pickProfilePhoto(
    User user,
    Map<String, dynamic> profile,
  ) async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final file = File(picked.path);
      final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await user.updatePhotoURL(url);
      await _updateProfileFields(user, data: {'photoUrl': url});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  Future<void> _openEditProfileSheet(
    User user,
    Map<String, dynamic> profile,
  ) async {
    final nameController =
        TextEditingController(text: profile['fullName'] ?? user.displayName ?? '');
    final emailController =
        TextEditingController(text: profile['email'] ?? user.email ?? '');
    final residentIdController =
        TextEditingController(text: profile['residentId'] ?? '#RES-${user.uid.substring(0, 6).toUpperCase()}');
    final addressController =
        TextEditingController(text: profile['address'] ?? '');

    String _normalizePhone(String raw) {
      String digits = raw.replaceAll(RegExp(r'[\s-]'), '');
      if (digits.startsWith('+')) return digits;
      digits = digits.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.startsWith('63')) return '+$digits';
      if (digits.startsWith('0')) return '+63${digits.substring(1)}';
      return '+63$digits';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Profile',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 20),
              _ProfileTextField(
                controller: nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _ProfileTextField(
                controller: emailController,
                label: 'Email',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _ProfileTextField(
                controller: residentIdController,
                label: 'Resident ID',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),
              _ProfileTextField(
                controller: addressController,
                label: 'Address',
                icon: Icons.home_outlined,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    FocusScope.of(ctx).unfocus();
                    await _updateProfileFields(user, data: {
                      'fullName': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'residentId': residentIdController.text.trim(),
                      'address': addressController.text.trim(),
                    });
                    if (nameController.text.trim().isNotEmpty) {
                      await user.updateDisplayName(nameController.text.trim());
                    }
                    if (emailController.text.trim().isNotEmpty &&
                        emailController.text.trim() != user.email) {
                      try {
                        await user.updateEmail(emailController.text.trim());
                      } catch (_) {}
                    }
                    if (!mounted) return;
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F75FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _linkMobileNumber(User user) async {
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    final codeController = TextEditingController();
    String? verificationId;
    bool isSending = false;
    bool codeSent = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
              Future<void> sendCode() async {
              final raw = phoneController.text.trim();
              if (raw.isEmpty) return;
              final formatted = _normalizePhone(raw);
              setModalState(() {
                isSending = true;
              });
              try {
                await FirebaseAuth.instance.verifyPhoneNumber(
                  phoneNumber: formatted,
                  verificationCompleted: (_) {},
                  verificationFailed: (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message ?? 'Verification failed')),
                    );
                  },
                  codeSent: (id, _) {
                    setModalState(() {
                      verificationId = id;
                      codeSent = true;
                    });
                  },
                  codeAutoRetrievalTimeout: (id) {
                    verificationId = id;
                  },
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send code: $e')),
                );
              } finally {
                setModalState(() {
                  isSending = false;
                });
              }
            }

            Future<void> verifyCode() async {
              if (verificationId == null || codeController.text.length < 6) {
                return;
              }
              final formatted = _normalizePhone(phoneController.text.trim());
              setModalState(() => isSending = true);
              try {
                final credential = PhoneAuthProvider.credential(
                  verificationId: verificationId!,
                  smsCode: codeController.text.trim(),
                );
                await AuthService.instance.linkPhoneCredential(credential);
                await _updateProfileFields(
                  user,
                  data: {'phoneNumber': formatted},
                );
                if (!mounted) return;
                Navigator.of(ctx).pop();
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.message ?? 'Invalid code')),
                );
              } finally {
                setModalState(() => isSending = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Link Mobile Number',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _ProfileTextField(
                    controller: phoneController,
                    label: 'Mobile Number (+63...)',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  if (codeSent)
                    _ProfileTextField(
                      controller: codeController,
                      label: 'Verification Code',
                      icon: Icons.lock_outline,
                      keyboardType: TextInputType.number,
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSending
                          ? null
                          : codeSent
                              ? verifyCode
                              : sendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F75FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              codeSent ? 'Verify Code' : 'Send Code',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    await AuthService.instance.logOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _ProfileScaffold(
        embedded: widget.embedded,
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Sign in to manage your profile'),
          ),
        ),
      );
    }

    final profileStream = _userCollection.doc(user.uid).snapshots();
    final requestsStream = _firestore
        .collection('Requests')
        .where('userId', isEqualTo: user.uid)
        .snapshots();

    return _ProfileScaffold(
      embedded: widget.embedded,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: profileStream,
        builder: (context, snapshot) {
          final profile = snapshot.data?.data() ?? {};
          final photoUrl =
              profile['photoUrl'] as String? ?? user.photoURL ?? '';
          final fullName =
              profile['fullName']?.toString() ?? user.displayName ?? 'Citizen';
          final residentId = profile['residentId']?.toString() ??
              '#RES-${user.uid.substring(0, 6).toUpperCase()}';
          final email =
              profile['email']?.toString() ?? user.email ?? 'Not set';
          final phone =
              profile['phoneNumber']?.toString() ?? user.phoneNumber ?? 'Not linked';
          final address = profile['address']?.toString() ?? 'Add your address';

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              children: [
                _ProfileHeader(
                  name: fullName,
                  residentId: residentId,
                  photoUrl: photoUrl,
                  uploadingPhoto: _uploadingPhoto,
                  onChangePhoto: () => _pickProfilePhoto(user, profile),
                  onEdit: () => _openEditProfileSheet(user, profile),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: requestsStream,
                  builder: (context, requestSnapshot) {
                    final docs = requestSnapshot.data?.docs ?? [];
                    final active = docs.where((doc) {
                      final status =
                          (doc.data()['status'] ?? '').toString().toLowerCase();
                      return status != 'completed' && status != 'ready';
                    }).length;
                    final completed = docs.where((doc) {
                      final status =
                          (doc.data()['status'] ?? '').toString().toLowerCase();
                      return status == 'ready' || status == 'completed';
                    }).length;
                    final pendingPayments = docs.where((doc) {
                      final status =
                          (doc.data()['status'] ?? '').toString().toLowerCase();
                      return status == 'payment_pending';
                    }).length;
                    return _StatsRow(
                      active: active,
                      completed: completed,
                      pending: pendingPayments,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _ContactInfoCard(
                  email: email,
                  phone: phone,
                  address: address,
                  onEdit: () => _openEditProfileSheet(user, profile),
                  onLinkPhone: () => _linkMobileNumber(user),
                ),
                const SizedBox(height: 16),
                _QuickLinksCard(
                  links: const [
                    _QuickLink(icon: Icons.person_outline, label: 'Personal Information'),
                    _QuickLink(icon: Icons.folder_open_outlined, label: 'My Documents'),
                    _QuickLink(icon: Icons.notifications_outlined, label: 'Notifications'),
                    _QuickLink(icon: Icons.help_outline, label: 'Help & Support'),
                  ],
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE74C3C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileScaffold extends StatelessWidget {
  const _ProfileScaffold({required this.embedded, required this.child});

  final bool embedded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return ColoredBox(
        color: const Color(0xFFF5F6FA),
        child: SafeArea(child: child),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(child: child),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.residentId,
    required this.photoUrl,
    required this.uploadingPhoto,
    required this.onChangePhoto,
    required this.onEdit,
  });

  final String name;
  final String residentId;
  final String photoUrl;
  final bool uploadingPhoto;
  final VoidCallback onChangePhoto;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 60),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F75FF), Color(0xFF1250D5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? const Icon(Icons.person_outline, size: 48, color: Color(0xFF1F75FF))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: uploadingPhoto ? null : onChangePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: uploadingPhoto
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Resident ID: $residentId',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.edit_outlined, size: 16, color: Color(0xFF1F75FF)),
                      SizedBox(width: 6),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Color(0xFF1F75FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.active,
    required this.completed,
    required this.pending,
  });

  final int active;
  final int completed;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.description_outlined,
              label: 'Active Requests',
              value: active.toString(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.verified_outlined,
              label: 'Completed',
              value: completed.toString(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.calendar_today_outlined,
              label: 'Pending Payments',
              value: pending.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF1F75FF)),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF7A8193)),
          ),
        ],
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard({
    required this.email,
    required this.phone,
    required this.address,
    required this.onEdit,
    required this.onLinkPhone,
  });

  final String email;
  final String phone;
  final String address;
  final VoidCallback onEdit;
  final VoidCallback onLinkPhone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF1F75FF)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ContactRow(
              icon: Icons.mail_outline,
              label: 'Email',
              value: email,
            ),
            const SizedBox(height: 12),
            _ContactRow(
              icon: Icons.phone_outlined,
              label: 'Mobile Number',
              value: phone,
              actionLabel: phone == 'Not linked' ? 'Link' : 'Update',
              onActionTap: onLinkPhone,
            ),
            const SizedBox(height: 12),
            _ContactRow(
              icon: Icons.home_outlined,
              label: 'Address',
              value: address,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF1F75FF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF7A8193),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1F1F1F),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _QuickLinksCard extends StatelessWidget {
  const _QuickLinksCard({required this.links});

  final List<_QuickLink> links;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: links
              .map(
                (link) => Column(
                  children: [
                    ListTile(
                      leading: Icon(link.icon, color: const Color(0xFF1F75FF)),
                      trailing: const Icon(Icons.chevron_right),
                      title: Text(
                        link.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () {},
                    ),
                    if (link != links.last)
                      const Divider(height: 0, indent: 16, endIndent: 16),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _QuickLink {
  const _QuickLink({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

