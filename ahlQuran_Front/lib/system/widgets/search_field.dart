import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for managing searchable lists.
class SearchController<T> extends GetxController {
  final RxString searchText = ''.obs;
  final RxList<T> originalList = <T>[].obs;
  final RxList<T> filteredList = <T>[].obs;
  final RxBool showResults = false.obs;

  final bool Function(T item, String query) filter;

  SearchController({
    required List<T> items,
    required this.filter,
  }) {
    originalList.value = items;
  }

  void updateSearch(String text) {
    searchText.value = text;

    if (text.trim().length < 3) {
      showResults.value = false;
      filteredList.clear();
      return;
    }

    filteredList.value =
        originalList.where((item) => filter(item, text)).toList();
    showResults.value = true;
  }

  void reset() {
    searchText.value = '';
    filteredList.clear();
    showResults.value = false;
  }
}

/// Reusable search field with logic to control when results show.
class SearchField<T> extends StatefulWidget {
  final SearchController<T> controller;
  final String hint;
  final Widget Function(T item)? itemBuilder; // Custom tile renderer

  const SearchField({
    super.key,
    required this.controller,
    this.hint = 'Search...',
    this.itemBuilder,
  });

  @override
  State<SearchField<T>> createState() => _SearchFieldState<T>();
}

class _SearchFieldState<T> extends State<SearchField<T>> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.controller.searchText.value);
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.controller.showResults.value = true;
      }
    });

    widget.controller.searchText.listen((value) {
      if (_textController.text != value) {
        _textController.text = value;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min, // minimize vertical size to contents
      children: [
        TextField(
          controller: _textController,
          focusNode: _focusNode,
          onChanged: widget.controller.updateSearch,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            suffixIcon: Obx(() {
              final hasText = widget.controller.searchText.value.isNotEmpty;
              return hasText
                  ? IconButton(
                      icon:
                          Icon(Icons.clear, color: theme.colorScheme.onSurface),
                      onPressed: () {
                        _textController.clear();
                        widget.controller.reset();
                      },
                    )
                  : const SizedBox.shrink();
            }),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),

        // Wrap search results in Flexible to give bounded height
        Flexible(
          child: Obx(() {
            final showResults = widget.controller.showResults.value;
            final searchText = widget.controller.searchText.value;
            final filtered = widget.controller.filteredList;

            if (!showResults || searchText.isEmpty) {
              // No results shown
              return const SizedBox.shrink();
            }

            if (filtered.isEmpty) {
              // Show "no results" message, centered vertically & horizontally
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'لا توجد نتائج',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // Show the filtered list with proper constraints
            return ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = filtered[index];
                if (widget.itemBuilder != null) {
                  return widget.itemBuilder!(item);
                }
                return ListTile(
                  title:
                      Text(item.toString(), textDirection: TextDirection.rtl),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
