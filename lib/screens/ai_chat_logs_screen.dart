import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class AiChatLogsScreen extends StatefulWidget {
  const AiChatLogsScreen({super.key});

  @override
  State<AiChatLogsScreen> createState() => _AiChatLogsScreenState();
}

class _AiChatLogsScreenState extends State<AiChatLogsScreen> {
  static const _pageSize = 50;
  final _scrollController = ScrollController();
  final List<AdminChatLog> _logs = [];
  String? _error;
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadWhenNearEnd);
    _loadMore();
  }

  void _loadWhenNearEnd() {
    if (_scrollController.position.extentAfter < 300) _loadMore();
  }

  Future<void> _loadMore({bool refresh = false}) async {
    if (_loading || (!refresh && !_hasMore)) return;
    setState(() {
      _loading = true;
      _error = null;
      if (refresh) {
        _logs.clear();
        _page = 0;
        _hasMore = true;
      }
    });
    try {
      final result = await AdminService.instance.fetchAiChatLogs(
        page: _page + 1,
        perPage: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _logs.addAll(result.logs);
        _page++;
        _hasMore = result.hasMore;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadWhenNearEnd)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final threads = groupAdminChatLogs(_logs);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Chat Logs',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            tooltip: 'Refresh logs',
            onPressed: _loading ? null : () => _loadMore(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      backgroundColor: AppTheme.bg,
      body: _error != null && _logs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => _loadMore(refresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadMore(refresh: true),
              child: ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: threads.isEmpty && !_loading && _error == null
                    ? 1
                    : threads.length + (_loading || _hasMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (threads.isEmpty && !_loading && _error == null) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: Text('No AI chat logs yet.')),
                    );
                  }
                  if (index == threads.length) {
                    if (_error != null) {
                      return TextButton(
                        onPressed: _loadMore,
                        child: Text('Could not load more logs: $_error. Retry'),
                      );
                    }
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return _ThreadCard(thread: threads[index]);
                },
              ),
            ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  final AdminChatThread thread;

  const _ThreadCard({required this.thread});

  @override
  Widget build(BuildContext context) {
    final firstPrompt = thread.messages
        .firstWhere(
          (message) => message.prompt.trim().isNotEmpty,
          orElse: () => thread.messages.first,
        )
        .prompt;
    final identifier = thread.userEmail?.isNotEmpty == true
        ? thread.userEmail!
        : thread.userId;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                identifier.isEmpty ? 'Unknown user' : identifier,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${thread.messages.length} ${thread.messages.length == 1 ? 'message' : 'messages'}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatTime(thread.startedAt)}  →  ${_formatTime(thread.lastMessageAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 5),
              Text(
                firstPrompt.isEmpty ? 'No prompt recorded' : firstPrompt,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        children: [
          for (var index = 0; index < thread.messages.length; index++) ...[
            if (index > 0) const Divider(height: 20),
            _TranscriptMessage(message: thread.messages[index]),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime? value) =>
      value?.toLocal().toString().split('.').first ?? 'Unknown time';
}

class _TranscriptMessage extends StatelessWidget {
  final AdminChatLog message;

  const _TranscriptMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 10),
        const Text('Prompt', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        _TranscriptBubble(text: message.prompt),
        const SizedBox(height: 10),
        const Text(
          'AI response',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        _AiResponse(response: message.response),
      ],
    );
  }

  String _formatTime(DateTime? value) =>
      value?.toLocal().toString().split('.').first ?? 'Unknown time';
}

class _TranscriptBubble extends StatelessWidget {
  final String text;

  const _TranscriptBubble({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.bg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.border),
    ),
    child: SelectableText(text.isEmpty ? 'No content recorded' : text),
  );
}

class _AiResponse extends StatelessWidget {
  final String response;

  const _AiResponse({required this.response});

  @override
  Widget build(BuildContext context) {
    final statusCode = _jsonErrorStatusCode(response);
    if (statusCode != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
          ),
          child: Text(
            '⚠️ AI Service Unavailable ($statusCode)',
            style: const TextStyle(
              color: Colors.deepOrange,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return _TranscriptBubble(text: response);
  }

  int? _jsonErrorStatusCode(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;
      final error = decoded['error'];
      if (error is! Map) return null;
      final code = error['code'] ?? decoded['code'] ?? error['status'];
      final statusCode = code is num ? code.toInt() : int.tryParse('$code');
      return statusCode != null && statusCode >= 400 && statusCode < 600
          ? statusCode
          : null;
    } on FormatException {
      return null;
    }
  }
}
