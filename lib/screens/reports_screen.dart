import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _reports = const [];
  bool _loading = true;
  String? _error;
  final Set<String> _busyReportIds = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports = await AdminService.instance.fetchPendingReports();
      if (mounted) setState(() => _reports = reports);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _dismiss(Map<String, dynamic> report) async {
    await _runReportAction(report, () async {
      await AdminService.instance.dismissReport(report['id'] as String);
    });
  }

  Future<void> _deleteContent(Map<String, dynamic> report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete reported content?'),
        content: const Text(
          'This action cannot be undone. Unsupported content types will remain '
          'available to dismiss without deleting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Content'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runReportAction(report, () async {
      await AdminService.instance.deleteReportedContent(
        report['id'] as String,
        report['target_type'] as String,
        report['target_id'] as String,
      );
    });
  }

  Future<void> _runReportAction(
    Map<String, dynamic> report,
    Future<void> Function() action,
  ) async {
    final reportId = report['id'] as String;
    setState(() => _busyReportIds.add(reportId));
    try {
      await action();
      if (mounted) {
        setState(() {
          _reports = _reports
              .where((item) => item['id'] != reportId)
              .toList(growable: false);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Report updated.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update report: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyReportIds.remove(reportId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderation / Reports'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadReports,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading && _reports.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Could not load pending reports:\n$_error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadReports,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _reports.isEmpty
          ? const Center(child: Text('No pending reports.'))
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _reports.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final report = _reports[index];
                  final id = report['id'] as String;
                  final busy = _busyReportIds.contains(id);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.flag_rounded,
                                color: AppTheme.danger,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${report['target_type']} · ${report['reason']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText('Target: ${report['target_id']}'),
                          if ((report['target_context'] as String?)
                                  ?.isNotEmpty ??
                              false)
                            Text('Context: ${report['target_context']}'),
                          if ((report['reporter_username'] as String?)
                                  ?.isNotEmpty ??
                              false)
                            Text(
                              'Reporter username: @${report['reporter_username']}',
                            ),
                          SelectableText('Reporter: ${report['reporter_id']}'),
                          if (report['created_at'] is String)
                            Text('Submitted: ${report['created_at']}'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: busy ? null : () => _dismiss(report),
                                child: const Text('Dismiss'),
                              ),
                              FilledButton.tonal(
                                onPressed: busy
                                    ? null
                                    : () => _deleteContent(report),
                                child: busy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Delete Content'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
