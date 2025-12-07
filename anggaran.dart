// lib/budget_page.dart
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'custom_widget.dart';
import 'form_anggaran.dart';
import 'form_transaksi.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // setiap item: { id, category, allocated, spent, remaining }
  List<Map<String, dynamic>> _budgets = [];
  int _totalAllocated = 0;
  int _totalSpent = 0;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await _refreshBudgets();
    await _refreshTotals();
  }

  Future<void> _refreshBudgets() async {
    final data = await _dbHelper.getBudgets();
    final List<Map<String, dynamic>> withSpent = [];

    for (var item in data) {
      final category = item['category'] as String;
      final allocated = (item['limit_amount'] as num).toInt();
      final spent = await _dbHelper.getTotalSpentByCategory(category);

      withSpent.add ({
        'id': item['id'],
        'category': category,
        'allocated': allocated,
        'spent': spent,
        'remaining': allocated - spent,
      });
    }

    setState(() {
      _budgets = withSpent;
    });
  }

  Future<void> _refreshTotals() async {
    final totalAllocated = await _dbHelper.getTotalDialokasikan();
    final totalSpent = await _dbHelper.getTotalTerpakai();

    setState(() {
      _totalAllocated = totalAllocated;
      _totalSpent = totalSpent;
    });
  }

  Future<void> _deleteBudget(int id) async {
    await _dbHelper.deleteBudget(id);
    await _refreshAll();
  }

  Future<void> _openFormAnggaran({Map<String, dynamic>? item}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormAnggaran(budget: item)),
    );
    if (result == true) {
      await _refreshAll();
    }
  }

  Future<void> _openFormTransaksi() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FormTransaksi()),
    );
    if (result == true) {
      await _refreshAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingTotal = (_totalAllocated - _totalSpent).clamp(0, 1 << 60);
    final progress = _totalAllocated == 0 ? 0.0 : (_totalSpent / _totalAllocated).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggaran'),
        actions: [
          IconButton(
            tooltip: 'Tambah Transaksi',
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: _openFormTransaksi,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openFormAnggaran(item: null),
        child: const Icon(Icons.add),
        tooltip: 'Tambah Anggaran',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul & month dropdown (simple)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Anggaran Bulan Ini', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    // Placeholder dropdown (you can connect to provider later)
                    DropdownButton<String>(
                      value: 'Januari',
                      items: <String>['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (_) {},
                    )
                  ],
                ),

                const SizedBox(height: 16),

                // Ringkasan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,3))],
                  ),
                  child: Column(
                    children: [
                      Text('Sisa Anggaran', style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Text('Rp ${_formatCurrency(remainingTotal)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 12,
                                backgroundColor: Colors.grey.shade200,
                                color: progress >= 0.7 ? Colors.red : Colors.green,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text('Terpakai dari total'),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Two small cards: allocated & spent
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Dialokasikan', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text('Rp ${_formatCurrency(_totalAllocated)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Terpakai', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text('Rp ${_formatCurrency(_totalSpent)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text('Daftar Anggaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // List of budgets with spent & remaining
                ListView.builder(
                  itemCount: _budgets.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final item = _budgets[index];
                    final allocated = item['allocated'] as int;
                    final spent = item['spent'] as int;
                    final remaining = item['remaining'] as int;

                    final progressCategory = allocated == 0 ? 0.0 : (spent / allocated).clamp(0.0, 1.0);

                    return Column(
                      children: [
                        CustomCard(
                          title: item['category'],
                          subtitle:
                              'Dialokasikan: Rp ${_formatCurrency(allocated)}\nTerpakai: Rp ${_formatCurrency(spent)}\nSisa: Rp ${_formatCurrency(remaining)}',
                          amount: null,
                          icon: Icons.pie_chart,
                          iconColor: Colors.blue,
                          onEdit: () => _openFormAnggaran(item: item),
                          onDelete: () => _confirmDeleteBudget(item['id']),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: LinearProgressIndicator(
                            value: progressCategory,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            color: progressCategory > 0.8 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteBudget(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Anggaran'),
        content: const Text('Yakin ingin menghapus anggaran ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteBudget(id);
      await _refreshAll();
    }
  }

  String _formatCurrency(num value) {
    // simple formatting: thousands separator
    final s = value.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }
}