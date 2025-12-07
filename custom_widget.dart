// lib/custom_widget.dart
import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? amount;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CustomCard({
    super.key,
    required this.title,
    this.subtitle,
    this.amount,
    required this.icon,
    this.iconColor,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: (iconColor ?? Colors.blue).withOpacity(0.12),
          child: Icon(icon, color: iconColor ?? Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: SizedBox(
          width: 110,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                  tooltip: 'Hapus',
                ),
            ],
          ),
        ),
      ),
    );
  }
}