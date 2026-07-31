import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/payment_method.dart';
import 'payment_method_widgets.dart';
import 'date_picker.dart';
import 'note_editor.dart';
import '../providers/payment_method_provider.dart';

class CalculatorKeyboard extends ConsumerStatefulWidget {
  const CalculatorKeyboard({
    super.key,
    required this.onComplete,
    required this.categoryName,
    required this.categoryIconPath,
    required this.initialPaymentMethod,
    this.initialAmount,
    this.initialNote,
    this.initialDate,
    this.onClose,
  });

  final void Function(
    double amount,
    String note,
    DateTime date,
    String paymentMethod,
  ) onComplete;
  final String categoryName;
  final String categoryIconPath;
  final String initialPaymentMethod;
  final double? initialAmount;
  final String? initialNote;
  final DateTime? initialDate;
  final VoidCallback? onClose;

  @override
  ConsumerState<CalculatorKeyboard> createState() => _CalculatorKeyboardState();
}

class _CalculatorKeyboardState extends ConsumerState<CalculatorKeyboard>
    with WidgetsBindingObserver {
  static const int _maxIntegerDigits = 8;
  static const int _maxDecimalDigits = 2;
  static const double _maxResultValue = 99999999.99;

  double _result = 0;
  String? _pendingOp;
  String _current = '0';
  bool _startNew = true;
  DateTime _selectedDate = DateTime.now();
  String _note = '';
  String _paymentMethod = PaymentMethod.wechat;
  double _bottomSafeArea = 0;

  double _readPlatformBottomSafeArea() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.viewPadding.bottom / view.devicePixelRatio;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bottomSafeArea = _readPlatformBottomSafeArea();
    // 编辑模式：预填初始值
    if (widget.initialAmount != null) {
      _current = _fmt(widget.initialAmount!);
      _startNew = true;
    }
    if (widget.initialNote != null) _note = widget.initialNote!;
    if (widget.initialDate != null) _selectedDate = widget.initialDate!;
    _paymentMethod = PaymentMethod.normalize(widget.initialPaymentMethod);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CalculatorKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPaymentMethod != oldWidget.initialPaymentMethod) {
      _paymentMethod = PaymentMethod.normalize(widget.initialPaymentMethod);
    }
  }

  @override
  void didChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final viewInsetsBottom = view.viewInsets.bottom / view.devicePixelRatio;

    if (viewInsetsBottom <= 0) {
      final platformBottomSafeArea = _readPlatformBottomSafeArea();
      if (platformBottomSafeArea > 0) {
        _bottomSafeArea = platformBottomSafeArea;
      }
    }
  }

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
  }

  int _integerDigitsCount(String value) {
    final integerPart = value.split('.').first;
    return integerPart.replaceFirst('-', '').length;
  }

  bool _canAppendDigit(String nextCurrent) {
    final parts = nextCurrent.split('.');
    final integerDigits = _integerDigitsCount(nextCurrent);
    if (integerDigits > _maxIntegerDigits) {
      return false;
    }
    if (parts.length > 1 && parts[1].length > _maxDecimalDigits) {
      return false;
    }
    return true;
  }

  String get _displayText {
    if (_pendingOp != null) return '${_fmt(_result)}$_pendingOp$_current';
    return _current;
  }

  double _evaluate() {
    final cur = double.tryParse(_current) ?? 0;
    if (_pendingOp == '+') return _result + cur;
    if (_pendingOp == '-') return _result - cur;
    return cur;
  }

  double _clampResult(double value) {
    if (value > _maxResultValue) {
      return _maxResultValue;
    }
    if (value < -_maxResultValue) {
      return -_maxResultValue;
    }
    return value;
  }

  void _onKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_startNew && _pendingOp != null) {
          _current = _fmt(_result);
          _result = 0;
          _pendingOp = null;
          _startNew = false;
        } else if (_current.length > 1) {
          _current = _current.substring(0, _current.length - 1);
          _startNew = false;
        } else {
          _current = '0';
          _startNew = true;
        }
        return;
      }
      if (key == '+' || key == '-') {
        _result = _clampResult(_evaluate());
        _pendingOp = key;
        _current = '0';
        _startNew = true;
        return;
      }
      if (key == '.') {
        if (_startNew) {
          _current = '0.';
          _startNew = false;
          return;
        }
        if (!_current.contains('.')) {
          _current += '.';
        }
        return;
      }
      if (_startNew) {
        if (_canAppendDigit(key)) {
          _current = key;
          _startNew = false;
        }
      } else if (_current == '0') {
        if (_canAppendDigit(key)) {
          _current = key;
        }
      } else {
        final nextCurrent = '$_current$key';
        if (_canAppendDigit(nextCurrent)) {
          _current = nextCurrent;
        }
      }
    });
  }

  void _onComplete() {
    final amount = _clampResult(_evaluate());
    if (_pendingOp != null) {
      setState(() {
        _result = amount;
        _current = _fmt(amount);
        _pendingOp = null;
        _startNew = true;
      });
      return;
    }
    if (amount <= 0) return;
    widget.onComplete(amount, _note, _selectedDate, _paymentMethod);
  }

  Future<void> _pickDate() async {
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (_) => DatePicker(initialDate: _selectedDate),
    );
    if (result != null) setState(() => _selectedDate = result);
  }

  Future<void> _editNote() async {
    final result = await showGeneralDialog<String>(
      context: context,
      barrierLabel: 'NoteEditor',
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, animation, secondaryAnimation) => NoteEditor(
        initialNote: _note,
        displayText: _displayText,
        categoryName: widget.categoryName,
        categoryIconPath: widget.categoryIconPath,
        bottomSafeArea: _bottomSafeArea,
        onChanged: (value) {
          if (!mounted) {
            return;
          }
          setState(() => _note = value);
        },
      ),
    );
    if (result != null) setState(() => _note = result);
  }

  String get _dateLabel {
    final now = DateTime.now();
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return '今天';
    }
    return '${_selectedDate.month}月${_selectedDate.day}日';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(paymentMethodsProvider);
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.viewInsets.bottom <= 0) {
      final platformBottomSafeArea = _readPlatformBottomSafeArea();
      if (platformBottomSafeArea > 0) {
        _bottomSafeArea = platformBottomSafeArea;
      }
    }
    final frozenMediaQuery = mediaQuery.copyWith(
      viewInsets: mediaQuery.viewInsets.copyWith(bottom: 0),
      padding: mediaQuery.padding.copyWith(bottom: _bottomSafeArea),
      viewPadding: mediaQuery.viewPadding.copyWith(bottom: _bottomSafeArea),
    );

    return MediaQuery(
      data: frozenMediaQuery,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAmountBar(),
            _buildPaymentMethodBar(),
            _buildNoteBar(),
            const Divider(height: 1),
            _buildKeyboard(),
            SizedBox(height: _bottomSafeArea),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Image.asset(widget.categoryIconPath, width: 28, height: 28),
          // Text(widget.categoryName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(_displayText,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNoteBar() {
    return GestureDetector(
      onTap: _editNote,
      child: Container(
        margin: const EdgeInsets.only(left: 12,right: 12, bottom: 16, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text('备注：',
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary,fontWeight: FontWeight.w500)),
            Expanded(
              child: Text(
                _note.isEmpty ? '点击填写备注' : _note,
                style: TextStyle(
                  fontSize: 13,
                  color: _note.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                  fontWeight: FontWeight.w500
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodBar() {
    final options = paymentMethodFilterValues().skip(1).toList();
    final selectedPaymentMethod = options.contains(_paymentMethod)
        ? _paymentMethod
        : (options.isNotEmpty ? options.first : _paymentMethod);
    if (_paymentMethod != selectedPaymentMethod) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _paymentMethod = selectedPaymentMethod);
        }
      });
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '支付方式：',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final itemWidth = (constraints.maxWidth - spacing * 3) / 4;
              return Wrap(
                spacing: spacing,
                runSpacing: 8,
                children: [
                  for (final method in options)
                    SizedBox(
                      width: itemWidth,
                      child: _PaymentMethodChip(
                        label: paymentMethodLabel(method),
                        selected: method == selectedPaymentMethod,
                        onPressed: () => setState(() => _paymentMethod = method),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    return Column(
      children: [
        _keyRow(['7', '8', '9', 'date']),
        _keyRow(['4', '5', '6', '+']),
        _keyRow(['1', '2', '3', '-']),
        _keyRow(['.', '0', '⌫', 'done']),
      ],
    );
  }

  Widget _keyRow(List<String> keys) {
    return Row(children: keys.map((k) {
      if (k == 'done') return _doneKey();
      if (k == 'date') return _dateKey();
      return _normalKey(k);
    }).toList());
  }

  Widget _normalKey(String label) {
    return Expanded(child: GestureDetector(
      onTap: () => _onKey(label),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 22)),
      ),
    ));
  }

  Widget _dateKey() {
    return Expanded(child: GestureDetector(
      onTap: _pickDate,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset('assets/images/upgrade_calendar@3x.png', width: 18, height: 18),
          const SizedBox(width: 4),
          Text(_dateLabel, style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ]),
      ),
    ));
  }

  Widget _doneKey() {
    return Expanded(child: GestureDetector(
      onTap: _onComplete,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
        ),
        alignment: Alignment.center,
        child: const Text('完成', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    ));
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: selected ? AppColors.primary : Colors.white,
          foregroundColor: selected ? Colors.white : AppColors.textPrimary,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.textSecondary.withAlpha(90),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
