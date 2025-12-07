import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'model_tabungan.dart';

class FormTabungan extends StatefulWidget {
  final SavingsModel? editing;

  const FormTabungan({super.key, this.editing});

  @override
  State<FormTabungan> createState() => _FormTabunganState();
}

class _FormTabunganState extends State<FormTabungan> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();

  String _category = "Pendidikan";

  final numberFormat = NumberFormat("#,###", "id_ID");
  final dateFormat = DateFormat("yyyy-MM-dd");

  @override
  void initState() {
    super.initState();

    if (widget.editing != null) {
      final s = widget.editing!;
      _titleCtrl.text = s.title;
      // show formatted numbers
      _currentCtrl.text = NumberFormat.decimalPattern('id').format(s.currentAmount);
      _targetCtrl.text = NumberFormat.decimalPattern('id').format(s.targetAmount);
      _startDateCtrl.text = s.startDate;
      _endDateCtrl.text = s.endDate;
      _category = s.category;
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime? selected = await showDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty ? DateTime.tryParse(controller.text) ?? DateTime.now() : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      controller.text = dateFormat.format(selected);
    }
  }

  int cleanNumber(String text) {
    final cleaned = text.replaceAll('.', '').replaceAll(',', '').replaceAll(' ', '');
    if (cleaned.isEmpty) return 0;
    return int.tryParse(cleaned) ?? 0;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _currentCtrl.dispose();
    _targetCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing == null ? "Tambah Tabungan" : "Edit Tabungan"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Judul Tabungan'),
                validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetCtrl,
                decoration: const InputDecoration(labelText: 'Target (Rp)'),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  // buat tampil lebih readable saat user mengetik (opsional)
                  final cleaned = v.replaceAll('.', '').replaceAll(',', '');
                  if (cleaned.isEmpty) return;
                  final formatted = NumberFormat.decimalPattern('id').format(int.tryParse(cleaned) ?? 0);
                  _targetCtrl.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                },
                validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currentCtrl,
                decoration: const InputDecoration(labelText: 'Jumlah Saat Ini (Rp)'),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final cleaned = v.replaceAll('.', '').replaceAll(',', '');
                  if (cleaned.isEmpty) return;
                  final formatted = NumberFormat.decimalPattern('id').format(int.tryParse(cleaned) ?? 0);
                  _currentCtrl.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                },
                validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _startDateCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Tanggal Mulai",
                  suffixIcon: IconButton(icon: const Icon(Icons.calendar_month), onPressed: () => _pickDate(_startDateCtrl)),
                ),
                validator: (v) => v == null || v.isEmpty ? "Wajib dipilih" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _endDateCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Tanggal Berakhir",
                  suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _pickDate(_endDateCtrl)),
                ),
                validator: (v) => v == null || v.isEmpty ? "Wajib dipilih" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: "Kategori"),
                items: const [
                  DropdownMenuItem(value: "Pendidikan", child: Text("Pendidikan")),
                  DropdownMenuItem(value: "Gadget", child: Text("Gadget")),
                  DropdownMenuItem(value: "Liburan", child: Text("Liburan")),
                  DropdownMenuItem(value: "Rumah", child: Text("Rumah")),
                ],
                onChanged: (v) => setState(() => _category = v ?? "Pendidikan"),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: Colors.green),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;

                  final model = SavingsModel(
                    id: widget.editing?.id,
                    title: _titleCtrl.text.trim(),
                    currentAmount: cleanNumber(_currentCtrl.text),
                    targetAmount: cleanNumber(_targetCtrl.text),
                    category: _category,
                    startDate: _startDateCtrl.text,
                    endDate: _endDateCtrl.text,
                  );

                  Navigator.pop(context, model);
                },
                child: Text(widget.editing == null ? 'Simpan' : 'Update'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
