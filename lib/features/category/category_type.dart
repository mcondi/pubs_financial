enum CategoryType {
  food,
  beverage,
  retail,
  accommodation,
}

extension CategoryTypeX on CategoryType {
  String get title {
    switch (this) {
      case CategoryType.food:
        return 'Food';
      case CategoryType.beverage:
        return 'Beverage';
      case CategoryType.retail:
        return 'Retail';
      case CategoryType.accommodation:
        return 'Accommodation';
    }
  }

  String get apiKey {
    // must match backend keys used inside categories/metrics arrays
    switch (this) {
      case CategoryType.food:
        return 'Food';
      case CategoryType.beverage:
        return 'Beverage';
      case CategoryType.retail:
        return 'Retail';
      case CategoryType.accommodation:
        return 'Accommodation';
    }
  }

  bool get showsWages => this == CategoryType.food || this == CategoryType.beverage;
}
