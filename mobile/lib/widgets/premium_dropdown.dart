import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A premium dropdown field that opens a modal bottom sheet for selection.
/// Replaces the basic Material DropdownButton with a polished mobile-first experience.
class PremiumDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final String? hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool showSearch;
  final bool isDarkLabel;

  const PremiumDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.showSearch = false,
    this.isDarkLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

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
                  child: Text(
                    hasValue ? value! : (hint ?? 'Select'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: hasValue ? Colors.black87 : Colors.grey[400],
                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: hasValue
                        ? const Color(0xFFFF5722)
                        : Colors.grey[400],
                    size: 22,
                  ),
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
      builder: (sheetContext) => _SelectionSheet(
        title: label,
        items: items,
        selectedValue: value,
        showSearch: shouldSearch,
        onSelected: (selected) {
          onChanged(selected);
          Navigator.pop(sheetContext);
        },
      ),
    );
  }
}

/// The bottom sheet content shown when the dropdown is tapped.
class _SelectionSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selectedValue;
  final bool showSearch;
  final ValueChanged<String> onSelected;

  const _SelectionSheet({
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.showSearch,
    required this.onSelected,
  });

  @override
  State<_SelectionSheet> createState() => _SelectionSheetState();
}

class _SelectionSheetState extends State<_SelectionSheet> {
  late TextEditingController _searchController;
  late List<String> _filteredItems;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items;
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

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.65;

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

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
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
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          if (widget.showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
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

          const SizedBox(height: 8),

          // Divider
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
                      final isSelected = item == widget.selectedValue;

                      return InkWell(
                        onTap: () => widget.onSelected(item),
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
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF5722),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
