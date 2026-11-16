import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/admin_service.dart';

class HiddenGemSuggestionsScreen extends StatefulWidget {
  const HiddenGemSuggestionsScreen({super.key});

  @override
  State<HiddenGemSuggestionsScreen> createState() =>
      _HiddenGemSuggestionsScreenState();
}

class _HiddenGemSuggestionsScreenState
    extends State<HiddenGemSuggestionsScreen> {
  List<SuggestedPlace> _suggestions = const [];
  final Set<String> _busyIds = {};
  final Map<String, PlaceSuggestionType> _typeOverrides = {};
  bool _loading = true;
  String? _error;
  String _statusFilter = 'pending';
  PlaceSuggestionType? _typeFilter;

  List<SuggestedPlace> get _visibleSuggestions => _suggestions
      .where((row) {
        return row.status == _statusFilter &&
            (_typeFilter == null || row.type == _typeFilter);
      })
      .toList(growable: false);

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
      final rows = await AdminService.instance.fetchPlaceSuggestions();
      if (mounted) setState(() => _suggestions = rows);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _moderate(SuggestedPlace suggestion, String action) async {
    final id = suggestion.id;
    final selectedType = _typeOverrides[id] ?? suggestion.type;
    setState(() => _busyIds.add(id));
    try {
      await AdminService.instance.moderatePlaceSuggestion(
        suggestion,
        action,
        approvedType: selectedType,
      );
      if (!mounted) return;
      setState(() {
        final approvedSuggestionType = action == 'approve'
            ? selectedType
            : suggestion.type;
        _suggestions = _suggestions
            .map(
              (row) => row.id == id
                  ? row.copyWith(
                      status: action == 'approve' ? 'approved' : 'rejected',
                      type: approvedSuggestionType,
                    )
                  : row,
            )
            .toList(growable: false);
        _typeOverrides.remove(id);
      });
      final message = switch (action) {
        'approve' =>
          'Suggestion approved and added to Places. The submitter was granted '
              '${selectedType == PlaceSuggestionType.hiddenGem ? 30 : 7} days of Free Pro.',
        _ => 'Suggestion rejected.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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

  void _setType(SuggestedPlace suggestion, PlaceSuggestionType type) {
    setState(() => _typeOverrides[suggestion.id] = type);
  }

  @override
  Widget build(BuildContext context) {
    final visibleSuggestions = _visibleSuggestions;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Suggestions'),
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
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final status in const [
                        ('pending', 'Pending'),
                        ('approved', 'Approved'),
                        ('rejected', 'Rejected'),
                      ])
                        ChoiceChip(
                          label: Text(status.$2),
                          selected: _statusFilter == status.$1,
                          onSelected: (_) =>
                              setState(() => _statusFilter = status.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Suggestion type',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _typeFilter == null,
                        onSelected: (_) => setState(() => _typeFilter = null),
                      ),
                      ChoiceChip(
                        label: const Text('Regular Places · 7d Pro'),
                        selected: _typeFilter == PlaceSuggestionType.regular,
                        onSelected: (_) => setState(
                          () => _typeFilter = PlaceSuggestionType.regular,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Hidden Gems · 30d Pro'),
                        selected: _typeFilter == PlaceSuggestionType.hiddenGem,
                        onSelected: (_) => setState(
                          () => _typeFilter = PlaceSuggestionType.hiddenGem,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visibleSuggestions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No $_statusFilter suggestions for this filter.',
                        ),
                      ),
                    )
                  else
                    for (final suggestion in visibleSuggestions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSuggestionCard(suggestion),
                      ),
                ],
              ),
            ),
    );
  }

  Widget _buildSuggestionCard(SuggestedPlace suggestion) {
    final id = suggestion.id;
    final busy = _busyIds.contains(id);
    final canModerate = suggestion.status == 'pending';
    final selectedType = _typeOverrides[id] ?? suggestion.type;
    final displaySuggestion = suggestion.copyWith(type: selectedType);
    final imageUrl = suggestion.imageUrl;
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
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (suggestion.nameAr?.isNotEmpty == true)
                  Text(suggestion.nameAr!),
                const SizedBox(height: 8),
                Chip(
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displaySuggestion.typeLabel),
                      Text(displaySuggestion.rewardLabel),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(suggestion.description),
                const SizedBox(height: 8),
                Text('Category: ${suggestion.category}'),
                if (suggestion.categoryAr?.isNotEmpty == true)
                  Text('Arabic category: ${suggestion.categoryAr}'),
                if (suggestion.address?.isNotEmpty == true)
                  Text('Location: ${suggestion.address}'),
                Text('Coordinates: ${suggestion.lat}, ${suggestion.lng}'),
                SelectableText('Submitted by: ${suggestion.userId}'),
                Text('Submitted: ${suggestion.createdAt ?? 'Unknown'}'),
                if (canModerate) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Approve as',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Regular Place · 7d Pro'),
                        selected: selectedType == PlaceSuggestionType.regular,
                        onSelected: busy
                            ? null
                            : (_) => _setType(
                                suggestion,
                                PlaceSuggestionType.regular,
                              ),
                      ),
                      ChoiceChip(
                        label: const Text('Hidden Gem · 30d Pro'),
                        selected: selectedType == PlaceSuggestionType.hiddenGem,
                        onSelected: busy
                            ? null
                            : (_) => _setType(
                                suggestion,
                                PlaceSuggestionType.hiddenGem,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: busy
                            ? null
                            : () => _moderate(suggestion, 'approve'),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Approve'),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => _moderate(suggestion, 'reject'),
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
                ] else
                  Chip(label: Text('Status: ${suggestion.status}')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
