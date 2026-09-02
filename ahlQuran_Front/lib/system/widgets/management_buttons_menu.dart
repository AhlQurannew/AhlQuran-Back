import 'package:flutter/material.dart';

class TopButtons<T> extends StatelessWidget {
  final VoidCallback? onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool hasSelection;

  const TopButtons({
    super.key,
    this.onAdd,
    this.onEdit,
    this.onDelete,
    this.hasSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.black),
          onPressed: onAdd,
        ),
        IconButton(
          icon: Icon(
            Icons.edit,
            color: hasSelection ? Colors.greenAccent : Colors.grey,
          ),
          onPressed: hasSelection ? onEdit : null,
        ),
        IconButton(
          icon: Icon(
            Icons.delete,
            color: hasSelection ? Colors.red : Colors.grey,
          ),
          onPressed: hasSelection ? onDelete : null,
        ),
      ],
    );
  }
}
