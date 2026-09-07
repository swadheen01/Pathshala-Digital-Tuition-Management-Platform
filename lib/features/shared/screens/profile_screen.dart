import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/app_avatar.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';

/// Profile view/edit screen — shared across all roles. Shows the
/// fields captured at signup (spec §1: name, class/grade, institution)
/// and lets the user update them.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _classGradeController = TextEditingController();
  final _institutionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _avatarUrl;
  bool _prefilled = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _classGradeController.dispose();
    _institutionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) return;

    try {
      await AuthService().updateProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: profile.role,
        classGrade: _classGradeController.text.trim().isEmpty
            ? null
            : _classGradeController.text.trim(),
        institution: _institutionController.text.trim().isEmpty
            ? null
            : _institutionController.text.trim(),
        avatarUrl: _avatarUrl,
      );

      ref.invalidate(currentProfileProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final bytes = await picked.readAsBytes();
      _avatarUrl = await StorageService().uploadAvatar(
        bytes: bytes,
        fileExtension: picked.name.split('.').last,
      );
      ref.invalidate(currentProfileProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload avatar: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load your profile. Please try again.')),
        data: (profile) {
          if (profile != null && !_prefilled) {
            _nameController.text = profile.fullName;
            _classGradeController.text = profile.classGrade ?? '';
            _institutionController.text = profile.institution ?? '';
            _emailController.text = profile.email ?? '';
            _phoneController.text = profile.phone ?? '';
            _avatarUrl = profile.avatarUrl;
            _prefilled = true;
          }

          final isStudent = profile?.role.name == 'student';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _saving ? null : _pickAvatar,
                      child: AppAvatar(
                        name: profile?.fullName ?? '',
                        imageUrl: _avatarUrl,
                        radius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    profile?.email ?? profile?.phone ?? '',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Chip(label: Text(profile?.role.name.toUpperCase() ?? '')),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) => Validators.required(v, fieldName: 'Name'),
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? null
                        : Validators.email(value),
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    enabled: !_saving,
                  ),
                  if (isStudent) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _classGradeController,
                      decoration:
                          const InputDecoration(labelText: 'Class / Grade'),
                      enabled: !_saving,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _institutionController,
                    decoration: const InputDecoration(
                      labelText: 'Institution (optional)',
                    ),
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _handleSave,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
