// lib/form_anggaran.dart
import 'package:flutter/material.dart';
import 'database_helper.dart';

class FormAnggaran extends StatefulWidget {
  final Map<String, dynamic>? budget; // null = tambah, ada = edit

  const FormAnggaran({super.key, this.budget});

  @override
  State<FormAnggaran> createState() => _FormAnggaranState();
}

class _FormAnggaranState extends State<FormAnggaran> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _limitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _categoryController.text = widget.budget!['category'] ?? '';
      _limitController.text = widget.budget!['limit_amount']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    final row = {
      'category': _categoryController.text.trim(),
      'limit_amount': int.parse(_limitController.text.trim()),
    };

    if (widget.budget == null) {
      await _dbHelper.insertBudget(row);
    } else {
      await _dbHelper.updateBudget(widget.budget!['id'], row);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.budget != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Anggaran' : 'Tambah Anggaran'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Kategori (mis: Makanan)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Kategori wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _limitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Batas Anggaran (Rp)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Jumlah wajib diisi';
                  final n = int.tryParse(v.trim());
                  if (n == null) return 'Masukkan angka yang valid';
                  if (n < 0) return 'Jumlah tidak boleh negatif';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveData,
                  child: Text(isEdit ? 'Update' : 'Simpan'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}