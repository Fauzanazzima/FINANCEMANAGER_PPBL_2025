import 'package:flutter/material.dart';
import 'database_helper.dart';

class FromTabungan extends StatefulWidget {
  const FromTabungan({super.key});

  @override
  State<FromTabungan> createState() => _TambahTabunganFormState();
}

class _TambahTabunganFormState extends State<FromTabungan> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _limitController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _categoryController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final db = DatabaseHelper();

    final data = {
      "category": _categoryController.text.trim(),
      "limit_amount": int.parse(_limitController.text.trim()),
      "spent_amount": 0,
    };

    final id = await db.insertBudget(data);

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (id > 0) {
      Navigator.pop(context, true); // <-- kirim sinyal sukses
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menambahkan tabungan")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Tabungan"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: "Nama Tabungan / Kategori",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Input nama tabungan";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _limitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Target Tabungan (limit)",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Input target tabungan";
                  }
                  if (int.tryParse(value) == null) {
                    return "Harus angka";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green,
                  ),
                  onPressed: _isSaving ? null : _saveBudget,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Simpan",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
