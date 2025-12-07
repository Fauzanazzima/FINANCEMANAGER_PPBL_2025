import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'model_tabungan.dart';
import 'db_tabungan.dart';
import 'form_tabungan.dart';

class TabunganScreen extends StatefulWidget {
  const TabunganScreen({super.key});

  @override
  State<TabunganScreen> createState() => _TabunganScreenState();
}

class _TabunganScreenState extends State<TabunganScreen> {
  final NumberFormat fmt =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  List<SavingsModel> items = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final data = await DB_Tabungan().getSavings();
    setState(() => items = data.map((e) => SavingsModel.fromMap(e)).toList());
  }

  Future<void> _onAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FormTabungan()),
    );

    if (result != null && result is SavingsModel) {
      await DB_Tabungan().insertSavings(result.toMap());
      _refresh();
    }
  }

  Future<void> _onEdit(SavingsModel s) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormTabungan(editing: s)),
    );

    if (result != null && result is SavingsModel) {
      await DB_Tabungan().updateSavings(s.id!, result.toMap());
      _refresh();
    }
  }

  Future<void> _onDelete(int id) async {
    await DB_Tabungan().deleteSavings(id);
    _refresh();
  }

  double progress(SavingsModel s) {
    if (s.targetAmount <= 0) return 0;
    return (s.currentAmount / s.targetAmount).clamp(0, 1);
  }

  Map<String, int> categorySummary() {
    final map = <String, int>{};
    for (var s in items) {
      map[s.category] = (map[s.category] ?? 0) + s.currentAmount;
    }
    return map;
  }

  Color categoryColor(String cat) {
    switch (cat) {
      case "Pendidikan":
        return Colors.orange;
      case "Gadget":
        return Colors.purple;
      case "Liburan":
        return Colors.blue;
      case "Rumah":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData categoryIcon(String cat) {
    switch (cat) {
      case "Pendidikan":
        return Icons.school;
      case "Gadget":
        return Icons.devices_other;
      case "Liburan":
        return Icons.beach_access;
      case "Rumah":
        return Icons.home_filled;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catSum = categorySummary();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Tabungan",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...items.map((s) => _savingCard(s)).toList(),
          const SizedBox(height: 22),
          const Text("Rangkuman Kategori Tabungan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3 / 2.3,
            children: [
              _summaryCard("Pendidikan", catSum["Pendidikan"] ?? 0),
              _summaryCard("Liburan", catSum["Liburan"] ?? 0),
              _summaryCard("Gadget", catSum["Gadget"] ?? 0),
              _summaryCard("Rumah", catSum["Rumah"] ?? 0),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAdd,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text("Tambah"),
      ),
    );
  }

  Widget _savingCard(SavingsModel s) {
    final color = categoryColor(s.category);
    final icon = categoryIcon(s.category);
    final prog = progress(s);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == "edit") _onEdit(s);
                  if (v == "delete") _onDelete(s.id!);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: "edit", child: Text("Edit")),
                  PopupMenuItem(value: "delete", child: Text("Hapus")),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text("${s.startDate} - ${s.endDate}",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: prog,
            minHeight: 9,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fmt.format(s.currentAmount),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              Text(
                fmt.format(s.targetAmount),
                style: TextStyle(color: Colors.grey.shade800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text("${(prog * 100).toStringAsFixed(0)}% tercapai",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, int amount) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 5, offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.green.shade100,
            child: Icon(categoryIcon(title), color: Colors.green),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(fmt.format(amount),
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }
}
