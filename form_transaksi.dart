// lib/form_transaksi.dart
import 'package:flutter/material.dart';
import 'database_helper.dart';

class FormTransaksi extends StatefulWidget {
  final Map<String, dynamic>? transaction; // null = tambah, ada = edit

  const FormTransaksi({super.key, this.transaction});

  @override
  State<FormTransaksi> createState() => _FormTransaksiState();
}

class _FormTransaksiState extends State<FormTransaksi> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String _type = 'expense';
  int? _selectedBudgetId;
  List<Map<String, dynamic>> _budgets = [];

  final DatabaseHelper _dbHelper = DatabaseHelper();

  int? editingId; // untuk mode edit

  @override
  void initState() {
    super.initState();
    _loadBudgets();
    _loadIfEdit();
  }

  void _loadIfEdit() {
    if (widget.transaction != null) {
      final t = widget.transaction!;
      editingId = t['id'];

      _titleController.text = t['title'] ?? '';
      _amountController.text = t['amount'].toString();
      _type = t['type'];
      _selectedBudgetId = t['budget_id'];
    }
  }

  Future<void> _loadBudgets() async {
    final data = await _dbHelper.getBudgets();

    setState(() {
      _budgets = data;

      // Jika tambah baru -> pilih pertama
      if (editingId == null && _budgets.isNotEmpty) {
        _selectedBudgetId = _budgets.first['id'] as int;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBudgetId == null && _type == 'expense') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori anggaran wajib dipilih')),
      );
      return;
    }

    final amount = int.parse(_amountController.text.trim());

    final row = {
      'title': _titleController.text.trim(),
      'amount': amount,
      'type': _type,
      'budget_id': _selectedBudgetId,
      'note': '',
      'created_at': DateTime.now().toIso8601String(),
    };

    // ---- INSERT ----
    if (editingId == null) {
      await _dbHelper.insertTransaction(row);

      if (_type == 'expense' && _selectedBudgetId != null) {
        await _dbHelper.updateBudgetSpent(_selectedBudgetId!, amount);
      }
    }
    // ---- UPDATE ----
    else {
      final oldAmount = widget.transaction!['amount'] as int;
      final oldBudget = widget.transaction!['budget_id'] as int?;

      await _dbHelper.updateTransaction(editingId!, row);

      // Jika sebelumnya expense, kembalikan spent lama
      if (oldBudget != null && widget.transaction!['type'] == 'expense') {
        await _dbHelper.reduceBudgetSpent(oldBudget, oldAmount);
      }

      // Jika sekarang expense, tambahkan spent baru
      if (_type == 'expense' && _selectedBudgetId != null) {
        await _dbHelper.updateBudgetSpent(_selectedBudgetId!, amount);
      }
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = editingId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Transaksi" : "Tambah Transaksi"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul/Deskripsi',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Judul wajib' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal (Rp)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nominal wajib';
                  if (int.tryParse(v.trim()) == null) {
                    return 'Masukkan angka valid';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Text('Tipe:'),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _type,
                    items: const [
                      DropdownMenuItem(value: 'expense', child: Text('Expense')),
                      DropdownMenuItem(value: 'income', child: Text('Income')),
                    ],
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ----------------- KATEGORI BUDGET -----------------
              Row(
                children: [
                  const Text('Kategori:'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _budgets.isEmpty
                        ? const Text(
                            'Belum ada kategori anggaran.\nTambah anggaran dulu.',
                          )
                        : DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedBudgetId,
                            items: _budgets
                                .map(
                                  (e) => DropdownMenuItem<int>(
                                    value: e['id'] as int,
                                    child: Text(
                                      "${e['category']} (Limit: Rp ${e['limit_amount']})",
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedBudgetId = v;
                              });
                            },
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(isEdit ? "Update" : "Simpan"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}