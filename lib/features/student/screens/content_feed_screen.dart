import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routes/route_names.dart';
import '../../../models/content_model.dart';
import '../../../providers/content_provider.dart';

/// Student's home feed of curated content — YouTube/other links, some
/// general and some targeted to their class/grade (spec §3, §4).
///
/// NOTE: add `url_launcher: ^6.3.0` to pubspec.yaml — needed to open
/// content links, wasn't in the original dependency list.
class ContentFeedScreen extends ConsumerWidget {
  const ContentFeedScreen({super.key});

  Future<void> _openContent(
    BuildContext context,
    WidgetRef ref,
    ContentModel content,
  ) async {
    await ref.read(contentControllerProvider.notifier).logView(content.id);

    final uri = Uri.tryParse(content.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this link')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(studentContentFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(RouteNames.contentSearch),
          ),
        ],
      ),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load content. Please try again.')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No content available yet.'));
          }
          const accents = [
            Color(0xFFEA4335),
            Color(0xFF4C7DFF),
            Color(0xFF2FB57A),
            Color(0xFFB14DFF),
            Color(0xFFFFB547),
          ];
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final content = items[index];
              final accent = accents[index % accents.length];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: Container(
                    height: 46,
                    width: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: accent),
                  ),
                  title: Text(content.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      content.subject ?? content.description ?? 'Tap to watch'),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () => _openContent(context, ref, content),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
