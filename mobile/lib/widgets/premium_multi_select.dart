import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A premium multi-select field that opens a modal bottom sheet with checkboxes.
/// Shows "Any" when nothing is selected. Matches the PremiumDropdown design.
class PremiumMultiSelect extends StatelessWidget {
  final String label;
  final List<String> selectedValues;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final String? hint;
  final bool showSearch;
  final bool isDarkLabel;

  const PremiumMultiSelect({
    super.key,
    required this.label,
    required this.selectedValues,
    required this.items,
    required this.onChanged,
    this.hint,
    this.showSearch = false,
    this.isDarkLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = selectedValues.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDarkLabel
                ? Colors.white.withOpacity(0.9)
                : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showSelectionSheet(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDarkLabel
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasValue
                    ? const Color(0xFFFF5722).withOpacity(0.3)
                    : Colors.grey[300]!,
                width: hasValue ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: hasValue
                      ? const Color(0xFFFF5722).withOpacity(0.06)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: hasValue
                      ? Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: selectedValues.map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5722).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFFF5722).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                item,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFFF5722),
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      : Text(
                          hint ?? 'Any',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                ),
                Icon(
                  Icons.expand_more_rounded,
                  color: hasValue
                      ? const Color(0xFFFF5722)
                      : Colors.grey[400],
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSelectionSheet(BuildContext context) {
    final shouldSearch = showSearch || items.length > 8;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _MultiSelectionSheet(
        title: label,
        items: items,
        selectedValues: List<String>.from(selectedValues),
        showSearch: shouldSearch,
        onDone: (selected) {
          onChanged(selected);
          Navigator.pop(sheetContext);
        },
      ),
    );
  }
}

class _MultiSelectionSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final List<String> selectedValues;
  final bool showSearch;
  final ValueChanged<List<String>> onDone;

  const _MultiSelectionSheet({
    required this.title,
    required this.items,
    required this.selectedValues,
    required this.showSearch,
    required this.onDone,
  });

  @override
  State<_MultiSelectionSheet> createState() => _MultiSelectionSheetState();
}

class _MultiSelectionSheetState extends State<_MultiSelectionSheet> {
  late TextEditingController _searchController;
  late List<String> _filteredItems;
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items;
    _selected = List<String>.from(widget.selectedValues);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleItem(String item) {
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else {
        _selected.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title + Done button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 4),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (_selected.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _selected.clear()),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => widget.onDone(_selected),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Done${_selected.isNotEmpty ? ' (${_selected.length})' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          if (widget.showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

          // Selected count
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selected.length} selected',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFFF5722),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey[200]),

          // Items list
          Flexible(
            child: _filteredItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No results found',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = _selected.contains(item);

                      return InkWell(
                        onTap: () => _toggleItem(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF5722).withOpacity(0.06)
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected
                                    ? const Color(0xFFFF5722)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFF5722)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFF5722)
                                        : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? const Color(0xFFFF5722)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
