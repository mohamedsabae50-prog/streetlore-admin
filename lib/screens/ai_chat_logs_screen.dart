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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Chat Logs',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
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
                itemCount: _logs.isEmpty && !_loading && _error == null
                    ? 1
                    : _logs.length + (_loading || _hasMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (_logs.isEmpty && !_loading && _error == null) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: Text('No AI chat logs yet.')),
                    );
                  }
                  if (index == _logs.length) {
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
                  return _LogCard(log: _logs[index]);
                },
              ),
            ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final AdminChatLog log;

  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.createdAt?.toLocal().toString().split('.').first ??
                'Unknown time',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          SelectableText(
            'User: ${log.userId}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          const Text('Prompt', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          SelectableText(log.prompt),
          const SizedBox(height: 12),
          const Text(
            'AI response',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          SelectableText(log.response),
        ],
      ),
    );
  }
}
