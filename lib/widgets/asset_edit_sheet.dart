import 'package:flutter/material.dart';

import '../models/asset_item.dart';
import '../theme/app_theme.dart';

Future<AssetItem?> showAssetEditSheet(
  BuildContext context, {
  required String walletId,
}) async {
  final nameController = TextEditingController();
  final noteController = TextEditingController();
  final amountController = TextEditingController();
  var type = AssetItem.debt;

  return showModalBottomSheet<AssetItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '添加资产',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ToggleButtons(
                  isSelected: [type == AssetItem.debt, type == AssetItem.credit],
                  onPressed: (index) {
                    setState(() {
                      type = index == 0 ? AssetItem.debt : AssetItem.credit;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('负债'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('债权'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '名称'),
                ),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: '备注'),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: '金额'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final note = noteController.text.trim();
                      final amount = double.tryParse(amountController.text.trim());
                      if (name.isEmpty || amount == null) return;
                      final now = DateTime.now().toIso8601String();
                      Navigator.pop(
                        sheetContext,
                        AssetItem(
                          id: 'asset_${DateTime.now().microsecondsSinceEpoch}',
                          walletId: walletId,
                          type: type,
                          name: name,
                          note: note,
                          amount: amount,
                          createdAt: now,
                          updatedAt: now,
                        ),
                      );
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
