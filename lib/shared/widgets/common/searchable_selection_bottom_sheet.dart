import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';

/// Modal bottom sheet with a search field and selectable list items.
void showSearchableSelectionBottomSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required T? selectedItem,
  required String Function(T) getDisplayName,
  required ValueChanged<T> onSelected,
  String searchHint = 'ابحث...',
  String? clearOptionLabel,
  VoidCallback? onClear,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (sheetContext) => _SearchableSelectionSheet<T>(
      title: title,
      items: items,
      selectedItem: selectedItem,
      getDisplayName: getDisplayName,
      onSelected: onSelected,
      searchHint: searchHint,
      clearOptionLabel: clearOptionLabel,
      onClear: onClear,
    ),
  );
}

class _SearchableSelectionSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) getDisplayName;
  final ValueChanged<T> onSelected;
  final String searchHint;
  final String? clearOptionLabel;
  final VoidCallback? onClear;

  const _SearchableSelectionSheet({
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.getDisplayName,
    required this.onSelected,
    required this.searchHint,
    this.clearOptionLabel,
    this.onClear,
  });

  @override
  State<_SearchableSelectionSheet<T>> createState() =>
      _SearchableSelectionSheetState<T>();
}

class _SearchableSelectionSheetState<T>
    extends State<_SearchableSelectionSheet<T>> {
  late final TextEditingController _searchController;
  late List<T> _filtered;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = List<T>.from(widget.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List<T>.from(widget.items)
          : widget.items
              .where((e) => widget.getDisplayName(e).toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final showClear =
        widget.clearOptionLabel != null && widget.onClear != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.textHint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(widget.title, style: AppTextStyles.headingSmall),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: AppTextStyles.input.copyWith(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: AppTextStyles.inputHint,
                prefixIcon: Icon(Icons.search, color: context.textSecondary),
                filled: true,
                fillColor: context.inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.inputBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.inputBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: _applyFilter,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.dividerColor, height: 1),
          Expanded(
            child: _filtered.isEmpty && !showClear
                ? Center(
                    child: Text(
                      'لا توجد نتائج',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: _filtered.length + (showClear ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (showClear && index == 0) {
                        return ListTile(
                          title: Text(
                            widget.clearOptionLabel!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: widget.selectedItem == null
                                  ? AppColors.primaryColor
                                  : context.textPrimary,
                              fontWeight: widget.selectedItem == null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: widget.selectedItem == null
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryColor,
                                )
                              : null,
                          onTap: () {
                            widget.onClear!();
                            Navigator.pop(context);
                          },
                        );
                      }

                      final itemIndex = showClear ? index - 1 : index;
                      final item = _filtered[itemIndex];
                      final isSelected = item == widget.selectedItem;
                      return ListTile(
                        title: Text(
                          widget.getDisplayName(item),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected
                                ? AppColors.primaryColor
                                : context.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.primaryColor,
                              )
                            : null,
                        onTap: () {
                          widget.onSelected(item);
                          Navigator.pop(context);
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
