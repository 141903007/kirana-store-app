import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../utils/validators.dart';

/// A stock-quantity field, always persisted/validated in the product's
/// base unit. When the product has a "box-like" price variant (a variant
/// whose [boxQuantity] > 1, e.g. "Box of 10"), an optional convenience row
/// lets the shop owner enter "3 boxes + 2 loose" instead of doing the
/// multiplication themselves — it just computes into the same field.
class OpeningStockInput extends StatefulWidget {
  final TextEditingController controller;
  final String fieldLabel;
  final String unitLabel;
  final double? boxQuantity;
  final String? boxLabel;

  const OpeningStockInput({
    super.key,
    required this.controller,
    required this.fieldLabel,
    required this.unitLabel,
    this.boxQuantity,
    this.boxLabel,
  });

  @override
  State<OpeningStockInput> createState() => _OpeningStockInputState();
}

class _OpeningStockInputState extends State<OpeningStockInput> {
  bool _useBoxEntry = false;
  final _boxesController = TextEditingController(text: '0');
  final _looseController = TextEditingController(text: '0');

  bool get _hasBoxVariant => (widget.boxQuantity ?? 0) > 1;

  @override
  void dispose() {
    _boxesController.dispose();
    _looseController.dispose();
    super.dispose();
  }

  void _recomputeFromBoxEntry() {
    final boxes = double.tryParse(_boxesController.text.trim()) ?? 0;
    final loose = double.tryParse(_looseController.text.trim()) ?? 0;
    final total = (boxes * (widget.boxQuantity ?? 0)) + loose;
    widget.controller.text = total == total.roundToDouble()
        ? total.toInt().toString()
        : total.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          enabled: !_useBoxEntry,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: widget.fieldLabel),
          validator: (value) => Validators.nonNegativeNumber(
            value,
            'common.required_field'.tr(),
            'common.invalid_number'.tr(),
          ),
        ),
        if (_hasBoxVariant) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('products.enter_as_boxes_toggle'.tr()),
            value: _useBoxEntry,
            onChanged: (value) => setState(() => _useBoxEntry = value),
          ),
          if (_useBoxEntry)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _boxesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '${'products.boxes_label'.tr()} (${widget.boxLabel})',
                    ),
                    onChanged: (_) => _recomputeFromBoxEntry(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _looseController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'products.loose_label'.tr(namedArgs: {'unit': widget.unitLabel}),
                    ),
                    onChanged: (_) => _recomputeFromBoxEntry(),
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }
}
