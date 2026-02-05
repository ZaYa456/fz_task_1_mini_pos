import 'package:flutter/widgets.dart';

class HoldIntent extends Intent {
  const HoldIntent();
}

class RecallIntent extends Intent {
  const RecallIntent();
}

class ClearCartIntent extends Intent {
  const ClearCartIntent();
}

class PayIntent extends Intent {
  const PayIntent();
}

class DeleteItemIntent extends Intent {
  const DeleteItemIntent();
}

class NavigateUpIntent extends Intent {
  const NavigateUpIntent();
}

class NavigateDownIntent extends Intent {
  const NavigateDownIntent();
}

class IncrementQtyIntent extends Intent {
  const IncrementQtyIntent();
}

class DecrementQtyIntent extends Intent {
  const DecrementQtyIntent();
}
