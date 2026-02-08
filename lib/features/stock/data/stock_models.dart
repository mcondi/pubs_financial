class StockSummary {
  final int venueId;
  final DateTime weekendDate;
  final String mode;

  final double inventoryFood;
  final double inventoryBeverage;

  final double weeklyFoodCogs;
  final double weeklyBeverageCogs;

  final double foodWeeksOnHand;
  final double beverageWeeksOnHand;

  final double foodStockTurnsAnnualised;
  final double beverageStockTurnsAnnualised;

  final double foodPurchases;

  StockSummary({
    required this.venueId,
    required this.weekendDate,
    required this.mode,
    required this.inventoryFood,
    required this.inventoryBeverage,
    required this.weeklyFoodCogs,
    required this.weeklyBeverageCogs,
    required this.foodWeeksOnHand,
    required this.beverageWeeksOnHand,
    required this.foodStockTurnsAnnualised,
    required this.beverageStockTurnsAnnualised,
    required this.foodPurchases,
  });

  factory StockSummary.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

    return StockSummary(
      venueId: (json['venueId'] as num).toInt(),
      weekendDate: DateTime.parse(json['weekendDate'] as String),
      mode: (json['mode'] as String?) ?? 'weekly',
      inventoryFood: d(json['inventoryFood']),
      inventoryBeverage: d(json['inventoryBeverage']),
      weeklyFoodCogs: d(json['weeklyFoodCogs']),
      weeklyBeverageCogs: d(json['weeklyBeverageCogs']),
      foodWeeksOnHand: d(json['foodWeeksOnHand']),
      beverageWeeksOnHand: d(json['beverageWeeksOnHand']),
      foodStockTurnsAnnualised: d(json['foodStockTurnsAnnualised']),
      beverageStockTurnsAnnualised: d(json['beverageStockTurnsAnnualised']),
      foodPurchases: d(json['foodPurchases']),
    );
  }
}
