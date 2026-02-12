import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/search_provider.dart';
import '../providers/barcode_handler_provider.dart';

class CheckoutSearchBar extends ConsumerStatefulWidget {
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;

  const CheckoutSearchBar({
    super.key,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  ConsumerState<CheckoutSearchBar> createState() => _CheckoutSearchBarState();
}

class _CheckoutSearchBarState extends ConsumerState<CheckoutSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _internalFocusNode;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _internalFocusNode = FocusNode();

    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(searchNotifierProvider.notifier).setQuery(_controller.text);
  }

  // ---- Fixed: Make async so we can await barcode processing ----
  Future<void> _onSubmitted(String value) async {
    final barcodeHandler = ref.read(barcodeHandlerProvider);

    // Await the async result
    final wasBarcode = await barcodeHandler.tryProcessBarcode(value);

    if (wasBarcode) {
      _controller.clear();
      _effectiveFocusNode.requestFocus();
    }

    widget.onSubmitted?.call();
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(searchNotifierProvider.notifier).clearQuery();
    _effectiveFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _effectiveFocusNode,
      decoration: InputDecoration(
        labelText: 'Search or scan barcode',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
              )
            : null,
      ),
      onSubmitted: _onSubmitted, // Async function is fine here
    );
  }
}
