import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_error.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/room_provider.dart';
import '../../../services/room_service.dart';

/// Student enters a join code. If the teacher already added them by name,
/// they can ask to be linked to that roster entry (teacher approves).
class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _rollController = TextEditingController();

  bool _busy = false;
  RoomCodeLookup? _lookup;

  @override
  void dispose() {
    _codeController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final lookup = await ref
          .read(roomServiceProvider)
          .findRoomByCode(_codeController.text.trim());
      if (!mounted) return;
      if (lookup == null) {
        _toast('Invalid join code. Please check and try again.');
        return;
      }
      if (lookup.unclaimedNames.isEmpty) {
        await _joinFresh();
      } else {
        setState(() => _lookup = lookup);
      }
    } catch (e) {
      _toast(friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinFresh() async {
    final room = await ref.read(roomControllerProvider.notifier).joinRoom(
          _codeController.text.trim(),
          rollNumber:
              _rollController.text.trim().isEmpty ? null : _rollController.text.trim(),
        );
    if (!mounted) return;
    if (room == null) {
      _toast(friendlyAuthError(ref.read(roomControllerProvider).error));
      return;
    }
    ref.invalidate(studentRoomsProvider);
    _toast('Joined "${room.name}"');
    context.pop();
  }

  Future<void> _claim(String name) async {
    setState(() => _busy = true);
    final roomName = await ref.read(roomControllerProvider.notifier).requestClaim(
          joinCode: _codeController.text.trim(),
          fullName: name,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (roomName == null) {
      _toast(friendlyAuthError(ref.read(roomControllerProvider).error));
      return;
    }
    _toast('Request sent to $roomName. Your teacher will confirm it\'s you.');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final lookup = _lookup;

    return Scaffold(
      appBar: AppBar(
        title: Text(lookup == null ? 'Join a room' : 'Is this you?'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: lookup == null ? _codeStep() : _claimStep(lookup),
        ),
      ),
    );
  }

  Widget _codeStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 30),
                SizedBox(height: 12),
                Text(
                  'Enter the join code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your teacher shares a 6-character code for each room.',
                  style: TextStyle(color: Color(0xFFD9E5FF), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 6,
              fontWeight: FontWeight.w800,
            ),
            decoration: const InputDecoration(hintText: 'ABC123'),
            validator: (v) => Validators.required(v, fieldName: 'Join code'),
            enabled: !_busy,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _rollController,
            decoration: const InputDecoration(
              labelText: 'Roll number (optional)',
              prefixIcon: Icon(Icons.tag),
            ),
            enabled: !_busy,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _busy ? null : _continue,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _claimStep(RoomCodeLookup lookup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your teacher already added some students to "${lookup.name}" by '
          'name. If one of these is you, pick it — your teacher will confirm '
          'and your attendance and payment history will carry over.',
          style: const TextStyle(color: Color(0xFF70655D), height: 1.4),
        ),
        const SizedBox(height: 20),
        for (final name in lookup.unclaimedNames)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.skyBlue.withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppTheme.skyBlue, fontWeight: FontWeight.w800),
                ),
              ),
              title: Text(name),
              trailing: _busy
                  ? null
                  : const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: _busy ? null : () => _claim(name),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _joinFresh,
          icon: const Icon(Icons.person_add_alt),
          label: const Text('None of these — join as new'),
        ),
      ],
    );
  }
}
