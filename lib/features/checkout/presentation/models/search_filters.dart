class SearchFilters {
  final String query;
  final String? selectedCategory;

  const SearchFilters({
    this.query = '',
    this.selectedCategory,
  });

  bool get hasActiveFilters => query.isNotEmpty || selectedCategory != null;

  SearchFilters copyWith({
    String? query,
    String? Function()? selectedCategory,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      selectedCategory:
          selectedCategory != null ? selectedCategory() : this.selectedCategory,
    );
  }

  SearchFilters clearQuery() {
    return SearchFilters(
      query: '',
      selectedCategory: selectedCategory,
    );
  }

  SearchFilters clearCategory() {
    return SearchFilters(
      query: query,
      selectedCategory: null,
    );
  }

  SearchFilters clear() {
    return const SearchFilters();
  }
}
