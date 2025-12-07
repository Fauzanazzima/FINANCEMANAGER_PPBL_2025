import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'custom_widget.dart';
import 'form_transaksi.dart'; // Import Form Transaksi

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  void _refreshTransactions() async {
    final data = await _dbHelper.getTransactions();
    setState(() { _transactions = data; });
  }

  void _deleteItem(int id) async {
    await _dbHelper.deleteTransaction(id);
    _refreshTransactions();
  }

  // Fungsi navigasi ke Form Screen
  void _openFormScreen({Map<String, dynamic>? item}) async {
    // Push ke halaman form 
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormTransaksi(transaction: item)),
    );

    // Jika result == true (ada data disimpan), refresh list
    if (result == true) {
      _refreshTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transaksi")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openFormScreen(item: null), // Tambah Baru (null)
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final item = _transactions[index];
          final isIncome = item['type'] == 'Masuk';
          
          return CustomCard(
            title: item['title'],
            subtitle: item['type'],
            amount: "Rp ${item['amount']}",
            icon: isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            iconColor: isIncome ? Colors.green : Colors.red,
            onDelete: () => _deleteItem(item['id']),
            onEdit: () => _openFormScreen(item: item), // Edit (kirim item)
          );
        },
      ),
    );
  }
}