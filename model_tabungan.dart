class SavingsModel {
  int? id;
  String title;
  int currentAmount;
  int targetAmount;
  String category;
  String startDate; // yyyy-MM-dd
  String endDate;   // yyyy-MM-dd

  SavingsModel({
    this.id,
    required this.title,
    required this.currentAmount,
    required this.targetAmount,
    required this.category,
    required this.startDate,
    required this.endDate,
  });

  // hitung bulan tersisa secara dinamis
  int get monthsLeft {
    try {
      final s = DateTime.parse(startDate);
      final e = DateTime.parse(endDate);
      return (e.year - s.year) * 12 + (e.month - s.month);
    } catch (_) {
      return 0;
    }
  }

  factory SavingsModel.fromMap(Map<String, dynamic> m) => SavingsModel(
    id: m['id'] as int?,
    title: m['title'] as String,
    currentAmount: m['currentAmount'] as int,
    targetAmount: m['targetAmount'] as int,
    category: m['category'] as String,
    startDate: m['startDate'] as String,
    endDate: m['endDate'] as String,
  );

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'currentAmount': currentAmount,
      'targetAmount': targetAmount,
      'category': category,
      'startDate': startDate,
      'endDate': endDate,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
