import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPreviousPage,
    this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: currentPage > 1 ? onPreviousPage : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
          ),
          Text('Page $currentPage of $totalPages'),
          ElevatedButton.icon(
            onPressed: currentPage < totalPages ? onNextPage : null,
            label: const Text('Next'),
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}
