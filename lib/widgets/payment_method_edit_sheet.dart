import 'package:flutter/material.dart';

Future<String?> showPaymentMethodEditSheet(
  BuildContext context, {
  required String title,
  String initialName = '',
  String confirmText = '保存',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _PaymentMethodEditSheet(
      title: title,
      initialName: initialName,
      confirmText: confirmText,
    ),
  );
}

class _PaymentMethodEditSheet extends StatefulWidget {
  const _PaymentMethodEditSheet({
    required this.title,
    required this.initialName,
    required this.confirmText,
  });

  final String title;
  final String initialName;
  final String confirmText;

  @override
  State<_PaymentMethodEditSheet> createState() => _PaymentMethodEditSheetState();
}

class _PaymentMethodEditSheetState extends State<_PaymentMethodEditSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: '输入名称',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: Text(widget.confirmText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
