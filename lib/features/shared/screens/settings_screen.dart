import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/widgets/app_nav_drawer.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';

/// Settings screen — shared across all roles. Language toggle
/// (spec §1: Bengali/English) and account actions.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const AppNavDrawer(),
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          profileAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (profile) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(profile?.fullName ?? ''),
                subtitle: Text(profile?.email ?? profile?.phone ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RouteNames.profile),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: profileAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (profile) => ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Language'),
                trailing: DropdownButton<String>(
                  value: profile?.languagePreference ?? 'en',
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(localeProvider.notifier)
                          .setLocale(Locale(value));
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: Icon(Icons.logout,
                  color: Theme.of(context).colorScheme.error),
              title: Text(
                'Sign Out',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go(RouteNames.login);
              },
            ),
          ),
        ],
      ),
    );
  }
}
