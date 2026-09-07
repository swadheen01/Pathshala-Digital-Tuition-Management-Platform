import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/content_provider.dart';

/// Content search/filter screen — available to all users (spec §4).
class ContentSearchScreen extends ConsumerStatefulWidget {
  const ContentSearchScreen({super.key});

  @override
  ConsumerState<ContentSearchScreen> createState() =>
      _ContentSearchScreenState();
}

class _ContentSearchScreenState extends ConsumerState<ContentSearchScreen> {
  final _keywordController = TextEditingController();
  String? _subjectFilter;
  ({String? keyword, String? subject}) _query = (keyword: null, subject: null);

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  void _runSearch() {
    setState(() {
      _query = (
        keyword: _keywordController.text.trim().isEmpty
            ? null
            : _keywordController.text.trim(),
        subject: _subjectFilter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(contentSearchProvider(_query));

    return Scaffold(
      appBar: AppBar(title: const Text('Search Content')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _keywordController,
                  decoration: const InputDecoration(
                    hintText: 'Search by title…',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _runSearch(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Filter by subject (optional)',
                          isDense: true,
                        ),
                        onChanged: (v) =>
                            _subjectFilter = v.trim().isEmpty ? null : v.trim(),
                        onSubmitted: (_) => _runSearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _runSearch,
                      child: const Text('Search'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                  child: Text('Unable to search content. Please try again.')),
              data: (results) {
                if (results.isEmpty) {
                  return const Center(
                      child: Text('No matching content found.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final content = results[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.play_circle_outline),
                        title: Text(content.title),
                        subtitle: Text(content.subject ?? ''),
                        onTap: () async {
                          await ref
                              .read(contentControllerProvider.notifier)
                              .logView(content.id);
                          final uri = Uri.tryParse(content.url);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
