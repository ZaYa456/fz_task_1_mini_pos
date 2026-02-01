import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/item_model.dart';
import '../models/checkout_model.dart';
import '../models/checkout_items_model.dart';

// Box name constants
const String kUserBox = 'user_box';
const String kItemBox = 'item_box';
const String kCheckoutBox = 'checkout_box';
const String kSessionBox = 'session_box';

// Session Keys
const String kIsLoggedInKey = 'is_logged_in';
const String kCurrentUserKey = 'current_user';

Future<void> setupHive() async {
  // 1. Initialize Hive
  await Hive.initFlutter();

  // 2. Register Adapters
  Hive.registerAdapter(UserAdapter()); // typeId: 0
  Hive.registerAdapter(ItemAdapter()); // typeId: 1
  Hive.registerAdapter(CheckoutAdapter()); // typeId: 2
  Hive.registerAdapter(CheckoutItemAdapter()); // typeId: 3

  // 3. Open Boxes
  await Hive.openBox<User>(kUserBox);
  await Hive.openBox<Item>(kItemBox);
  await Hive.openBox<Checkout>(kCheckoutBox);

  // 4. Session box (auth state)
  await Hive.openBox(kSessionBox);
}
