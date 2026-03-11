import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../../shared/widgets/common/error_state.dart';
import '../cubit/permissions_cubit.dart';
import '../../data/models/permission_model.dart';

/// Permissions management screen (admin). Requires permissions.view; create/update/delete gated by abilities.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _canCreate = false;
  bool _canUpdate = false;
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    final abilities = StorageService.getAbilities();
    _canCreate = abilities.contains('permissions.create');
    _canUpdate = abilities.contains('permissions.update');
    _canDelete = abilities.contains('permissions.delete');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PermissionsCubit>().getPermissions();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final state = context.read<PermissionsCubit>().state;
    if (state is PermissionsLoaded && state.hasMore) {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        context.read<PermissionsCubit>().getPermissions(
              search: state.search,
              page: state.currentPage + 1,
            );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة صلاحية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  hintText: 'مثال: عرض المستخدمين',
                ),
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: slugController,
                decoration: const InputDecoration(
                  labelText: 'المعرّف (slug)',
                  hintText: 'مثال: users-view',
                ),
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'الوصف (اختياري)',
                ),
                maxLines: 2,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final slug = slugController.text.trim();
              if (name.isEmpty || slug.isEmpty) {
                CustomToast.showError(context, 'الاسم والمعرّف مطلوبان');
                return;
              }
              Navigator.of(ctx).pop();
              await context.read<PermissionsCubit>().createPermission(
                    name: name,
                    slug: slug,
                    description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                  );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(PermissionModel permission) {
    final nameController = TextEditingController(text: permission.name);
    final slugController = TextEditingController(text: permission.slug);
    final descController = TextEditingController(text: permission.description ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الصلاحية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'الاسم'),
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: slugController,
                decoration: const InputDecoration(labelText: 'المعرّف (slug)'),
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'الوصف (اختياري)'),
                maxLines: 2,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final slug = slugController.text.trim();
              if (name.isEmpty || slug.isEmpty) {
                CustomToast.showError(context, 'الاسم والمعرّف مطلوبان');
                return;
              }
              Navigator.of(ctx).pop();
              await context.read<PermissionsCubit>().updatePermission(
                    permission.id,
                    name: name,
                    slug: slug,
                    description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                  );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(PermissionModel permission) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الصلاحية'),
        content: Text(
          'هل أنت متأكد من حذف "${permission.name}"؟ لا يمكن حذف صلاحية مرتبطة بأدوار.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<PermissionsCubit>().deletePermission(permission.id);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text('الصلاحيات', style: AppTextStyles.headingMedium),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو المعرّف',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              textDirection: TextDirection.ltr,
              onSubmitted: (value) {
                context.read<PermissionsCubit>().getPermissions(search: value.trim().isEmpty ? null : value.trim());
              },
            ),
          ),
          Expanded(
            child: BlocConsumer<PermissionsCubit, PermissionsState>(
              listener: (context, state) {
                if (state is PermissionsError || state is PermissionDetailError || state is PermissionActionError) {
                  final msg = state is PermissionsError
                      ? state.message
                      : state is PermissionDetailError
                          ? state.message
                          : (state as PermissionActionError).message;
                  CustomToast.showError(context, msg);
                }
                if (state is PermissionActionSuccess) {
                  CustomToast.showSuccess(context, state.message);
                  final current = context.read<PermissionsCubit>().state;
                  String? search;
                  if (current is PermissionsLoaded) search = current.search;
                  context.read<PermissionsCubit>().getPermissions(search: search, refresh: true);
                }
              },
              builder: (context, state) {
                if (state is PermissionsLoading && (state is! PermissionsLoaded)) {
                  return const Center(child: LoadingIndicator());
                }
                if (state is PermissionsError) {
                  return Center(
                    child: ErrorState(
                      message: state.message,
                      onRetry: () => context.read<PermissionsCubit>().getPermissions(),
                    ),
                  );
                }
                if (state is PermissionsLoaded) {
                  if (state.permissions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, size: 64, color: context.textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            state.search != null && state.search!.isNotEmpty
                                ? 'لا توجد نتائج للبحث'
                                : 'لا توجد صلاحيات',
                            style: AppTextStyles.bodyMedium.copyWith(color: context.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<PermissionsCubit>().getPermissions(
                            search: state.search,
                            refresh: true,
                          );
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: state.permissions.length,
                      itemBuilder: (context, index) {
                        final p = state.permissions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                              child: Icon(Icons.lock_outline, color: AppColors.primaryColor),
                            ),
                            title: Text(
                              p.name,
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  p.slug,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: context.textSecondary,
                                    fontFamily: 'monospace',
                                  ),
                                  textDirection: TextDirection.ltr,
                                ),
                                if (p.description != null && p.description!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    p.description!,
                                    style: AppTextStyles.bodySmall.copyWith(color: context.textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (p.rolesCount != null && p.rolesCount! > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${p.rolesCount} دور',
                                      style: AppTextStyles.bodySmall.copyWith(color: context.textSecondary),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: _canUpdate || _canDelete
                                ? PopupMenuButton<String>(
                                    itemBuilder: (ctx) => [
                                      if (_canUpdate) const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                      if (_canDelete) const PopupMenuItem(value: 'delete', child: Text('حذف')),
                                    ].whereType<PopupMenuItem<String>>().toList(),
                                    onSelected: (value) {
                                      if (value == 'edit') _showEditDialog(p);
                                      if (value == 'delete') _confirmDelete(p);
                                    },
                                  )
                                : null,
                            onTap: () {
                              if (_canUpdate) _showEditDialog(p);
                            },
                          ),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _canCreate
          ? FloatingActionButton(
              onPressed: _showCreateDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
