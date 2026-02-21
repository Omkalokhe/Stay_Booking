import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/admin/admin_users_controller.dart';
import 'package:stay_booking_frontend/model/admin/admin_user_dto.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({required this.user, super.key});

  final Map<String, dynamic> user;

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  late final AdminUsersController _controller;
  final _searchController = TextEditingController();

  static const _roleOptions = <String>['CUSTOMER', 'VENDOR', 'ADMIN'];
  static const _statusOptions = <String>[
    'ACTIVE',
    'SUSPENDED',
    'DELETED',
    'PENDING_VERIFICATION',
  ];
  static const _sortOptions = <String>[
    'fname',
    'lname',
    'email',
    'role',
    'status',
    'createdat',
    'updatedat',
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      AdminUsersController(currentAdminEmail: _adminEmail()),
      tag: 'admin-users-controller',
    );
    _controller.loadFirstPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E1E86),
        foregroundColor: Colors.white,
        titleSpacing: 16,
        title: _buildSearchBar(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              onPressed: _openFilterSheet,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.filter_alt_outlined),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _controller.refreshList,
        child: Obx(() {
          if (_controller.isLoading.value && _controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage.value.isNotEmpty && _controller.items.isEmpty) {
            return _ErrorState(
              message: _controller.errorMessage.value,
              onRetry: _controller.loadFirstPage,
            );
          }

          return ListView(
            padding: _contentPadding(context),
            children: [
              if (_controller.isEmpty)
                const _EmptyState(message: 'No users found for selected filters.')
              else
                ..._controller.items.map(_buildUserCard),
              const SizedBox(height: 12),
              _PaginationBar(controller: _controller),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: _controller.applySearch,
      decoration: InputDecoration(
        hintText: 'Search users',
        filled: true,
        fillColor: const Color(0xFFE7E5EC),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF595761)),
        suffixIcon: IconButton(
          onPressed: () => _controller.applySearch(_searchController.text),
          icon: const Icon(Icons.arrow_forward, color: Color(0xFF595761)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    String? roleValue = _controller.roleFilter.value;
    String? statusValue = _controller.statusFilter.value;
    String sortValue = _controller.sortBy.value;
    String directionValue = _controller.direction.value;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String?>(
                      initialValue: roleValue,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [null, ..._roleOptions]
                          .map(
                            (e) => DropdownMenuItem<String?>(
                              value: e,
                              child: Text(e ?? 'All Roles'),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setModalState(() => roleValue = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: statusValue,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [null, ..._statusOptions]
                          .map(
                            (e) => DropdownMenuItem<String?>(
                              value: e,
                              child: Text(e ?? 'All Status'),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setModalState(() => statusValue = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: sortValue,
                      decoration: const InputDecoration(labelText: 'Sort By'),
                      items: _sortOptions
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(growable: false),
                      onChanged: (value) =>
                          setModalState(() => sortValue = value ?? 'updatedat'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: directionValue,
                      decoration: const InputDecoration(labelText: 'Direction'),
                      items: const [
                        DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                        DropdownMenuItem(value: 'desc', child: Text('Descending')),
                      ],
                      onChanged: (value) =>
                          setModalState(() => directionValue = value ?? 'desc'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              _searchController.clear();
                              await _controller.applySearch('');
                              await _controller.setRoleFilter(null);
                              await _controller.setStatusFilter(null);
                              await _controller.setSort('updatedat');
                              if (_controller.direction.value != 'desc') {
                                await _controller.toggleDirection();
                              }
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _controller.setRoleFilter(roleValue);
                              await _controller.setStatusFilter(statusValue);
                              await _controller.setSort(sortValue);
                              if (_controller.direction.value != directionValue) {
                                await _controller.toggleDirection();
                              }
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserCard(AdminUserDto user) {
    return Card(
      child: ListTile(
        title: Text(user.fullName.isEmpty ? user.email : user.fullName),
        subtitle: Text('Email: ${user.email}\nRole: ${user.role} | Status: ${user.status}'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await _showAccessSheet(context, user);
            } else if (value == 'softDelete') {
              await _controller.deleteUser(user, hardDelete: false);
            } else if (value == 'hardDelete') {
              await _controller.deleteUser(user, hardDelete: true);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Update access')),
            PopupMenuItem(value: 'softDelete', child: Text('Soft delete')),
            PopupMenuItem(value: 'hardDelete', child: Text('Hard delete')),
          ],
        ),
      ),
    );
  }

  Future<void> _showAccessSheet(BuildContext context, AdminUserDto user) async {
    String? roleValue = user.role;
    String? statusValue = user.status;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Update Access', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: roleValue,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: _roleOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(growable: false),
                    onChanged: (v) => setLocalState(() => roleValue = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: statusValue,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _statusOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(growable: false),
                    onChanged: (v) => setLocalState(() => statusValue = v),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _controller.updateAccess(
                          user: user,
                          role: roleValue,
                          status: statusValue,
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _adminEmail() {
    final email = (widget.user['email'] as String?)?.trim() ?? '';
    return email.isEmpty ? 'admin@gmail.com' : email;
  }

  EdgeInsets _contentPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = width >= 1200
        ? 32.0
        : width >= 900
            ? 24.0
            : 16.0;
    return EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24);
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.controller});

  final AdminUsersController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Total: ${controller.totalElements.value} | Page ${controller.page.value + 1}/${controller.totalPages.value}',
        ),
        const Spacer(),
        IconButton(
          onPressed: controller.isFirstPage.value ? null : controller.goToPreviousPage,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          onPressed: controller.isLastPage.value ? null : controller.goToNextPage,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(message)),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
