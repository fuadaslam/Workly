import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/profile.dart' as model;
import '../providers/profile_provider.dart';
import '../../../../core/widgets/responsive_layout.dart';
import 'package:service_manager_app/core/widgets/app_bar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final model.Profile profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _whatsappController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _whatsappController = TextEditingController(text: widget.profile.whatsappNo);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 100);
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      late Uint8List bytes;
      String? localPath;

      if (kIsWeb) {
        // Web: dart:io and FlutterImageCompress are unavailable.
        bytes = await picked.readAsBytes();
      } else {
        // Native: compress to JPEG ≤ 200 KB.
        final tmpDir = await getTemporaryDirectory();
        final outPath = '${tmpDir.path}/${user.id}_avatar.jpg';
        final compressed = await FlutterImageCompress.compressAndGetFile(
          picked.path,
          outPath,
          format: CompressFormat.jpeg,
          quality: 65,
          minWidth: 300,
          minHeight: 300,
        );
        if (compressed == null) return;
        localPath = compressed.path;
        bytes = await File(compressed.path).readAsBytes();
      }

      // Upload to Supabase Storage (upsert)
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            '${user.id}.jpg',
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Get public URL and update profile row
      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl('${user.id}.jpg');

      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id);

      setState(() => _localAvatarPath = localPath);

      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppTheme.darkBlue),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.darkBlue),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('profiles').update({
        'name': _nameController.text.trim(),
        'whatsapp_no': _whatsappController.text.trim(),
        'phone_number': _phoneController.text.trim(),
      }).eq('id', user.id);

      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildAvatar() {
    final remoteUrl = widget.profile.avatarUrl;
    final hasLocal = _localAvatarPath != null;
    final hasRemote = remoteUrl != null && remoteUrl.isNotEmpty;

    ImageProvider? imageProvider;
    if (hasLocal) {
      imageProvider = FileImage(File(_localAvatarPath!));
    } else if (hasRemote) {
      imageProvider = NetworkImage(remoteUrl);
    }

    return GestureDetector(
      onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryAccent(Theme.of(context).brightness == Brightness.dark), width: 2),
            ),
            child: _isUploadingAvatar
                ? const SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emeraldGreen),
                  )
                : CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.emeraldLight,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(Icons.person, size: 50, color: AppTheme.emeraldGreen)
                        : null,
                  ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.emeraldGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      appBar: const WorkqlyAppBar(title: 'Edit Profile'),
      body: ResponsiveLayout(
        maxWidth: 800,
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildAvatar()),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Tap to change photo',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 32),
              _buildTextField(
                label: 'Full Name / الاسم الكامل',
                controller: _nameController,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'WhatsApp Number / رقم الواتساب',
                controller: _whatsappController,
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Phone Number / رقم الهاتف',
                controller: _phoneController,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.primaryAccent(isDark) : AppTheme.emeraldGreen,
                    foregroundColor: isDark ? AppTheme.ink900 : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: isDark ? AppTheme.ink900 : Colors.white, strokeWidth: 2))
                      : Text('Save Changes / حفظ التغييرات', style: TextStyle(color: isDark ? AppTheme.ink900 : Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.primaryAccent(isDark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: accent),
            filled: true,
            fillColor: isDark ? AppTheme.darkCard : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
