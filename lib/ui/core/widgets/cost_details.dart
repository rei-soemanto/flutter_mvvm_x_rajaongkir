/// Opens the right detail pop-up for a shipping cost.
library;

import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/cost_detail_bottom_sheet.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/international_cost_dialog.dart';

/// Shows every attribute of [cost] in a pop-up.
///
/// A domestic result opens a modal bottom sheet and an international result
/// opens a dialog. Because [ShippingCost] is sealed, the compiler checks that
/// both kinds are handled.
Future<void> showShippingCostDetails(
  BuildContext context,
  ShippingCost cost,
) async {
  switch (cost) {
    case DomesticShippingCost():
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => CostDetailBottomSheet(cost: cost),
      );
    case InternationalShippingCost():
      await showDialog<void>(
        context: context,
        builder: (context) => InternationalCostDialog(cost: cost),
      );
  }
}
