import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../models/content_model.dart';
import '../../../providers/content_provider.dart';

/// Admin manages curated content — links/videos with optional
/// class/grade targeting (spec §4).
class ManageContentScreen extends ConsumerWidget {
  const ManageContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(allContentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Content')),
      body: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load content. Please try again.')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No content yet.\nTap + to add some.',
                  textAlign: TextAlign.center),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _ContentTile(content: items[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.addContent),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ContentTile extends ConsumerWidget {
  const _ContentTile({required this.content});
  final ContentModel content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.play_circle_outline),
        title: Text(content.title),
        subtitle: Text(
          content.isGeneral
              ? 'All students'
              : 'Class: ${content.targetClassGrade}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await ref
                .read(contentControllerProvider.notifier)
                .deleteContent(content.id);
            ref.invalidate(allContentProvider);
          },
        ),
      ),
    );
  }
}
