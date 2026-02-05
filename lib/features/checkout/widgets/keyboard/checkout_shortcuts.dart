import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'checkout_intents.dart';

final Map<LogicalKeySet, Intent> checkoutShortcuts = {
  LogicalKeySet(LogicalKeyboardKey.f1): const HoldIntent(),
  LogicalKeySet(LogicalKeyboardKey.f2): const RecallIntent(),
  LogicalKeySet(LogicalKeyboardKey.f9): const ClearCartIntent(),
  LogicalKeySet(LogicalKeyboardKey.f12): const PayIntent(),
  LogicalKeySet(LogicalKeyboardKey.delete): const DeleteItemIntent(),
  LogicalKeySet(LogicalKeyboardKey.arrowUp): const NavigateUpIntent(),
  LogicalKeySet(LogicalKeyboardKey.arrowDown): const NavigateDownIntent(),
  LogicalKeySet(LogicalKeyboardKey.add): const IncrementQtyIntent(),
  LogicalKeySet(LogicalKeyboardKey.numpadAdd): const IncrementQtyIntent(),
  LogicalKeySet(LogicalKeyboardKey.minus): const DecrementQtyIntent(),
  LogicalKeySet(LogicalKeyboardKey.numpadSubtract): const DecrementQtyIntent(),
};
