// edit_profile_screen.dart - FIXED & FULLY RESPONSIVE WITH DARK THEME
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  bool isLoading = false;
  bool isUploadingImage = false;
  String? profileImageUrl;
  File? _imageFile;

  late AnimationController _formController;
  late AnimationController _buttonController;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _buttonScale;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserData();
  }

  void _initAnimations() {
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _formFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _formController, curve: Curves.easeOut));
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
        );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        _firstNameController.text = doc['firstName'] ?? '';
        _lastNameController.text = doc['lastName'] ?? '';
        _emailController.text = user.email ?? '';
        _countryController.text = doc['country'] ?? '';
        _stateController.text = doc['state'] ?? '';
        _cityController.text = doc['city'] ?? '';
        profileImageUrl = doc['profileImageUrl'] as String?;

        _formController.forward();
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _showImageSourceDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Change Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: Text(
                'Camera',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: Colors.purple),
              ),
              title: Text(
                'Gallery',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (profileImageUrl != null || _imageFile != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                title: Text(
                  'Remove Photo',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFile = null;
                    profileImageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _imageFile = File(image.path);
      });
    } catch (e) {
      debugPrint("❌ Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return profileImageUrl;

    setState(() => isUploadingImage = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      await storageRef.putFile(_imageFile!);
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() => isUploadingImage = false);
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ Error uploading image: $e");
      setState(() => isUploadingImage = false);
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    _buttonController.forward().then((_) => _buttonController.reverse());

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? imageUrl = profileImageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage();
      }

      final updateData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'country': _countryController.text.trim(),
        'state': _stateController.text.trim(),
        'city': _cityController.text.trim(),
      };

      if (imageUrl != null) {
        updateData['profileImageUrl'] = imageUrl;
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profileImageUrl': FieldValue.delete()});

        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('${user.uid}.jpg');
          await storageRef.delete();
        } catch (e) {
          // Ignore if file doesn't exist
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text("Profile updated successfully!"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text("Failed to update profile"),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required bool isSmallScreen,
    String? Function(String?)? validator,
    bool readOnly = false,
    int index = 0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1 * value),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                readOnly: readOnly,
                validator: validator,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF8B7FFF), const Color(0xFF00E5FF)]
                            : [
                                const Color(0xFF6C63FF),
                                const Color(0xFF00D4FF),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  filled: true,
                  fillColor: readOnly
                      ? (isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.1))
                      : (isDark ? const Color(0xFF1F1F2E) : Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 14 : 18,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final firstName = _firstNameController.text;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1E) : Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: isSmallScreen ? 180 : 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF2D2D44), Colors.transparent]
                    : [Theme.of(context).primaryColor, Colors.transparent],
              ),
            ),
          ),

          // Form
          FadeTransition(
            opacity: _formFade,
            child: SlideTransition(
              position: _formSlide,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: isSmallScreen ? 80 : 100),

                      // Profile Image Section
                      Hero(
                        tag: 'profile_image',
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: isSmallScreen ? 60 : 70,
                                      backgroundColor: Colors.white,
                                      backgroundImage: _imageFile != null
                                          ? FileImage(_imageFile!)
                                          : (profileImageUrl != null
                                                    ? NetworkImage(
                                                        profileImageUrl!,
                                                      )
                                                    : null)
                                                as ImageProvider?,
                                      child:
                                          _imageFile == null &&
                                              profileImageUrl == null
                                          ? Text(
                                              firstName.isNotEmpty
                                                  ? firstName[0].toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                fontSize: isSmallScreen
                                                    ? 40
                                                    : 48,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  if (isUploadingImage)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: isUploadingImage
                                          ? null
                                          : _showImageSourceDialog,
                                      child: Container(
                                        padding: EdgeInsets.all(
                                          isSmallScreen ? 10 : 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isDark
                                                ? [
                                                    const Color(0xFF8B7FFF),
                                                    const Color(0xFF00E5FF),
                                                  ]
                                                : [
                                                    const Color(0xFF6C63FF),
                                                    const Color(0xFF00D4FF),
                                                  ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: isSmallScreen ? 20 : 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 28 : 32),

                      // Form Fields
                      _buildTextField(
                        controller: _firstNameController,
                        label: "First Name",
                        icon: Icons.person,
                        isDark: isDark,
                        isSmallScreen: isSmallScreen,
                        validator: (value) =>
                            value!.trim().isEmpty ? "Required" : null,
                        index: 0,
                      ),
                      SizedBox(height: isSmallScreen ? 14 : 16),

                      _buildTextField(
                        controller: _lastNameController,
                        label: "Last Name",
                        icon: Icons.person_outline,
                        isDark: isDark,
                        isSmallScreen: isSmallScreen,
                        validator: (value) =>
                            value!.trim().isEmpty ? "Required" : null,
                        index: 1,
                      ),
                      SizedBox(height: isSmallScreen ? 14 : 16),

                      _buildTextField(
                        controller: _emailController,
                        label: "Email (read-only)",
                        icon: Icons.email,
                        isDark: isDark,
                        isSmallScreen: isSmallScreen,
                        readOnly: true,
                        index: 2,
                      ),
                      SizedBox(height: isSmallScreen ? 14 : 16),

                      _buildTextField(
                        controller: _countryController,
                        label: "Country",
                        icon: Icons.flag,
                        isDark: isDark,
                        isSmallScreen: isSmallScreen,
                        index: 3,
                      ),
                      SizedBox(height: isSmallScreen ? 14 : 16),

                      _buildTextField(
                        controller: _stateController,
                        label: "State",
                        icon: Icons.map,
                        isDark: isDark,
                        isSmallScreen: isSmallScreen,
                        index: 4,
                      ),
                      SizedBox(height: isSmallScreen ? 14 : 16),

                      _buildTextField(
                        controller: _cityController,
                        label: "City",
                        icon: Icons.location_city,
                        isDark: isDark,
                        isSmallScreen: isSmallScreen,
                        index: 5,
                      ),

                      SizedBox(height: isSmallScreen ? 28 : 32),

                      // Save Button
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: ScaleTransition(
                              scale: _buttonScale,
                              child: Container(
                                width: double.infinity,
                                height: isSmallScreen ? 50 : 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            const Color(0xFF8B7FFF),
                                            const Color(0xFF00E5FF),
                                          ]
                                        : [
                                            const Color(0xFF6C63FF),
                                            const Color(0xFF00D4FF),
                                          ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isDark
                                                  ? const Color(0xFF8B7FFF)
                                                  : const Color(0xFF6C63FF))
                                              .withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.save,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Save Changes",
                                              style: TextStyle(
                                                fontSize: isSmallScreen
                                                    ? 16
                                                    : 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: isSmallScreen ? 28 : 32),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Full screen loader overlay
          if (isLoading && !isUploadingImage)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
