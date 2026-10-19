import 'package:flutter/material.dart';

import '../services/admin_service.dart';

class HiddenGemSuggestionsScreen extends StatefulWidget {
  const HiddenGemSuggestionsScreen({super.key});

  @override
  State<HiddenGemSuggestionsScreen> createState() =>
      _HiddenGemSuggestionsScreenState();
}

class _HiddenGemSuggestionsScreenState
    extends State<HiddenGemSuggestionsScreen> {
  List<Map<String, dynamic>> _suggestions = const [];
  final Set<String> _busyIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await AdminService.instance.fetchPendingHiddenGems();
      if (mounted) setState(() => _suggestions = rows);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _moderate(Map<String, dynamic> suggestion, String action) async {
    final id = suggestion['id'].toString();
    setState(() => _busyIds.add(id));
    try {
      await AdminService.instance.moderateHiddenGem(id, action);
      if (!mounted) return;
      setState(() {
        _suggestions = _suggestions
            .where((row) => row['id'].toString() != id)
            .toList(growable: false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'approve'
                ? 'Suggestion approved and added to Places. The submitter was granted 30 days of Pro for free.'
                : 'Suggestion rejected.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not moderate suggestion: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hidden Gem Suggestions'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading && _suggestions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Could not load suggestions:\n$_error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _suggestions.isEmpty
          ? const Center(child: Text('No pending suggestions.'))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final row = _suggestions[index];
                  final id = row['id'].toString();
                  final imageUrl = row['image_url'] as String?;
                  final busy = _busyIds.contains(id);
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl?.isNotEmpty == true)
                          Image.network(
                            imageUrl!,
                            height: 190,
                            width: double.infinity,
                            cacheWidth: 640,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox(
                              height: 80,
                              child: Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row['title']?.toString() ?? '',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if ((row['name_ar'] as String?)?.isNotEmpty ==
                                  true)
                                Text(row['name_ar'] as String),
                              const SizedBox(height: 8),
                              Text(row['description']?.toString() ?? ''),
                              const SizedBox(height: 8),
                              Text('Category: ${row['category'] ?? 'Other'}'),
                              if ((row['category_ar'] as String?)?.isNotEmpty ==
                                  true)
                                Text(
                                  'Arabic category: '
                                  '${row['category_ar']}',
                                ),
                              if ((row['address'] as String?)?.isNotEmpty ==
                                  true)
                                Text('Location: ${row['address']}'),
                              Text(
                                'Coordinates: ${row['lat']}, '
                                '${row['lng']}',
                              ),
                              SelectableText('Submitted by: ${row['user_id']}'),
                              Text('Submitted: ${row['created_at']}'),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilledButton.icon(
                                    onPressed: busy
                                        ? null
                                        : () => _moderate(row, 'approve'),
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                    ),
                                    label: const Text('Approve'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: busy
                                        ? null
                                        : () => _moderate(row, 'reject'),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Reject'),
                                  ),
                                  if (busy)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
