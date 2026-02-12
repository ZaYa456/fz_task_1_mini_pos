import 'package:hive_flutter/hive_flutter.dart';

import '../../features/auth/data/models/user_model.dart';
import '../../features/items/data/models/item_model.dart';
import '../../features/checkout/data/models/checkout_model.dart';
import '../../features/checkout/data/models/checkout_items_model.dart';

// ===============================
// Box Name Constants
// ===============================

const String kUserBox = 'user_box';
const String kItemBox = 'item_box';
const String kCheckoutBox = 'checkout_box';
const String kSessionBox = 'session_box';

// ===============================
// Session Keys
// ===============================

const String kIsLoggedInKey = 'is_logged_in';
const String kCurrentUserKey = 'current_user';

// ===============================
// Hive Setup
// ===============================

Future<void> setupHive() async {
  // 1️⃣ Initialize Hive for Flutter (Windows supported)
  await Hive.initFlutter();

  // 2️⃣ Register Generated Adapters (MODEL adapters, not domain entities)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserAdapter());
  }

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ItemModelAdapter());
  }

  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CheckoutModelAdapter());
  }

  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(CheckoutItemModelAdapter());
  }

  // 3️⃣ Open Boxes (Store MODELS only)
  await Hive.openBox<User>(kUserBox);
  await Hive.openBox<ItemModel>(kItemBox);
  await Hive.openBox<CheckoutModel>(kCheckoutBox);

  // 4️⃣ Session box (non-typed)
  await Hive.openBox(kSessionBox);
}
