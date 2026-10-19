import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';
import 'manage_user_visits_dialog.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  static const _pageSize = 50;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  List<AdminUser> _users = [];
  String _query = '';
  String? _error;
  String? _deletingUserId;
  String? _updatingProUserId;
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUsers(reset: true);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300 &&
        !_loading &&
        !_loadingMore &&
        _hasMore) {
      _loadUsers();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final query = value.trim();
      if (query == _query || !mounted) return;
      _query = query;
      _loadUsers(reset: true);
    });
  }

  Future<void> _loadUsers({bool reset = false}) async {
    if (!reset && (_loading || _loadingMore)) return;
    final page = reset ? 1 : _page + 1;
    final query = _query;
    final requestId = ++_requestId;
    setState(() {
      if (reset) {
        _loading = true;
        _loadingMore = false;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final result = await AdminService.instance.fetchUsers(
        query: query,
        page: page,
        perPage: _pageSize,
      );
      if (!mounted || requestId != _requestId || query != _query) return;
      setState(() {
        _users = reset ? result.users : [..._users, ...result.users];
        _page = page;
        _hasMore = result.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId || query != _query) return;
      setState(() {
        _error = '$e';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _deleteUser(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user account?'),
        content: Text(
          'Permanently delete ${user.name} (${user.email}) and their '
          'submitted content? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() => _deletingUserId = user.id);
    try {
      await AdminService.instance.deleteUser(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${user.name} and their account data')),
      );
      await _loadUsers(reset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User deletion failed: $e')));
    } finally {
      if (mounted) setState(() => _deletingUserId = null);
    }
  }

  Future<void> _copyEmail(String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  Future<void> _selectSubscriptionPlan(AdminUser user) async {
    final plan = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Subscription plan for ${user.name}'),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _planOption(context, 'weekly', 'Weekly'),
            _planOption(context, 'monthly', 'Monthly'),
            _planOption(context, 'lifetime', 'Lifetime'),
            _planOption(context, 'free', 'Revoke Pro (Free)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (!mounted || plan == null) return;
    await _setSubscriptionPlan(user, plan);
  }

  Widget _planOption(BuildContext context, String plan, String title) =>
      ListTile(
        leading: Icon(
          plan == 'free' ? Icons.person_outline_rounded : Icons.workspace_premium_rounded,
          color: plan == 'free' ? AppTheme.textSecondary : AppTheme.primary,
        ),
        title: Text(title),
        onTap: () => Navigator.pop(context, plan),
      );

  Future<void> _setSubscriptionPlan(AdminUser user, String plan) async {
    setState(() => _updatingProUserId = user.id);
    try {
      final updated = await AdminService.instance.setUserSubscriptionPlan(
        user.id,
        plan,
      );
      if (!mounted) return;
      setState(() {
        final index = _users.indexWhere((item) => item.id == user.id);
        if (index >= 0) {
          _users[index] = user.copyWith(
            isPro: plan != 'free',
            subscriptionTier: updated.tier,
            subscriptionEndDate: updated.endDate,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            plan == 'free'
                ? 'Pro revoked for ${user.name}'
                : '${plan[0].toUpperCase()}${plan.substring(1)} Pro granted to ${user.name}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription plan update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _updatingProUserId = null);
    }
  }

  Future<void> _manageVisits(AdminUser user) async {
    final result = await showManageUserVisitsDialog(context, user);
    if (!mounted || result == null) return;
    final addedCount = (result['added_count'] as num?)?.toInt() ?? 0;
    final badges = result['newly_unlocked'] is List
        ? result['newly_unlocked'] as List
        : const <dynamic>[];
    final badgeNames = badges
        .whereType<Map>()
        .map((badge) => (badge['name'] ?? badge['id'] ?? 'Achievement').toString())
        .map(
          (name) => name
              .replaceFirst('ach_', '')
              .replaceAll('_name', '')
              .replaceAll('_', ' '),
        )
        .toList(growable: false);
    final message = addedCount == 0
        ? 'No new visits were added for ${user.name}. Stats are synced.'
        : 'Added $addedCount visit(s) for ${user.name}.'
              '${badgeNames.isEmpty ? '' : ' New badges: ${badgeNames.join(', ')}'}';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _containsArabic(String value) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(value);

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Users',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _loadUsers(reset: true),
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _users.isEmpty
                ? _errorState()
                : _users.isEmpty
                ? const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadUsers(reset: true),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _users.length + (_loadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == _users.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final user = _users[index];
                        final deleting = _deletingUserId == user.id;
                        final updatingPro = _updatingProUserId == user.id;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                foregroundColor: AppTheme.primary,
                                child: Text(
                                  user.name.isEmpty
                                      ? '?'
                                      : user.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      textDirection: _containsArabic(user.name)
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            user.email,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Copy email',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () =>
                                              _copyEmail(user.email),
                                          icon: const Icon(
                                            Icons.copy_rounded,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (user.createdAt != null)
                                      Text(
                                        'Joined ${user.createdAt!.toLocal().toString().split(' ').first}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    user.isPro
                                        ? 'PRO · ${user.subscriptionTier ?? 'legacy'}'
                                        : 'FREE',
                                    style: TextStyle(
                                      color: user.isPro
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (user.subscriptionEndDate != null)
                                    Text(
                                      'Until ${user.subscriptionEndDate!.toLocal().toString().split(' ').first}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 9,
                                      ),
                                    ),
                                  if (updatingPro)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else
                                    TextButton(
                                      onPressed: () => _selectSubscriptionPlan(user),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Manage plan'),
                                    ),
                                ],
                              ),
                              IconButton(
                                tooltip: 'Manage Visits / إضافة زيارات',
                                onPressed: deleting || updatingPro
                                    ? null
                                    : () => _manageVisits(user),
                                icon: const Icon(
                                  Icons.add_location_alt_outlined,
                                  color: AppTheme.primary,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete user account',
                                onPressed: deleting || updatingPro
                                    ? null
                                    : () => _deleteUser(user),
                                icon: deleting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load users: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _loadUsers(reset: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
